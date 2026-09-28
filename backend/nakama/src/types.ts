// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE MULTIPLAYER TYPES & CONSTANTS
// ==============================================================================

export enum PlayerId {
    NONE = 0,
    PLAYER_1 = 1, // Bottom / Red
    PLAYER_2 = 2  // Top / Ivory
}

export enum MatchOpCode {
    OP_MOVE_REQUEST = 1,
    OP_MOVE_ACCEPTED = 2,
    OP_MOVE_REJECTED = 3,
    OP_STATE_SYNC = 4,
    OP_RESIGN = 5,
    OP_PING = 6,
    OP_TIMER_TICK = 7,
    OP_MATCH_OVER = 8,
    OP_PLAYER_RECONNECTED = 9,
    OP_PLAYER_DISCONNECTED = 10,
    OP_CHAT_MESSAGE = 11,
    OP_EMOJI_REACTION = 12,
    OP_WEBRTC_SIGNAL = 13,
    OP_VOICE_STATUS = 14
}

export enum MatchStatus {
    WAITING = "WAITING",
    READY = "READY",
    PLAYING = "PLAYING",
    TIME_UP = "TIME_UP",
    COMPLETED = "COMPLETED",
    CANCELLED = "CANCELLED",
    ABANDONED = "ABANDONED"
}

export enum EndReason {
    NORMAL_WIN = "NORMAL_WIN",
    NO_MOVES = "NO_MOVES",
    TIME_UP = "TIME_UP",
    TIMEOUT = "TIMEOUT",
    OPPONENT_DISCONNECTED = "OPPONENT_DISCONNECTED",
    FORFEIT = "FORFEIT"
}

// Configurable Server-Authoritative Timer Constants
export const MATCH_DURATION_SEC = 300;     // 5 minutes total match duration
export const TURN_NORMAL_TIME_SEC = 7;     // 7 seconds per-turn normal time
export const PLAYER_EXTRA_TIME_SEC = 60;   // 60 seconds personal reserve per player

export interface MoveRequest {
    from: number;
    to: number;
    is_capture: boolean;
    captured: number;
    client_seq: number;
}

export interface MatchPlayer {
    presence: any;
    userId: string;
    username: string;
    playerIndex: PlayerId; // 1 or 2
    captures: number;
    remainingPieces: number;
    connected: boolean;
    disconnectedAtSec?: number;
    lastPingAtSec: number;
    lastSeq: number;
}

export interface ServerMatchState {
    matchId: string;
    roomCode?: string;
    mode: string;
    status: MatchStatus;
    players: { [sessionOrUserId: string]: MatchPlayer };
    player1Id: string;
    player2Id: string;
    board: number[]; // Array of 37 integers (0: None, 1: P1, 2: P2)
    activePlayer: PlayerId;
    turnNumber: number;
    isInMultiCapture: boolean;
    multiCaptureNode: number;
    matchStartTimeSec: number;
    matchDurationLimitSec: number; // 300 seconds default (5 minutes)
    remainingSeconds: number; // Match duration remaining
    // Server-Authoritative Turn & Extra Time State
    turnNormalDurationSec: number; // 7 seconds
    playerExtraTimeDurationSec: number; // 60 seconds
    turnStartTimeSec: number; // Wall-clock timestamp when current turn/action began
    p1ExtraTimeRemainingSec: number; // P1 personal reserve (starts at 60s, persistent)
    p2ExtraTimeRemainingSec: number; // P2 personal reserve (starts at 60s, persistent)
    isInExtraTime: boolean; // True if current turn elapsed > 7s
    turnRemainingSeconds: number; // Remaining normal or extra time for active turn
    moveHistory: any[];
    emptyTicks: number;
    winner: PlayerId;
    loser: PlayerId;
    endReason: EndReason | "";
}
