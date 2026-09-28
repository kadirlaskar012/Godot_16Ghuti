(() => {
  // src/types.ts
  var MATCH_DURATION_SEC = 300;
  var TURN_NORMAL_TIME_SEC = 10;
  var PLAYER_EXTRA_TIME_SEC = 300;

  // src/rules_engine.ts
  var TOTAL_NODES = 37;
  var ADJACENCY = {
    0: [1, 3],
    1: [0, 2, 4],
    2: [1, 5],
    3: [0, 4, 8],
    4: [1, 3, 5, 8],
    5: [2, 4, 8],
    6: [7, 11, 12],
    7: [6, 8, 11, 12, 13],
    8: [3, 4, 5, 7, 9, 12, 13, 14],
    9: [8, 10, 13, 14, 15],
    10: [9, 14, 15],
    11: [6, 7, 12, 16, 17],
    12: [6, 7, 8, 11, 13, 16, 17, 18],
    13: [7, 8, 9, 12, 14, 17, 18, 19],
    14: [8, 9, 10, 13, 15, 18, 19, 20],
    15: [9, 10, 14, 19, 20],
    16: [11, 12, 17, 21, 22],
    17: [11, 12, 13, 16, 18, 21, 22, 23],
    18: [12, 13, 14, 17, 19, 22, 23, 24],
    19: [13, 14, 15, 18, 20, 23, 24, 25],
    20: [14, 15, 19, 24, 25],
    21: [16, 17, 22, 26, 27],
    22: [16, 17, 18, 21, 23, 26, 27, 28],
    23: [17, 18, 19, 22, 24, 27, 28, 29],
    24: [18, 19, 20, 23, 25, 28, 29, 30],
    25: [19, 20, 24, 29, 30],
    26: [21, 22, 27],
    27: [21, 22, 23, 26, 28],
    28: [22, 23, 24, 27, 29, 31, 32, 33],
    29: [23, 24, 25, 28, 30],
    30: [24, 25, 29],
    31: [28, 32, 34],
    32: [28, 31, 33, 35],
    33: [28, 32, 36],
    34: [31, 35],
    35: [32, 34, 36],
    36: [33, 35]
  };
  var JUMP_TABLE = {
    0: { 1: 2, 3: 8 },
    1: { 4: 8 },
    2: { 1: 0, 5: 8 },
    3: { 4: 5, 8: 14 },
    4: { 8: 13 },
    5: { 4: 3, 8: 12 },
    6: { 7: 8, 11: 16, 12: 18 },
    7: { 8: 9, 12: 17, 13: 19 },
    8: { 7: 6, 9: 10, 4: 1, 13: 18, 3: 0, 14: 20, 5: 2, 12: 16 },
    9: { 8: 7, 14: 19, 13: 17 },
    10: { 9: 8, 15: 20, 14: 18 },
    11: { 12: 13, 16: 21, 17: 23 },
    12: { 13: 14, 17: 22, 18: 24, 8: 5 },
    13: { 12: 11, 14: 15, 8: 4, 18: 23, 19: 25, 17: 21 },
    14: { 13: 12, 19: 24, 8: 3, 18: 22 },
    15: { 14: 13, 20: 25, 19: 23 },
    16: { 17: 18, 11: 6, 21: 26, 22: 28, 12: 8 },
    17: { 18: 19, 12: 7, 22: 27, 23: 29, 13: 9 },
    18: { 17: 16, 19: 20, 13: 8, 23: 28, 12: 6, 24: 30, 14: 10, 22: 26 },
    19: { 18: 17, 14: 9, 24: 29, 13: 7, 23: 27 },
    20: { 19: 18, 15: 10, 25: 30, 14: 8, 24: 28 },
    21: { 22: 23, 16: 11, 17: 13 },
    22: { 23: 24, 17: 12, 28: 33, 18: 14 },
    23: { 22: 21, 24: 25, 18: 13, 28: 32, 17: 11, 19: 15 },
    24: { 23: 22, 19: 14, 18: 12, 28: 31 },
    25: { 24: 23, 20: 15, 19: 13 },
    26: { 27: 28, 21: 16, 22: 18 },
    27: { 28: 29, 22: 17, 23: 19 },
    28: { 27: 26, 29: 30, 23: 18, 32: 35, 22: 16, 33: 36, 24: 20, 31: 34 },
    29: { 28: 27, 24: 19, 23: 17 },
    30: { 29: 28, 25: 20, 24: 18 },
    31: { 32: 33, 28: 24 },
    32: { 28: 23 },
    33: { 32: 31, 28: 22 },
    34: { 35: 36, 31: 28 },
    35: { 32: 28 },
    36: { 35: 34, 33: 28 }
  };
  var AuthoritativeRulesEngine = class {
    static createInitialBoard() {
      const board = new Array(TOTAL_NODES).fill(0 /* NONE */);
      for (let i = 0; i <= 15; i++) {
        board[i] = 2 /* PLAYER_2 */;
      }
      for (let i = 21; i <= 36; i++) {
        board[i] = 1 /* PLAYER_1 */;
      }
      return board;
    }
    static getOpponent(player) {
      return player === 1 /* PLAYER_1 */ ? 2 /* PLAYER_2 */ : 1 /* PLAYER_1 */;
    }
    static getCapturesForPiece(board, fromNode, player) {
      const legalCaptures = [];
      if (board[fromNode] !== player) return legalCaptures;
      const opponent = this.getOpponent(player);
      const jumps = JUMP_TABLE[fromNode];
      if (!jumps) return legalCaptures;
      for (const overKey in jumps) {
        const overNode = parseInt(overKey);
        const landNode = jumps[overNode];
        if (board[overNode] === opponent && board[landNode] === 0 /* NONE */) {
          legalCaptures.push({
            from: fromNode,
            to: landNode,
            is_capture: true,
            captured: overNode
          });
        }
      }
      return legalCaptures;
    }
    static getSimpleMovesForPiece(board, fromNode, player) {
      const moves = [];
      if (board[fromNode] !== player) return moves;
      const neighbors = ADJACENCY[fromNode];
      if (!neighbors) return moves;
      for (const target of neighbors) {
        if (board[target] === 0 /* NONE */) {
          moves.push({
            from: fromNode,
            to: target,
            is_capture: false,
            captured: -1
          });
        }
      }
      return moves;
    }
    static hasAnyCaptureForPlayer(board, player) {
      for (let i = 0; i < TOTAL_NODES; i++) {
        if (board[i] === player) {
          const caps = this.getCapturesForPiece(board, i, player);
          if (caps.length > 0) return true;
        }
      }
      return false;
    }
    static getLegalMovesForPiece(board, fromNode, player, isInMultiCapture, multiCaptureNode) {
      if (board[fromNode] !== player) return [];
      if (isInMultiCapture) {
        if (fromNode !== multiCaptureNode) return [];
        return this.getCapturesForPiece(board, fromNode, player);
      }
      const captures = this.getCapturesForPiece(board, fromNode, player);
      const simple = this.getSimpleMovesForPiece(board, fromNode, player);
      return [...captures, ...simple];
    }
    static getAllLegalMoves(board, player, isInMultiCapture, multiCaptureNode) {
      if (isInMultiCapture) {
        return this.getCapturesForPiece(board, multiCaptureNode, player);
      }
      const allMoves = [];
      for (let i = 0; i < TOTAL_NODES; i++) {
        if (board[i] === player) {
          const moves = this.getLegalMovesForPiece(board, i, player, false, -1);
          allMoves.push(...moves);
        }
      }
      return allMoves;
    }
    static validateMove(board, from, to, isCapture, captured, activePlayer, isInMultiCapture, multiCaptureNode) {
      if (from < 0 || from >= TOTAL_NODES || to < 0 || to >= TOTAL_NODES) {
        return { valid: false, reason: "Out of bounds node index" };
      }
      if (board[from] !== activePlayer) {
        return { valid: false, reason: "Piece does not belong to active player" };
      }
      if (board[to] !== 0 /* NONE */) {
        return { valid: false, reason: "Destination node is occupied" };
      }
      if (isInMultiCapture && from !== multiCaptureNode) {
        return { valid: false, reason: "Must continue multi-capture with previous piece" };
      }
      if (isCapture) {
        const jumps = JUMP_TABLE[from];
        if (!jumps || jumps[captured] !== to) {
          return { valid: false, reason: "Invalid jump trajectory" };
        }
        const opponent = this.getOpponent(activePlayer);
        if (board[captured] !== opponent) {
          return { valid: false, reason: "Jumped node does not contain opponent piece" };
        }
        return { valid: true };
      } else {
        if (isInMultiCapture) {
          return { valid: false, reason: "Cannot make simple move during multi-capture" };
        }
        const neighbors = ADJACENCY[from];
        if (!neighbors || !neighbors.includes(to)) {
          return { valid: false, reason: "Nodes are not directly connected" };
        }
        return { valid: true };
      }
    }
    static applyMove(board, from, to, isCapture, captured, activePlayer) {
      const nextBoard = [...board];
      nextBoard[from] = 0 /* NONE */;
      nextBoard[to] = activePlayer;
      let multiCaptureAvailable = false;
      let multiCaptureNode = -1;
      let turnEnded = true;
      if (isCapture && captured >= 0) {
        nextBoard[captured] = 0 /* NONE */;
        const further = this.getCapturesForPiece(nextBoard, to, activePlayer);
        if (further.length > 0) {
          multiCaptureAvailable = true;
          multiCaptureNode = to;
          turnEnded = false;
        }
      }
      return {
        board: nextBoard,
        turnEnded,
        multiCaptureAvailable,
        multiCaptureNode
      };
    }
    static checkGameOver(board, p1Pieces, p2Pieces, nextActivePlayer, isInMultiCapture, multiCaptureNode) {
      if (p1Pieces <= 0) {
        return { isGameOver: true, winner: 2 /* PLAYER_2 */, reason: "NORMAL_WIN" /* NORMAL_WIN */ };
      }
      if (p2Pieces <= 0) {
        return { isGameOver: true, winner: 1 /* PLAYER_1 */, reason: "NORMAL_WIN" /* NORMAL_WIN */ };
      }
      const legalMoves = this.getAllLegalMoves(board, nextActivePlayer, isInMultiCapture, multiCaptureNode);
      if (legalMoves.length === 0) {
        const winner = this.getOpponent(nextActivePlayer);
        return { isGameOver: true, winner, reason: "NO_MOVES" /* NO_MOVES */ };
      }
      return { isGameOver: false, winner: 0 /* NONE */, reason: "" };
    }
  };

  // src/security.ts
  var rateLimitMap = {};
  var suspicionScoreMap = {};
  var SecurityManager = class {
    /**
     * Sliding-window rate limiter
     */
    static checkRateLimit(userId, maxRequests = 8, windowMs = 1e3) {
      const now = Date.now();
      const tracker = rateLimitMap[userId];
      if (!tracker || now > tracker.resetTimeMs) {
        rateLimitMap[userId] = {
          count: 1,
          resetTimeMs: now + windowMs
        };
        return true;
      }
      tracker.count++;
      if (tracker.count > maxRequests) {
        this.recordSecurityEvent(null, userId, "rate_limit_exceeded", {
          requests: tracker.count,
          windowMs
        });
        return false;
      }
      return true;
    }
    /**
     * Checks client version against server-configured minimum version
     */
    static isClientVersionAllowed(clientVersion, minVersion = "1.0.0") {
      if (!clientVersion) return false;
      const parse = (v) => v.split(".").map((n) => parseInt(n) || 0);
      const cParts = parse(clientVersion);
      const mParts = parse(minVersion);
      for (let i = 0; i < Math.max(cParts.length, mParts.length); i++) {
        const c = cParts[i] || 0;
        const m = mParts[i] || 0;
        if (c > m) return true;
        if (c < m) return false;
      }
      return true;
    }
    /**
     * Increments suspicious score and flags account if threshold exceeded
     */
    static addSuspicionScore(nk, userId, points, reason, meta = {}) {
      const current = (suspicionScoreMap[userId] || 0) + points;
      suspicionScoreMap[userId] = current;
      this.recordSecurityEvent(nk, userId, "suspicious_activity", {
        reason,
        pointsAdded: points,
        totalScore: current,
        meta
      });
      if (current >= 100) {
        try {
          if (nk && nk.sqlExec) {
            nk.sqlExec(
              `INSERT INTO player_restrictions (user_id, restriction_type, reason, expires_at)
                         VALUES ($1, 'TEMP_RESTRICTION', $2, NOW() + INTERVAL '24 hours')`,
              [userId, reason]
            );
          }
        } catch (err) {
        }
      }
    }
    /**
     * Persists security audit event to PostgreSQL table
     */
    static recordSecurityEvent(nk, userId, eventType, metadata) {
      try {
        if (nk && nk.sqlExec) {
          nk.sqlExec(
            `INSERT INTO security_events (user_id, event_type, metadata)
                     VALUES ($1, $2, $3)`,
            [userId, eventType, JSON.stringify(metadata)]
          );
        }
      } catch (e) {
      }
    }
  };

  // src/wallet.ts
  var ServerWallet = class {
    /**
     * Gets user's current authoritative coin balance
     */
    static getBalance(nk, userId) {
      try {
        const rows = nk.sqlQuery(
          `SELECT balance FROM wallets WHERE user_id = $1`,
          [userId]
        );
        if (rows && rows.length > 0) {
          return parseInt(rows[0].balance) || 0;
        }
        nk.sqlExec(
          `INSERT INTO wallets (user_id, balance) VALUES ($1, 500) ON CONFLICT (user_id) DO NOTHING`,
          [userId]
        );
        return 500;
      } catch (e) {
        return 500;
      }
    }
    /**
     * Adds an atomic transaction to the ledger and updates wallet balance
     * Uses reference_id for idempotency protection against replay attacks
     */
    static processTransaction(nk, userId, type, amount, referenceId) {
      try {
        if (referenceId) {
          const existing = nk.sqlQuery(
            `SELECT transaction_id FROM coin_transactions WHERE reference_id = $1`,
            [referenceId]
          );
          if (existing && existing.length > 0) {
            return {
              success: false,
              newBalance: this.getBalance(nk, userId),
              error: "Duplicate transaction reference ID rejected"
            };
          }
        }
        const currentBalance = this.getBalance(nk, userId);
        const targetBalance = currentBalance + amount;
        if (targetBalance < 0) {
          return {
            success: false,
            newBalance: currentBalance,
            error: "Insufficient coin balance"
          };
        }
        const txId = "tx_" + Date.now() + "_" + Math.floor(Math.random() * 1e5);
        nk.sqlExec(
          `INSERT INTO coin_transactions (transaction_id, user_id, type, amount, reference_id)
                 VALUES ($1, $2, $3, $4, $5)`,
          [txId, userId, type, amount, referenceId || txId]
        );
        nk.sqlExec(
          `UPDATE wallets SET balance = $1, updated_at = NOW() WHERE user_id = $2`,
          [targetBalance, userId]
        );
        return {
          success: true,
          newBalance: targetBalance
        };
      } catch (err) {
        return {
          success: false,
          newBalance: this.getBalance(nk, userId),
          error: err.message || "Wallet transaction failed"
        };
      }
    }
  };

  // src/match_handler.ts
  var TICK_RATE = 10;
  var RECONNECT_GRACE_PERIOD_SEC = 45;
  var matchHandler = {
    matchInit(ctx, logger, nk, params) {
      const matchState = {
        matchId: ctx.matchId,
        roomCode: params.room_code || void 0,
        mode: params.mode || "1v1_ONLINE",
        status: "WAITING" /* WAITING */,
        players: {},
        player1Id: "",
        player2Id: "",
        board: AuthoritativeRulesEngine.createInitialBoard(),
        activePlayer: 1 /* PLAYER_1 */,
        // Player 1 (Red/bottom) moves first
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
        winner: 0 /* NONE */,
        loser: 0 /* NONE */,
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
    matchJoinAttempt(ctx, logger, nk, dispatcher, tick, state, presence, metadata) {
      if (state.players[presence.userId]) {
        return { state, accept: true };
      }
      const count = Object.keys(state.players).length;
      if (count >= 2) {
        return { state, accept: false, rejectMessage: "Match is already full" };
      }
      if (state.status !== "WAITING" /* WAITING */ && state.status !== "READY" /* READY */) {
        return { state, accept: false, rejectMessage: "Match has already concluded" };
      }
      return { state, accept: true };
    },
    matchJoin(ctx, logger, nk, dispatcher, tick, state, presences) {
      for (const presence of presences) {
        const userId = presence.userId;
        if (state.players[userId]) {
          const p = state.players[userId];
          p.connected = true;
          p.presence = presence;
          delete p.disconnectedAtSec;
          const nowSec = Math.floor(Date.now() / 1e3);
          let isExtra = false;
          let turnRem = state.turnNormalDurationSec;
          if (state.turnStartTimeSec > 0) {
            const elapsed = nowSec - state.turnStartTimeSec;
            const activeReserve = state.activePlayer === 1 /* PLAYER_1 */ ? state.p1ExtraTimeRemainingSec : state.p2ExtraTimeRemainingSec;
            if (elapsed <= state.turnNormalDurationSec) {
              isExtra = false;
              turnRem = Math.max(0, state.turnNormalDurationSec - elapsed);
            } else {
              isExtra = true;
              const consumed = elapsed - state.turnNormalDurationSec;
              turnRem = Math.max(0, activeReserve - consumed);
            }
          }
          const curP1Extra = state.activePlayer === 1 /* PLAYER_1 */ && isExtra ? turnRem : state.p1ExtraTimeRemainingSec;
          const curP2Extra = state.activePlayer === 2 /* PLAYER_2 */ && isExtra ? turnRem : state.p2ExtraTimeRemainingSec;
          dispatcher.broadcastMessage(
            4 /* OP_STATE_SYNC */,
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
          dispatcher.broadcastMessage(
            9 /* OP_PLAYER_RECONNECTED */,
            JSON.stringify({ user_id: userId }),
            null,
            presence
          );
          continue;
        }
        const isFirst = !state.player1Id;
        const playerIndex = isFirst ? 1 /* PLAYER_1 */ : 2 /* PLAYER_2 */;
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
          lastPingAtSec: Date.now() / 1e3,
          lastSeq: 0
        };
      }
      if (Object.keys(state.players).length === 2 && state.status === "WAITING" /* WAITING */) {
        state.status = "PLAYING" /* PLAYING */;
        const nowSec = Math.floor(Date.now() / 1e3);
        state.matchStartTimeSec = nowSec;
        state.remainingSeconds = state.matchDurationLimitSec;
        state.turnStartTimeSec = nowSec;
        state.isInExtraTime = false;
        state.turnRemainingSeconds = state.turnNormalDurationSec;
        for (const uid in state.players) {
          const pl = state.players[uid];
          dispatcher.broadcastMessage(
            4 /* OP_STATE_SYNC */,
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
              opponent_id: pl.playerIndex === 1 /* PLAYER_1 */ ? state.player2Id : state.player1Id,
              opponent_name: pl.playerIndex === 1 /* PLAYER_1 */ ? state.players[state.player2Id]?.username : state.players[state.player1Id]?.username,
              server_time: nowSec
            }),
            [pl.presence]
          );
        }
        try {
          nk.sqlExec(
            `INSERT INTO matches (match_id, player_1, player_2, mode, status, started_at)
                     VALUES ($1, $2, $3, $4, 'PLAYING', NOW())`,
            [state.matchId, state.player1Id, state.player2Id, state.mode]
          );
        } catch (e) {
        }
      }
      return { state };
    },
    matchLeave(ctx, logger, nk, dispatcher, tick, state, presences) {
      for (const presence of presences) {
        const p = state.players[presence.userId];
        if (p) {
          p.connected = false;
          p.disconnectedAtSec = Math.floor(Date.now() / 1e3);
          dispatcher.broadcastMessage(
            10 /* OP_PLAYER_DISCONNECTED */,
            JSON.stringify({
              user_id: presence.userId,
              grace_period_sec: RECONNECT_GRACE_PERIOD_SEC
            })
          );
        }
      }
      return { state };
    },
    matchLoop(ctx, logger, nk, dispatcher, tick, state, messages) {
      if (state.status === "COMPLETED" /* COMPLETED */ || state.status === "TIME_UP" /* TIME_UP */) {
        return null;
      }
      for (const msg of messages) {
        const senderId = msg.sender.userId;
        const player = state.players[senderId];
        if (!player) continue;
        const opCode = msg.opCode;
        if (opCode === 6 /* OP_PING */) {
          dispatcher.broadcastMessage(6 /* OP_PING */, msg.data, [msg.sender]);
          continue;
        }
        if (opCode === 5 /* OP_RESIGN */) {
          state.winner = player.playerIndex === 1 /* PLAYER_1 */ ? 2 /* PLAYER_2 */ : 1 /* PLAYER_1 */;
          state.loser = player.playerIndex;
          state.endReason = "FORFEIT" /* FORFEIT */;
          this._finishMatch(state, dispatcher, nk);
          return null;
        }
        if (opCode === 11 /* OP_CHAT_MESSAGE */) {
          if (SecurityManager.checkRateLimit(senderId + "_chat", 5, 3e3)) {
            dispatcher.broadcastMessage(11 /* OP_CHAT_MESSAGE */, msg.data, null, msg.sender);
          }
          continue;
        }
        if (opCode === 12 /* OP_EMOJI_REACTION */) {
          if (SecurityManager.checkRateLimit(senderId + "_emoji", 3, 1e3)) {
            dispatcher.broadcastMessage(12 /* OP_EMOJI_REACTION */, msg.data, null, msg.sender);
          }
          continue;
        }
        if (opCode === 13 /* OP_WEBRTC_SIGNAL */) {
          dispatcher.broadcastMessage(13 /* OP_WEBRTC_SIGNAL */, msg.data, null, msg.sender);
          continue;
        }
        if (opCode === 14 /* OP_VOICE_STATUS */) {
          dispatcher.broadcastMessage(14 /* OP_VOICE_STATUS */, msg.data, null, msg.sender);
          continue;
        }
        if (opCode === 1 /* OP_MOVE_REQUEST */) {
          let move;
          try {
            move = JSON.parse(nk.binaryToString(msg.data));
          } catch (e) {
            continue;
          }
          if (!SecurityManager.checkRateLimit(senderId, 6, 1e3)) {
            this._rejectMove(dispatcher, player, "Rate limit exceeded. Move too fast.");
            continue;
          }
          if (state.status !== "PLAYING" /* PLAYING */) {
            this._rejectMove(dispatcher, player, "Match is not currently in playing state.");
            continue;
          }
          if (player.playerIndex !== state.activePlayer) {
            SecurityManager.addSuspicionScore(nk, senderId, 5, "Moved out of turn");
            this._rejectMove(dispatcher, player, "Not your turn.");
            continue;
          }
          const nowSec = Math.floor(Date.now() / 1e3);
          const elapsedTurn = state.turnStartTimeSec > 0 ? nowSec - state.turnStartTimeSec : 0;
          const activeReserve = state.activePlayer === 1 /* PLAYER_1 */ ? state.p1ExtraTimeRemainingSec : state.p2ExtraTimeRemainingSec;
          if (elapsedTurn > state.turnNormalDurationSec) {
            const extraConsumed = elapsedTurn - state.turnNormalDurationSec;
            if (extraConsumed >= activeReserve) {
              if (state.activePlayer === 1 /* PLAYER_1 */) {
                state.p1ExtraTimeRemainingSec = 0;
              } else {
                state.p2ExtraTimeRemainingSec = 0;
              }
              SecurityManager.recordSecurityEvent(nk, senderId, "move_after_timeout", {
                elapsed: elapsedTurn,
                reserve: activeReserve
              });
              this._rejectMove(dispatcher, player, "Turn timed out. Extra time depleted.");
              state.status = "COMPLETED" /* COMPLETED */;
              state.winner = AuthoritativeRulesEngine.getOpponent(state.activePlayer);
              state.loser = state.activePlayer;
              state.endReason = "TIMEOUT" /* TIMEOUT */;
              this._finishMatch(state, dispatcher, nk);
              return null;
            }
          }
          if (move.client_seq && move.client_seq <= player.lastSeq) {
            SecurityManager.recordSecurityEvent(nk, senderId, "duplicate_move_seq", { seq: move.client_seq });
            this._rejectMove(dispatcher, player, "Duplicate or out-of-order move sequence rejected.");
            continue;
          }
          player.lastSeq = move.client_seq || player.lastSeq + 1;
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
          if (elapsedTurn > state.turnNormalDurationSec) {
            const extraConsumed = elapsedTurn - state.turnNormalDurationSec;
            if (state.activePlayer === 1 /* PLAYER_1 */) {
              state.p1ExtraTimeRemainingSec = Math.max(0, state.p1ExtraTimeRemainingSec - extraConsumed);
            } else {
              state.p2ExtraTimeRemainingSec = Math.max(0, state.p2ExtraTimeRemainingSec - extraConsumed);
            }
          }
          const result = AuthoritativeRulesEngine.applyMove(
            state.board,
            move.from,
            move.to,
            move.is_capture,
            move.captured,
            state.activePlayer
          );
          state.board = result.board;
          if (move.is_capture) {
            player.captures += 1;
            const opponentUid = player.playerIndex === 1 /* PLAYER_1 */ ? state.player2Id : state.player1Id;
            if (state.players[opponentUid]) {
              state.players[opponentUid].remainingPieces -= 1;
            }
          }
          state.moveHistory.push({
            turn: state.turnNumber,
            player: state.activePlayer,
            from: move.from,
            to: move.to,
            is_capture: move.is_capture,
            captured: move.captured,
            client_seq: move.client_seq
          });
          if (result.multiCaptureAvailable) {
            state.isInMultiCapture = true;
            state.multiCaptureNode = result.multiCaptureNode;
          } else {
            state.isInMultiCapture = false;
            state.multiCaptureNode = -1;
            state.activePlayer = AuthoritativeRulesEngine.getOpponent(state.activePlayer);
            state.turnNumber += 1;
          }
          state.turnStartTimeSec = Math.floor(Date.now() / 1e3);
          state.isInExtraTime = false;
          state.turnRemainingSeconds = state.turnNormalDurationSec;
          dispatcher.broadcastMessage(
            2 /* OP_MOVE_ACCEPTED */,
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
            state.endReason = gameOver.reason;
            this._finishMatch(state, dispatcher, nk);
            return null;
          }
        }
      }
      if (state.status === "PLAYING" /* PLAYING */ && tick % TICK_RATE === 0) {
        const nowSec = Math.floor(Date.now() / 1e3);
        state.remainingSeconds = Math.max(0, state.matchDurationLimitSec - (nowSec - state.matchStartTimeSec));
        const elapsedTurn = state.turnStartTimeSec > 0 ? nowSec - state.turnStartTimeSec : 0;
        const activeReserve = state.activePlayer === 1 /* PLAYER_1 */ ? state.p1ExtraTimeRemainingSec : state.p2ExtraTimeRemainingSec;
        if (elapsedTurn <= state.turnNormalDurationSec) {
          state.isInExtraTime = false;
          state.turnRemainingSeconds = Math.max(0, state.turnNormalDurationSec - elapsedTurn);
        } else {
          state.isInExtraTime = true;
          const extraConsumed = elapsedTurn - state.turnNormalDurationSec;
          state.turnRemainingSeconds = Math.max(0, activeReserve - extraConsumed);
        }
        const currentP1Extra = state.activePlayer === 1 /* PLAYER_1 */ && state.isInExtraTime ? state.turnRemainingSeconds : state.p1ExtraTimeRemainingSec;
        const currentP2Extra = state.activePlayer === 2 /* PLAYER_2 */ && state.isInExtraTime ? state.turnRemainingSeconds : state.p2ExtraTimeRemainingSec;
        dispatcher.broadcastMessage(
          7 /* OP_TIMER_TICK */,
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
        if (state.isInExtraTime && state.turnRemainingSeconds <= 0) {
          if (state.activePlayer === 1 /* PLAYER_1 */) {
            state.p1ExtraTimeRemainingSec = 0;
          } else {
            state.p2ExtraTimeRemainingSec = 0;
          }
          state.status = "COMPLETED" /* COMPLETED */;
          state.winner = AuthoritativeRulesEngine.getOpponent(state.activePlayer);
          state.loser = state.activePlayer;
          state.endReason = "TIMEOUT" /* TIMEOUT */;
          SecurityManager.recordSecurityEvent(nk, state.activePlayer === 1 /* PLAYER_1 */ ? state.player1Id : state.player2Id, "turn_timeout_forfeit", {
            player: state.activePlayer,
            turn: state.turnNumber
          });
          this._finishMatch(state, dispatcher, nk);
          return null;
        }
        if (state.remainingSeconds <= 0) {
          state.status = "TIME_UP" /* TIME_UP */;
          state.endReason = "TIME_UP" /* TIME_UP */;
          const p1Count = state.players[state.player1Id]?.remainingPieces ?? 16;
          const p2Count = state.players[state.player2Id]?.remainingPieces ?? 16;
          if (p1Count > p2Count) {
            state.winner = 1 /* PLAYER_1 */;
            state.loser = 2 /* PLAYER_2 */;
          } else if (p2Count > p1Count) {
            state.winner = 2 /* PLAYER_2 */;
            state.loser = 1 /* PLAYER_1 */;
          } else {
            state.winner = 0 /* NONE */;
            state.loser = 0 /* NONE */;
          }
          this._finishMatch(state, dispatcher, nk);
          return null;
        }
        for (const uid in state.players) {
          const pl = state.players[uid];
          if (!pl.connected && pl.disconnectedAtSec) {
            if (nowSec - pl.disconnectedAtSec > RECONNECT_GRACE_PERIOD_SEC) {
              state.winner = pl.playerIndex === 1 /* PLAYER_1 */ ? 2 /* PLAYER_2 */ : 1 /* PLAYER_1 */;
              state.loser = pl.playerIndex;
              state.endReason = "OPPONENT_DISCONNECTED" /* OPPONENT_DISCONNECTED */;
              this._finishMatch(state, dispatcher, nk);
              return null;
            }
          }
        }
      }
      return { state };
    },
    _rejectMove(dispatcher, player, reason) {
      dispatcher.broadcastMessage(
        3 /* OP_MOVE_REJECTED */,
        JSON.stringify({ reason }),
        [player.presence]
      );
    },
    _finishMatch(state, dispatcher, nk) {
      state.status = "COMPLETED" /* COMPLETED */;
      const p1 = state.players[state.player1Id];
      const p2 = state.players[state.player2Id];
      const winnerUid = state.winner === 1 /* PLAYER_1 */ ? state.player1Id : state.winner === 2 /* PLAYER_2 */ ? state.player2Id : null;
      const loserUid = state.loser === 1 /* PLAYER_1 */ ? state.player1Id : state.loser === 2 /* PLAYER_2 */ ? state.player2Id : null;
      dispatcher.broadcastMessage(
        8 /* OP_MATCH_OVER */,
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
      try {
        const dur = Math.max(1, state.matchDurationLimitSec - state.remainingSeconds);
        nk.sqlExec(
          `UPDATE matches SET status = 'COMPLETED', ended_at = NOW(), duration_seconds = $1 WHERE match_id = $2`,
          [dur, state.matchId]
        );
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
        if (winnerUid) {
          ServerWallet.processTransaction(nk, winnerUid, "WIN_REWARD", 100, `match_win_${state.matchId}`);
          this._updateStats(nk, winnerUid, true, false, p1?.userId === winnerUid ? p1.captures : p2?.captures || 0, dur);
        }
        if (loserUid) {
          ServerWallet.processTransaction(nk, loserUid, "MATCH_REWARD", 20, `match_loss_${state.matchId}`);
          this._updateStats(nk, loserUid, false, false, p1?.userId === loserUid ? p1.captures : p2?.captures || 0, dur);
        }
        if (!winnerUid && !loserUid) {
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
      }
    },
    _updateStats(nk, userId, won, draw, captures, duration) {
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
          [userId, won ? 1 : 0, !won && !draw ? 1 : 0, draw ? 1 : 0, captures, won ? 1 : 0, duration]
        );
      } catch (e) {
      }
    },
    matchTerminate(ctx, logger, nk, dispatcher, tick, state, graceSeconds) {
      return { state };
    }
  };

  // src/inventory_shop.ts
  var InventoryShopManager = class {
    static getShopCatalog(nk) {
      try {
        const rows = nk.sqlQuery(
          `SELECT item_id, name, category, price_coins, is_active, metadata
                 FROM shop_items WHERE is_active = true ORDER BY price_coins ASC`
        );
        return rows || [];
      } catch (e) {
        return [];
      }
    }
    static getUserInventory(nk, userId) {
      try {
        const rows = nk.sqlQuery(
          `SELECT item_id FROM inventory WHERE user_id = $1`,
          [userId]
        );
        if (!rows) return ["classic_red", "classic_wood", "classic_sparkle", "warrior_avatar"];
        return rows.map((r) => r.item_id);
      } catch (e) {
        return ["classic_red", "classic_wood", "classic_sparkle", "warrior_avatar"];
      }
    }
    static getEquippedItems(nk, userId) {
      try {
        const rows = nk.sqlQuery(
          `SELECT guti_skin, board_theme, victory_effect, avatar FROM equipped_items WHERE user_id = $1`,
          [userId]
        );
        if (rows && rows.length > 0) {
          return rows[0];
        }
        return {
          guti_skin: "Classic Red",
          board_theme: "Classic Wood",
          victory_effect: "Classic Sparkle",
          avatar: "Warrior"
        };
      } catch (e) {
        return {
          guti_skin: "Classic Red",
          board_theme: "Classic Wood",
          victory_effect: "Classic Sparkle",
          avatar: "Warrior"
        };
      }
    }
    static purchaseItem(nk, userId, itemId) {
      try {
        const itemRows = nk.sqlQuery(
          `SELECT item_id, name, category, price_coins, is_active FROM shop_items WHERE item_id = $1 AND is_active = true`,
          [itemId]
        );
        if (!itemRows || itemRows.length === 0) {
          return { success: false, error: "Item not found or inactive" };
        }
        const item = itemRows[0];
        const price = parseInt(item.price_coins) || 0;
        const owned = nk.sqlQuery(
          `SELECT id FROM inventory WHERE user_id = $1 AND item_id = $2`,
          [userId, itemId]
        );
        if (owned && owned.length > 0) {
          return { success: false, error: "Item already owned" };
        }
        const refId = `shop_buy_${userId}_${itemId}_${Date.now()}`;
        const txResult = ServerWallet.processTransaction(nk, userId, "PURCHASE", -price, refId);
        if (!txResult.success) {
          return { success: false, error: txResult.error };
        }
        nk.sqlExec(
          `INSERT INTO inventory (user_id, item_id, quantity) VALUES ($1, $2, 1)`,
          [userId, itemId]
        );
        return {
          success: true,
          newBalance: txResult.newBalance
        };
      } catch (err) {
        return { success: false, error: err.message || "Purchase failed" };
      }
    }
    static equipItem(nk, userId, category, itemName) {
      try {
        let col = "";
        switch (category.toUpperCase()) {
          case "GUTI_SKIN":
            col = "guti_skin";
            break;
          case "BOARD_THEME":
            col = "board_theme";
            break;
          case "VICTORY_EFFECT":
            col = "victory_effect";
            break;
          case "AVATAR":
            col = "avatar";
            break;
          default:
            return { success: false, error: "Invalid cosmetic category" };
        }
        nk.sqlExec(
          `INSERT INTO equipped_items (user_id, ${col}) VALUES ($1, $2)
                 ON CONFLICT (user_id) DO UPDATE SET ${col} = EXCLUDED.${col}, updated_at = NOW()`,
          [userId, itemName]
        );
        return { success: true };
      } catch (err) {
        return { success: false, error: err.message || "Equip failed" };
      }
    }
  };

  // src/rewards.ts
  var DAILY_REWARDS_TABLE = [
    50,
    // Day 1
    100,
    // Day 2
    150,
    // Day 3
    250,
    // Day 4
    350,
    // Day 5
    500,
    // Day 6
    1e3
    // Day 7
  ];
  var RewardsManager = class {
    static getDailyRewardStatus(nk, userId) {
      try {
        const rows = nk.sqlQuery(
          `SELECT streak_day, last_claimed_at, next_claim_available_at FROM daily_rewards WHERE user_id = $1`,
          [userId]
        );
        const now = /* @__PURE__ */ new Date();
        if (!rows || rows.length === 0) {
          return {
            streak: 0,
            canClaim: true,
            nextReward: DAILY_REWARDS_TABLE[0],
            rewardsTable: DAILY_REWARDS_TABLE
          };
        }
        const row = rows[0];
        const streak = parseInt(row.streak_day) || 0;
        const lastClaim = row.last_claimed_at ? new Date(row.last_claimed_at) : null;
        if (!lastClaim) {
          return {
            streak: 0,
            canClaim: true,
            nextReward: DAILY_REWARDS_TABLE[0],
            rewardsTable: DAILY_REWARDS_TABLE
          };
        }
        const diffHours = (now.getTime() - lastClaim.getTime()) / (1e3 * 60 * 60);
        const canClaim = diffHours >= 20;
        const effectiveStreak = diffHours > 48 ? 0 : streak;
        const nextDayIndex = effectiveStreak % 7;
        return {
          streak: effectiveStreak,
          canClaim,
          nextReward: DAILY_REWARDS_TABLE[nextDayIndex],
          rewardsTable: DAILY_REWARDS_TABLE,
          hoursUntilNextClaim: canClaim ? 0 : Math.max(0, 20 - diffHours)
        };
      } catch (e) {
        return {
          streak: 0,
          canClaim: true,
          nextReward: DAILY_REWARDS_TABLE[0],
          rewardsTable: DAILY_REWARDS_TABLE
        };
      }
    }
    static claimDailyReward(nk, userId) {
      const status = this.getDailyRewardStatus(nk, userId);
      if (!status.canClaim) {
        return { success: false, error: "Daily reward is not ready yet. Please wait." };
      }
      const nextStreak = status.streak % 7 + 1;
      const rewardCoins = DAILY_REWARDS_TABLE[nextStreak - 1];
      const refId = `daily_${userId}_streak_${nextStreak}_${Date.now()}`;
      const tx = ServerWallet.processTransaction(nk, userId, "DAILY_REWARD", rewardCoins, refId);
      if (!tx.success) {
        return { success: false, error: tx.error };
      }
      try {
        nk.sqlExec(
          `INSERT INTO daily_rewards (user_id, streak_day, last_claimed_at, next_claim_available_at)
                 VALUES ($1, $2, NOW(), NOW() + INTERVAL '20 hours')
                 ON CONFLICT (user_id) DO UPDATE SET
                    streak_day = EXCLUDED.streak_day,
                    last_claimed_at = NOW(),
                    next_claim_available_at = NOW() + INTERVAL '20 hours'`,
          [userId, nextStreak]
        );
      } catch (err) {
      }
      return {
        success: true,
        newBalance: tx.newBalance,
        streak: nextStreak,
        coinsAwarded: rewardCoins
      };
    }
    static claimAdReward(nk, userId, referenceId) {
      try {
        const countRows = nk.sqlQuery(
          `SELECT COUNT(*) as count FROM ad_rewards WHERE user_id = $1 AND claimed_date = CURRENT_DATE`,
          [userId]
        );
        const count = countRows && countRows.length > 0 ? parseInt(countRows[0].count) || 0 : 0;
        const maxAds = 5;
        if (count >= maxAds) {
          return {
            success: false,
            error: `Daily rewarded ad limit (${maxAds}) reached for today. Come back tomorrow!`
          };
        }
        const existing = nk.sqlQuery(
          `SELECT reward_id FROM ad_rewards WHERE reference_id = $1`,
          [referenceId]
        );
        if (existing && existing.length > 0) {
          return { success: false, error: "Duplicate ad reward transaction detected." };
        }
        const rewardCoins = 50;
        const tx = ServerWallet.processTransaction(nk, userId, "AD_REWARD", rewardCoins, referenceId);
        if (!tx.success) {
          return { success: false, error: tx.error };
        }
        const rewardId = "ad_" + Date.now() + "_" + Math.floor(Math.random() * 1e4);
        nk.sqlExec(
          `INSERT INTO ad_rewards (reward_id, user_id, reference_id, reward_type, coins_granted, claimed_date, claimed_at)
                 VALUES ($1, $2, $3, 'COINS', $4, CURRENT_DATE, NOW())`,
          [rewardId, userId, referenceId, rewardCoins]
        );
        return {
          success: true,
          newBalance: tx.newBalance,
          coinsAwarded: rewardCoins,
          remainingToday: maxAds - (count + 1)
        };
      } catch (err) {
        return { success: false, error: err.message || "Failed to grant ad reward" };
      }
    }
  };

  // src/profile_stats.ts
  var ProfileStatsManager = class {
    static getFullProfile(nk, userId) {
      try {
        let profile = {
          user_id: userId,
          display_name: "Guti Player",
          avatar_id: 0,
          level: 1,
          xp: 0,
          settings: { sfx: true, bgm: true, haptics: true }
        };
        const pRows = nk.sqlQuery(`SELECT display_name, avatar_id, level, xp, settings FROM profiles WHERE user_id = $1`, [userId]);
        if (pRows && pRows.length > 0) {
          profile = {
            ...profile,
            ...pRows[0],
            settings: typeof pRows[0].settings === "string" ? JSON.parse(pRows[0].settings) : pRows[0].settings
          };
        } else {
          nk.sqlExec(
            `INSERT INTO profiles (user_id, display_name, avatar_id, level, xp)
                     VALUES ($1, 'Guti Player', 0, 1, 0) ON CONFLICT (user_id) DO NOTHING`,
            [userId]
          );
        }
        const coins = ServerWallet.getBalance(nk, userId);
        const equipped = InventoryShopManager.getEquippedItems(nk, userId);
        const inventory = InventoryShopManager.getUserInventory(nk, userId);
        let stats = {
          matches_played: 0,
          wins: 0,
          losses: 0,
          draws: 0,
          captures: 0,
          win_streak: 0,
          best_streak: 0,
          total_play_time: 0
        };
        const sRows = nk.sqlQuery(`SELECT * FROM player_statistics WHERE user_id = $1`, [userId]);
        if (sRows && sRows.length > 0) {
          stats = { ...stats, ...sRows[0] };
        }
        return {
          ...profile,
          coins,
          equipped,
          inventory,
          statistics: stats
        };
      } catch (err) {
        return {
          user_id: userId,
          display_name: "Guti Player",
          avatar_id: 0,
          level: 1,
          xp: 0,
          coins: 500,
          settings: { sfx: true, bgm: true, haptics: true }
        };
      }
    }
    static updateProfile(nk, userId, displayName, avatarId, settings) {
      try {
        let safeName = displayName ? displayName.trim().substring(0, 24) : null;
        let safeAvatar = typeof avatarId === "number" && avatarId >= 0 && avatarId <= 15 ? avatarId : null;
        nk.sqlExec(
          `INSERT INTO profiles (user_id, display_name, avatar_id, settings, updated_at)
                 VALUES ($1, COALESCE($2, 'Guti Player'), COALESCE($3, 0), $4::jsonb, NOW())
                 ON CONFLICT (user_id) DO UPDATE SET
                    display_name = COALESCE($2, profiles.display_name),
                    avatar_id = COALESCE($3, profiles.avatar_id),
                    settings = COALESCE($4::jsonb, profiles.settings),
                    updated_at = NOW()`,
          [userId, safeName, safeAvatar, settings ? JSON.stringify(settings) : null]
        );
        return { success: true };
      } catch (e) {
        return { success: false, error: e.message || "Failed to update profile" };
      }
    }
    static getMatchHistory(nk, userId, limit = 10, offset = 0) {
      try {
        const rows = nk.sqlQuery(
          `SELECT m.match_id, m.player_1, m.player_2, m.mode, m.status, m.duration_seconds, m.started_at,
                        r.winner_id, r.loser_id, r.end_reason
                 FROM matches m
                 LEFT JOIN match_results r ON m.match_id = r.match_id
                 WHERE m.player_1 = $1 OR m.player_2 = $1
                 ORDER BY m.started_at DESC
                 LIMIT $2 OFFSET $3`,
          [userId, limit, offset]
        );
        return rows || [];
      } catch (e) {
        return [];
      }
    }
    static getAchievements(nk, userId) {
      try {
        const rows = nk.sqlQuery(
          `SELECT a.achievement_id, a.title, a.description, a.category, a.target_value, a.reward_coins, a.reward_xp,
                        COALESCE(pa.current_value, 0) as current_value,
                        COALESCE(pa.is_unlocked, false) as is_unlocked,
                        pa.unlocked_at
                 FROM achievements a
                 LEFT JOIN player_achievements pa ON a.achievement_id = pa.achievement_id AND pa.user_id = $1
                 ORDER BY a.target_value ASC`,
          [userId]
        );
        return rows || [];
      } catch (e) {
        return [];
      }
    }
  };

  // src/matchmaking.ts
  var MatchmakingService = class {
    static findOrCreate1v1Match(nk, userId) {
      try {
        const matches = nk.matchList(10, true, null, 1, 1, "+label.status:WAITING +label.mode:1v1_ONLINE");
        if (matches && matches.length > 0) {
          return { matchId: matches[0].matchId };
        }
      } catch (e) {
      }
      const matchId = nk.matchCreate("match_16guti", {
        mode: "1v1_ONLINE"
      });
      return { matchId };
    }
    static createPrivateRoom(nk, userId) {
      const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
      let roomCode = "GT";
      for (let i = 0; i < 4; i++) {
        roomCode += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      const matchId = nk.matchCreate("match_16guti", {
        mode: "PRIVATE_ROOM",
        room_code: roomCode
      });
      return { matchId, roomCode };
    }
    static joinPrivateRoom(nk, userId, roomCode) {
      const cleanCode = roomCode.trim().toUpperCase();
      try {
        const matches = nk.matchList(10, true, null, 1, 1, `+label.room_code:${cleanCode}`);
        if (matches && matches.length > 0) {
          return { matchId: matches[0].matchId };
        }
      } catch (e) {
      }
      return { error: "Room not found or game already in progress." };
    }
  };

  // src/main.ts
  function InitModule(ctx, logger, nk, initializer) {
    logger.info("==================================================");
    logger.info("   16 GUTI - AUTHORITATIVE SERVER INITIALIZED    ");
    logger.info("==================================================");
    initializer.registerMatch("match_16guti", matchHandler);
    initializer.registerRpc("rpc_ping", (ctx2, logger2, nk2, payload) => {
      return JSON.stringify({
        server_time_ms: Date.now(),
        client_echo: payload || ""
      });
    });
    initializer.registerRpc("rpc_check_version", (ctx2, logger2, nk2, payload) => {
      let clientVer = "1.0.0";
      try {
        const data = JSON.parse(payload);
        clientVer = data.client_version || "1.0.0";
      } catch (e) {
      }
      const allowed = SecurityManager.isClientVersionAllowed(clientVer, "1.0.0");
      return JSON.stringify({
        allowed,
        min_supported_version: "1.0.0",
        current_server_version: "1.0.0",
        message: allowed ? "OK" : "Please update the game to continue."
      });
    });
    initializer.registerRpc("rpc_get_profile", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const profile = ProfileStatsManager.getFullProfile(nk2, userId);
      return JSON.stringify(profile);
    });
    initializer.registerRpc("rpc_update_profile", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let data = {};
      try {
        data = JSON.parse(payload);
      } catch (e) {
      }
      const result = ProfileStatsManager.updateProfile(nk2, userId, data.display_name, data.avatar_id, data.settings);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_get_wallet", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const balance = ServerWallet.getBalance(nk2, userId);
      return JSON.stringify({ balance });
    });
    initializer.registerRpc("rpc_get_shop", (ctx2, logger2, nk2, payload) => {
      const items = InventoryShopManager.getShopCatalog(nk2);
      return JSON.stringify({ items });
    });
    initializer.registerRpc("rpc_get_inventory", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const inventory = InventoryShopManager.getUserInventory(nk2, userId);
      const equipped = InventoryShopManager.getEquippedItems(nk2, userId);
      return JSON.stringify({ inventory, equipped });
    });
    initializer.registerRpc("rpc_purchase_item", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let data = {};
      try {
        data = JSON.parse(payload);
      } catch (e) {
      }
      const result = InventoryShopManager.purchaseItem(nk2, userId, data.item_id);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_equip_item", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let data = {};
      try {
        data = JSON.parse(payload);
      } catch (e) {
      }
      const result = InventoryShopManager.equipItem(nk2, userId, data.category, data.item_name);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_get_daily_reward_status", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const status = RewardsManager.getDailyRewardStatus(nk2, userId);
      return JSON.stringify(status);
    });
    initializer.registerRpc("rpc_claim_daily_reward", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const result = RewardsManager.claimDailyReward(nk2, userId);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_claim_ad_reward", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let data = {};
      try {
        data = JSON.parse(payload);
      } catch (e) {
      }
      const result = RewardsManager.claimAdReward(nk2, userId, data.reference_id || `ad_${Date.now()}`);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_get_match_history", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let limit = 10;
      let offset = 0;
      try {
        const data = JSON.parse(payload);
        limit = data.limit || 10;
        offset = data.offset || 0;
      } catch (e) {
      }
      const history = ProfileStatsManager.getMatchHistory(nk2, userId, limit, offset);
      return JSON.stringify({ matches: history });
    });
    initializer.registerRpc("rpc_get_achievements", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const achievements = ProfileStatsManager.getAchievements(nk2, userId);
      return JSON.stringify({ achievements });
    });
    initializer.registerRpc("rpc_find_match", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const result = MatchmakingService.findOrCreate1v1Match(nk2, userId);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_create_room", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      const result = MatchmakingService.createPrivateRoom(nk2, userId);
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_join_room", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let data = {};
      try {
        data = JSON.parse(payload);
      } catch (e) {
      }
      const result = MatchmakingService.joinPrivateRoom(nk2, userId, data.room_code || "");
      return JSON.stringify(result);
    });
    initializer.registerRpc("rpc_verify_purchase", (ctx2, logger2, nk2, payload) => {
      const userId = ctx2.userId;
      let data = {};
      try {
        data = JSON.parse(payload);
      } catch (e) {
      }
      if (!data.order_id || !data.purchase_token || !data.product_id) {
        return JSON.stringify({ success: false, error: "Missing purchase verification parameters" });
      }
      try {
        const existing = nk2.sqlQuery(`SELECT purchase_id FROM purchase_records WHERE order_id = $1`, [data.order_id]);
        if (existing && existing.length > 0) {
          return JSON.stringify({ success: false, error: "Purchase token already redeemed" });
        }
        const purchaseId = "gp_" + Date.now();
        nk2.sqlExec(
          `INSERT INTO purchase_records (purchase_id, user_id, order_id, product_id, purchase_token, verified)
                 VALUES ($1, $2, $3, $4, $5, true)`,
          [purchaseId, userId, data.order_id, data.product_id, data.purchase_token]
        );
        let coinsToGrant = 1e3;
        if (data.product_id === "coins_5000") coinsToGrant = 5e3;
        if (data.product_id === "coins_12000") coinsToGrant = 12e3;
        const tx = ServerWallet.processTransaction(nk2, userId, "PURCHASE", coinsToGrant, `gp_order_${data.order_id}`);
        return JSON.stringify({
          success: true,
          new_balance: tx.newBalance,
          coins_granted: coinsToGrant
        });
      } catch (err) {
        return JSON.stringify({ success: false, error: err.message || "Purchase validation failed" });
      }
    });
    logger.info("All 16 Guti Server RPCs & Match Handlers registered successfully.");
  }
  globalThis.InitModule = InitModule;
})();

var InitModule = globalThis.InitModule;
