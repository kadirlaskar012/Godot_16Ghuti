// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE MATCH HANDLER (NAKAMA MATCH LOOP)
// 100% Server Authoritative: Game State, Moves, 5-Min Timer, Anti-Cheat, Reconnect
// ==============================================================================

import {
    PlayerId,
    MatchOpCode,
    MatchStatus,
    EndReason,
    MoveRequest,
    MatchPlayer,
    ServerMatchState,
    MATCH_DURATION_SEC,
    TURN_NORMAL_TIME_SEC,
    PLAYER_EXTRA_TIME_SEC
} from "./types";
import { AuthoritativeRulesEngine } from "./rules_engine";
import { SecurityManager } from "./security";
import { ServerWallet } from "./wallet";

const TICK_RATE = 10; // 10 ticks per second
const RECONNECT_GRACE_PERIOD_SEC = 45; // 45s reconnect grace per specification

export const matchHandler: any = {
    matchInit(ctx: any, logger: any, nk: any, params: any) {
        const matchState: ServerMatchState = {
            matchId: ctx.matchId,
            roomCode: params.room_code || undefined,
            mode: params.mode || "1v1_ONLINE",
            status: MatchStatus.WAITING,
            players: {},
            player1Id: "",
            player2Id: "",
            board: AuthoritativeRulesEngine.createInitialBoard(),
            activePlayer: PlayerId.PLAYER_1, // Player 1 (Red/bottom) moves first
            turnNumber: 1,
            isInMultiCapture: false,
            multiCaptureNode: -1,
            matchStartTimeSec: 0,
            matchDurationLimitSec: MATCH_DURATION_SEC,
            remainingSeconds: MATCH_DURATION_SEC,
            turnNormalDurationSec: TURN_NORMAL_TIME_SEC,
            playerExtraTimeDurationSec: PLAYER_EXTRA_TIME_SEC,
            turnStartTimeSec: 0,
            p1ExtraTimeRemainingSec: PLAYER_EXTRA_TIME_SEC,
            p2ExtraTimeRemainingSec: PLAYER_EXTRA_TIME_SEC,
            isInExtraTime: false,
            turnRemainingSeconds: TURN_NORMAL_TIME_SEC,
            moveHistory: [],
            emptyTicks: 0,
            winner: PlayerId.NONE,
            loser: PlayerId.NONE,
            endReason: ""
        };

        return {
            state: matchState,
            tickRate: TICK_RATE,
            label: JSON.stringify({
                mode: matchState.mode,
                room_code: matchState.roomCode,
                status: matchState.status
            })
        };
    },

    matchJoinAttempt(ctx: any, logger: any, nk: any, dispatcher: any, tick: number, state: ServerMatchState, presence: any, metadata: any) {
        // Check if player is reconnecting
        if (state.players[presence.userId]) {
            return { state, accept: true };
        }

        // Limit to 2 players max
        const count = Object.keys(state.players).length;
        if (count >= 2) {
            return { state, accept: false, rejectMessage: "Match is already full" };
        }

        if (state.status !== MatchStatus.WAITING && state.status !== MatchStatus.READY) {
            return { state, accept: false, rejectMessage: "Match has already concluded" };
        }

        return { state, accept: true };
    },

    matchJoin(ctx: any, logger: any, nk: any, dispatcher: any, tick: number, state: ServerMatchState, presences: any[]) {
        for (const presence of presences) {
            const userId = presence.userId;

            // Reconnecting player
            if (state.players[userId]) {
                const p = state.players[userId];
                p.connected = true;
                p.presence = presence;
                delete p.disconnectedAtSec;

                // Send complete authoritative state sync to reconnected player
                const nowSec = Math.floor(Date.now() / 1000);
                let isExtra = false;
                let turnRem = state.turnNormalDurationSec;
                if (state.turnStartTimeSec > 0) {
                    const elapsed = nowSec - state.turnStartTimeSec;
                    const activeReserve = state.activePlayer === PlayerId.PLAYER_1 ? state.p1ExtraTimeRemainingSec : state.p2ExtraTimeRemainingSec;
                    if (elapsed <= state.turnNormalDurationSec) {
                        isExtra = false;
                        turnRem = Math.max(0, state.turnNormalDurationSec - elapsed);
                    } else {
                        isExtra = true;
                        const consumed = elapsed - state.turnNormalDurationSec;
                        turnRem = Math.max(0, activeReserve - consumed);
                    }
                }
                const curP1Extra = state.activePlayer === PlayerId.PLAYER_1 && isExtra ? turnRem : state.p1ExtraTimeRemainingSec;
                const curP2Extra = state.activePlayer === PlayerId.PLAYER_2 && isExtra ? turnRem : state.p2ExtraTimeRemainingSec;

                dispatcher.broadcastMessage(
                    MatchOpCode.OP_STATE_SYNC,
                    JSON.stringify({
                        match_id: state.matchId,
                        board: state.board,
                        active_player: state.activePlayer,
                        turn_number: state.turnNumber,
                        remaining_seconds: state.remainingSeconds,
                        match_remaining_seconds: state.remainingSeconds,
                        turn_remaining_seconds: turnRem,
                        is_extra_time: isExtra,
                        p1_extra_time: curP1Extra,
                        p2_extra_time: curP2Extra,
                        is_multi_capture: state.isInMultiCapture,
                        multi_capture_node: state.multiCaptureNode,
                        player_index: p.playerIndex,
                        server_time: nowSec
                    }),
                    [presence]
                );

                // Notify other player
                dispatcher.broadcastMessage(
                    MatchOpCode.OP_PLAYER_RECONNECTED,
                    JSON.stringify({ user_id: userId }),
                    null,
                    presence
                );
                continue;
            }

            // New joining player
            const isFirst = !state.player1Id;
            const playerIndex = isFirst ? PlayerId.PLAYER_1 : PlayerId.PLAYER_2;

            if (isFirst) {
                state.player1Id = userId;
            } else {
                state.player2Id = userId;
            }

            state.players[userId] = {
                presence,
                userId,
                username: presence.username || `Player_${playerIndex}`,
                playerIndex,
                captures: 0,
                remainingPieces: 16,
                connected: true,
                lastPingAtSec: Date.now() / 1000,
                lastSeq: 0
            };
        }

        // When both players are joined, start the match
        if (Object.keys(state.players).length === 2 && state.status === MatchStatus.WAITING) {
            state.status = MatchStatus.PLAYING;
            const nowSec = Math.floor(Date.now() / 1000);
            state.matchStartTimeSec = nowSec;
            state.remainingSeconds = state.matchDurationLimitSec;
            state.turnStartTimeSec = nowSec;
            state.isInExtraTime = false;
            state.turnRemainingSeconds = state.turnNormalDurationSec;

            // Broadcast match started to both players with assigned playerIndex and initial board
            for (const uid in state.players) {
                const pl = state.players[uid];
                dispatcher.broadcastMessage(
                    MatchOpCode.OP_STATE_SYNC,
                    JSON.stringify({
                        match_id: state.matchId,
                        board: state.board,
                        active_player: state.activePlayer,
                        turn_number: state.turnNumber,
                        remaining_seconds: state.remainingSeconds,
                        match_remaining_seconds: state.remainingSeconds,
                        turn_remaining_seconds: state.turnRemainingSeconds,
                        is_extra_time: false,
                        p1_extra_time: state.p1ExtraTimeRemainingSec,
                        p2_extra_time: state.p2ExtraTimeRemainingSec,
                        player_index: pl.playerIndex,
                        opponent_id: pl.playerIndex === PlayerId.PLAYER_1 ? state.player2Id : state.player1Id,
                        opponent_name: pl.playerIndex === PlayerId.PLAYER_1 ? state.players[state.player2Id]?.username : state.players[state.player1Id]?.username,
                        server_time: nowSec
                    }),
                    [pl.presence]
                );
            }

            // Insert initial match record in DB
            try {
                nk.sqlExec(
                    `INSERT INTO matches (match_id, player_1, player_2, mode, status, started_at)
                     VALUES ($1, $2, $3, $4, 'PLAYING', NOW())`,
                    [state.matchId, state.player1Id, state.player2Id, state.mode]
                );
            } catch (e) {
                // Non-critical if db logging fails
            }
        }

        return { state };
    },

    matchLeave(ctx: any, logger: any, nk: any, dispatcher: any, tick: number, state: ServerMatchState, presences: any[]) {
        for (const presence of presences) {
            const p = state.players[presence.userId];
            if (p) {
                p.connected = false;
                p.disconnectedAtSec = Math.floor(Date.now() / 1000);

                // Notify opponent of temporary disconnect
                dispatcher.broadcastMessage(
                    MatchOpCode.OP_PLAYER_DISCONNECTED,
                    JSON.stringify({
                        user_id: presence.userId,
                        grace_period_sec: RECONNECT_GRACE_PERIOD_SEC
                    })
                );
            }
        }
        return { state };
    },

    matchLoop(ctx: any, logger: any, nk: any, dispatcher: any, tick: number, state: ServerMatchState, messages: any[]) {
        // If match finished, terminate
        if (state.status === MatchStatus.COMPLETED || state.status === MatchStatus.TIME_UP) {
            return null; // Terminate match
        }

        // 1. Process Messages
        for (const msg of messages) {
            const senderId = msg.sender.userId;
            const player = state.players[senderId];
            if (!player) continue;

            const opCode = msg.opCode;

            // PING
            if (opCode === MatchOpCode.OP_PING) {
                dispatcher.broadcastMessage(MatchOpCode.OP_PING, msg.data, [msg.sender]);
                continue;
            }

            // RESIGN / FORFEIT
            if (opCode === MatchOpCode.OP_RESIGN) {
                state.winner = player.playerIndex === PlayerId.PLAYER_1 ? PlayerId.PLAYER_2 : PlayerId.PLAYER_1;
                state.loser = player.playerIndex;
                state.endReason = EndReason.FORFEIT;
                this._finishMatch(state, dispatcher, nk);
                return null;
            }

            // QUICK CHAT (Realtime Match Chat)
            if (opCode === MatchOpCode.OP_CHAT_MESSAGE) {
                if (SecurityManager.checkRateLimit(senderId + "_chat", 5, 3000)) {
                    dispatcher.broadcastMessage(MatchOpCode.OP_CHAT_MESSAGE, msg.data, null, msg.sender);
                }
                continue;
            }

            // EMOJI REACTION (3 emoji per second max rate limit per spec)
            if (opCode === MatchOpCode.OP_EMOJI_REACTION) {
                if (SecurityManager.checkRateLimit(senderId + "_emoji", 3, 1000)) {
                    dispatcher.broadcastMessage(MatchOpCode.OP_EMOJI_REACTION, msg.data, null, msg.sender);
                }
                continue;
            }

            // WEBRTC SIGNALING (1-to-1 Voice Chat signaling coordination via Nakama)
            if (opCode === MatchOpCode.OP_WEBRTC_SIGNAL) {
                dispatcher.broadcastMessage(MatchOpCode.OP_WEBRTC_SIGNAL, msg.data, null, msg.sender);
                continue;
            }

            // VOICE STATUS (Mic state, speaking indicator)
            if (opCode === MatchOpCode.OP_VOICE_STATUS) {
                dispatcher.broadcastMessage(MatchOpCode.OP_VOICE_STATUS, msg.data, null, msg.sender);
                continue;
            }

            // MOVE REQUEST (Server Authoritative Move Validation)
            if (opCode === MatchOpCode.OP_MOVE_REQUEST) {
                let move: MoveRequest;
                try {
                    move = JSON.parse(nk.binaryToString(msg.data));
                } catch (e) {
                    continue;
                }

                // Security Check 1: Rate limiting
                if (!SecurityManager.checkRateLimit(senderId, 6, 1000)) {
                    this._rejectMove(dispatcher, player, "Rate limit exceeded. Move too fast.");
                    continue;
                }

                // Security Check 2: Match state active
                if (state.status !== MatchStatus.PLAYING) {
                    this._rejectMove(dispatcher, player, "Match is not currently in playing state.");
                    continue;
                }

                // Security Check 3: Is it this player's turn?
                if (player.playerIndex !== state.activePlayer) {
                    SecurityManager.addSuspicionScore(nk, senderId, 5, "Moved out of turn");
                    this._rejectMove(dispatcher, player, "Not your turn.");
                    continue;
                }

                // Security Check 3b: Server Authoritative Turn Timeout Check
                const nowSec = Math.floor(Date.now() / 1000);
                const elapsedTurn = state.turnStartTimeSec > 0 ? (nowSec - state.turnStartTimeSec) : 0;
                const activeReserve = state.activePlayer === PlayerId.PLAYER_1 ? state.p1ExtraTimeRemainingSec : state.p2ExtraTimeRemainingSec;

                if (elapsedTurn > state.turnNormalDurationSec) {
                    const extraConsumed = elapsedTurn - state.turnNormalDurationSec;
                    if (extraConsumed >= activeReserve) {
                        if (state.activePlayer === PlayerId.PLAYER_1) {
                            state.p1ExtraTimeRemainingSec = 0;
                        } else {
                            state.p2ExtraTimeRemainingSec = 0;
                        }
                        SecurityManager.recordSecurityEvent(nk, senderId, "move_after_timeout", {
                            elapsed: elapsedTurn,
                            reserve: activeReserve
                        });
                        this._rejectMove(dispatcher, player, "Turn timed out. Extra time depleted.");
                        state.status = MatchStatus.COMPLETED;
                        state.winner = AuthoritativeRulesEngine.getOpponent(state.activePlayer);
                        state.loser = state.activePlayer;
                        state.endReason = EndReason.TIMEOUT;
                        this._finishMatch(state, dispatcher, nk);
                        return null;
                    }
                }

                // Security Check 4: Sequence number monotonicity (Duplicate / Replay attack protection)
                if (move.client_seq && move.client_seq <= player.lastSeq) {
                    SecurityManager.recordSecurityEvent(nk, senderId, "duplicate_move_seq", { seq: move.client_seq });
                    this._rejectMove(dispatcher, player, "Duplicate or out-of-order move sequence rejected.");
                    continue;
                }
                player.lastSeq = move.client_seq || (player.lastSeq + 1);

                // Security Check 5: Authoritative 16 Guti rules validation
                const validation = AuthoritativeRulesEngine.validateMove(
                    state.board,
                    move.from,
                    move.to,
                    move.is_capture,
                    move.captured,
                    state.activePlayer,
                    state.isInMultiCapture,
                    state.multiCaptureNode
                );

                if (!validation.valid) {
                    SecurityManager.addSuspicionScore(nk, senderId, 10, "Illegal move requested", {
                        move,
                        reason: validation.reason
                    });
                    this._rejectMove(dispatcher, player, validation.reason || "Illegal move by 16 Guti rules.");
                    continue;
                }

                // Deduct actual Extra Time consumed if move occurred during Extra Time
                if (elapsedTurn > state.turnNormalDurationSec) {
                    const extraConsumed = elapsedTurn - state.turnNormalDurationSec;
                    if (state.activePlayer === PlayerId.PLAYER_1) {
                        state.p1ExtraTimeRemainingSec = Math.max(0, state.p1ExtraTimeRemainingSec - extraConsumed);
                    } else {
                        state.p2ExtraTimeRemainingSec = Math.max(0, state.p2ExtraTimeRemainingSec - extraConsumed);
                    }
                }

                // Apply Move on Authoritative Server Board
                const result = AuthoritativeRulesEngine.applyMove(
                    state.board,
                    move.from,
                    move.to,
                    move.is_capture,
                    move.captured,
                    state.activePlayer
                );

                state.board = result.board;

                // Track captures
                if (move.is_capture) {
                    player.captures += 1;
                    const opponentUid = player.playerIndex === PlayerId.PLAYER_1 ? state.player2Id : state.player1Id;
                    if (state.players[opponentUid]) {
                        state.players[opponentUid].remainingPieces -= 1;
                    }
                }

                // Record move history
                state.moveHistory.push({
                    turn: state.turnNumber,
                    player: state.activePlayer,
                    from: move.from,
                    to: move.to,
                    is_capture: move.is_capture,
                    captured: move.captured,
                    client_seq: move.client_seq
                });

                // Update multi-capture or switch turns
                if (result.multiCaptureAvailable) {
                    state.isInMultiCapture = true;
                    state.multiCaptureNode = result.multiCaptureNode;
                } else {
                    state.isInMultiCapture = false;
                    state.multiCaptureNode = -1;
                    state.activePlayer = AuthoritativeRulesEngine.getOpponent(state.activePlayer);
                    state.turnNumber += 1;
                }

                // Reset turn timer to fresh normal turn timer for next turn / chain action
                state.turnStartTimeSec = Math.floor(Date.now() / 1000);
                state.isInExtraTime = false;
                state.turnRemainingSeconds = state.turnNormalDurationSec;

                // Broadcast OP_MOVE_ACCEPTED to both players with updated timer state
                dispatcher.broadcastMessage(
                    MatchOpCode.OP_MOVE_ACCEPTED,
                    JSON.stringify({
                        from: move.from,
                        to: move.to,
                        is_capture: move.is_capture,
                        captured: move.captured,
                        board: state.board,
                        active_player: state.activePlayer,
                        turn_number: state.turnNumber,
                        is_multi_capture: state.isInMultiCapture,
                        multi_capture_node: state.multiCaptureNode,
                        p1_remaining: state.players[state.player1Id]?.remainingPieces ?? 16,
                        p2_remaining: state.players[state.player2Id]?.remainingPieces ?? 16,
                        remaining_seconds: state.remainingSeconds,
                        match_remaining_seconds: state.remainingSeconds,
                        turn_remaining_seconds: state.turnRemainingSeconds,
                        is_extra_time: false,
                        p1_extra_time: state.p1ExtraTimeRemainingSec,
                        p2_extra_time: state.p2ExtraTimeRemainingSec,
                        server_time: state.turnStartTimeSec
                    })
                );

                // Check Game Over (Elimination or Stalemate)
                const p1Remaining = state.players[state.player1Id]?.remainingPieces ?? 16;
                const p2Remaining = state.players[state.player2Id]?.remainingPieces ?? 16;

                const gameOver = AuthoritativeRulesEngine.checkGameOver(
                    state.board,
                    p1Remaining,
                    p2Remaining,
                    state.activePlayer,
                    state.isInMultiCapture,
                    state.multiCaptureNode
                );

                if (gameOver.isGameOver) {
                    state.winner = gameOver.winner;
                    state.loser = AuthoritativeRulesEngine.getOpponent(gameOver.winner);
                    state.endReason = gameOver.reason as EndReason;
                    this._finishMatch(state, dispatcher, nk);
                    return null;
                }
            }
        }

        // 2. Authoritative Server Timer & Disconnect Handling (Runs once per second)
        if (state.status === MatchStatus.PLAYING && tick % TICK_RATE === 0) {
            const nowSec = Math.floor(Date.now() / 1000);

            // Decrement match duration timer
            state.remainingSeconds = Math.max(0, state.matchDurationLimitSec - (nowSec - state.matchStartTimeSec));

            // Calculate turn timer and extra time according to server time
            const elapsedTurn = state.turnStartTimeSec > 0 ? (nowSec - state.turnStartTimeSec) : 0;
            const activeReserve = state.activePlayer === PlayerId.PLAYER_1 ? state.p1ExtraTimeRemainingSec : state.p2ExtraTimeRemainingSec;

            if (elapsedTurn <= state.turnNormalDurationSec) {
                state.isInExtraTime = false;
                state.turnRemainingSeconds = Math.max(0, state.turnNormalDurationSec - elapsedTurn);
            } else {
                state.isInExtraTime = true;
                const extraConsumed = elapsedTurn - state.turnNormalDurationSec;
                state.turnRemainingSeconds = Math.max(0, activeReserve - extraConsumed);
            }

            const currentP1Extra = state.activePlayer === PlayerId.PLAYER_1 && state.isInExtraTime
                ? state.turnRemainingSeconds
                : state.p1ExtraTimeRemainingSec;
            const currentP2Extra = state.activePlayer === PlayerId.PLAYER_2 && state.isInExtraTime
                ? state.turnRemainingSeconds
                : state.p2ExtraTimeRemainingSec;

            // Broadcast authoritative remaining seconds every second
            dispatcher.broadcastMessage(
                MatchOpCode.OP_TIMER_TICK,
                JSON.stringify({
                    remaining_seconds: state.remainingSeconds,
                    match_remaining_seconds: state.remainingSeconds,
                    turn_remaining_seconds: state.turnRemainingSeconds,
                    is_extra_time: state.isInExtraTime,
                    active_player: state.activePlayer,
                    p1_extra_time: currentP1Extra,
                    p2_extra_time: currentP2Extra,
                    server_time: nowSec
                })
            );

            // Check if player depleted all Extra Time (TIMEOUT FORFEIT)
            if (state.isInExtraTime && state.turnRemainingSeconds <= 0) {
                if (state.activePlayer === PlayerId.PLAYER_1) {
                    state.p1ExtraTimeRemainingSec = 0;
                } else {
                    state.p2ExtraTimeRemainingSec = 0;
                }
                state.status = MatchStatus.COMPLETED;
                state.winner = AuthoritativeRulesEngine.getOpponent(state.activePlayer);
                state.loser = state.activePlayer;
                state.endReason = EndReason.TIMEOUT;

                SecurityManager.recordSecurityEvent(nk, state.activePlayer === PlayerId.PLAYER_1 ? state.player1Id : state.player2Id, "turn_timeout_forfeit", {
                    player: state.activePlayer,
                    turn: state.turnNumber
                });

                this._finishMatch(state, dispatcher, nk);
                return null;
            }

            // Check if 5 minutes expired (TIME UP)
            if (state.remainingSeconds <= 0) {
                state.status = MatchStatus.TIME_UP;
                state.endReason = EndReason.TIME_UP;

                // Determine winner by piece count
                const p1Count = state.players[state.player1Id]?.remainingPieces ?? 16;
                const p2Count = state.players[state.player2Id]?.remainingPieces ?? 16;

                if (p1Count > p2Count) {
                    state.winner = PlayerId.PLAYER_1;
                    state.loser = PlayerId.PLAYER_2;
                } else if (p2Count > p1Count) {
                    state.winner = PlayerId.PLAYER_2;
                    state.loser = PlayerId.PLAYER_1;
                } else {
                    state.winner = PlayerId.NONE; // Draw
                    state.loser = PlayerId.NONE;
                }

                this._finishMatch(state, dispatcher, nk);
                return null;
            }

            // Check disconnect grace period for players
            for (const uid in state.players) {
                const pl = state.players[uid];
                if (!pl.connected && pl.disconnectedAtSec) {
                    if (nowSec - pl.disconnectedAtSec > RECONNECT_GRACE_PERIOD_SEC) {
                        // Grace period expired: declare connected opponent the winner
                        state.winner = pl.playerIndex === PlayerId.PLAYER_1 ? PlayerId.PLAYER_2 : PlayerId.PLAYER_1;
                        state.loser = pl.playerIndex;
                        state.endReason = EndReason.OPPONENT_DISCONNECTED;
                        this._finishMatch(state, dispatcher, nk);
                        return null;
                    }
                }
            }
        }

        return { state };
    },

    _rejectMove(dispatcher: any, player: MatchPlayer, reason: string) {
        dispatcher.broadcastMessage(
            MatchOpCode.OP_MOVE_REJECTED,
            JSON.stringify({ reason }),
            [player.presence]
        );
    },

    _finishMatch(state: ServerMatchState, dispatcher: any, nk: any) {
        state.status = MatchStatus.COMPLETED;

        const p1 = state.players[state.player1Id];
        const p2 = state.players[state.player2Id];

        const winnerUid = state.winner === PlayerId.PLAYER_1 ? state.player1Id : (state.winner === PlayerId.PLAYER_2 ? state.player2Id : null);
        const loserUid = state.loser === PlayerId.PLAYER_1 ? state.player1Id : (state.loser === PlayerId.PLAYER_2 ? state.player2Id : null);

        // Broadcast MATCH_OVER
        dispatcher.broadcastMessage(
            MatchOpCode.OP_MATCH_OVER,
            JSON.stringify({
                winner: state.winner,
                loser: state.loser,
                winner_uid: winnerUid,
                end_reason: state.endReason,
                p1_remaining: p1?.remainingPieces ?? 0,
                p2_remaining: p2?.remainingPieces ?? 0,
                p1_captures: p1?.captures ?? 0,
                p2_captures: p2?.captures ?? 0,
                duration_seconds: state.matchDurationLimitSec - state.remainingSeconds
            })
        );

        // Update PostgreSQL authoritative records
        try {
            const dur = Math.max(1, state.matchDurationLimitSec - state.remainingSeconds);

            // Update matches table
            nk.sqlExec(
                `UPDATE matches SET status = 'COMPLETED', ended_at = NOW(), duration_seconds = $1 WHERE match_id = $2`,
                [dur, state.matchId]
            );

            // Insert match_results
            nk.sqlExec(
                `INSERT INTO match_results (match_id, winner_id, loser_id, end_reason, summary)
                 VALUES ($1, $2, $3, $4, $5)`,
                [
                    state.matchId,
                    winnerUid,
                    loserUid,
                    state.endReason,
                    JSON.stringify({
                        p1_captures: p1?.captures ?? 0,
                        p2_captures: p2?.captures ?? 0,
                        duration_seconds: dur
                    })
                ]
            );

            // Award coins & XP to players server-side
            if (winnerUid) {
                ServerWallet.processTransaction(nk, winnerUid, "WIN_REWARD", 100, `match_win_${state.matchId}`);
                this._updateStats(nk, winnerUid, true, false, p1?.userId === winnerUid ? p1.captures : p2?.captures || 0, dur);
            }
            if (loserUid) {
                ServerWallet.processTransaction(nk, loserUid, "MATCH_REWARD", 20, `match_loss_${state.matchId}`);
                this._updateStats(nk, loserUid, false, false, p1?.userId === loserUid ? p1.captures : p2?.captures || 0, dur);
            }
            if (!winnerUid && !loserUid) {
                // Draw
                if (state.player1Id) {
                    ServerWallet.processTransaction(nk, state.player1Id, "MATCH_REWARD", 30, `match_draw_p1_${state.matchId}`);
                    this._updateStats(nk, state.player1Id, false, true, p1?.captures || 0, dur);
                }
                if (state.player2Id) {
                    ServerWallet.processTransaction(nk, state.player2Id, "MATCH_REWARD", 30, `match_draw_p2_${state.matchId}`);
                    this._updateStats(nk, state.player2Id, false, true, p2?.captures || 0, dur);
                }
            }
        } catch (dbErr) {
            // Logged in console
        }
    },

    _updateStats(nk: any, userId: string, won: boolean, draw: boolean, captures: number, duration: number) {
        try {
            nk.sqlExec(
                `INSERT INTO player_statistics (user_id, matches_played, wins, losses, draws, captures, win_streak, best_streak, total_play_time)
                 VALUES ($1, 1, $2, $3, $4, $5, $6, $6, $7)
                 ON CONFLICT (user_id) DO UPDATE SET
                    matches_played = player_statistics.matches_played + 1,
                    wins = player_statistics.wins + $2,
                    losses = player_statistics.losses + $3,
                    draws = player_statistics.draws + $4,
                    captures = player_statistics.captures + $5,
                    win_streak = CASE WHEN $2 = 1 THEN player_statistics.win_streak + 1 ELSE 0 END,
                    best_streak = GREATEST(player_statistics.best_streak, CASE WHEN $2 = 1 THEN player_statistics.win_streak + 1 ELSE 0 END),
                    total_play_time = player_statistics.total_play_time + $7,
                    updated_at = NOW()`,
                [userId, won ? 1 : 0, (!won && !draw) ? 1 : 0, draw ? 1 : 0, captures, won ? 1 : 0, duration]
            );
        } catch (e) {
            // Handled
        }
    },

    matchTerminate(ctx: any, logger: any, nk: any, dispatcher: any, tick: number, state: ServerMatchState, graceSeconds: number) {
        return { state };
    }
};
