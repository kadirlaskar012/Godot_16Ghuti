// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE RULES ENGINE
// Exact mirror of BoardData.gd and RulesEngine.gd for zero client trust
// ==============================================================================

import { PlayerId, EndReason } from "./types";

export const TOTAL_NODES = 37;
export const PIECES_PER_PLAYER = 16;

// Adjacency List: node_id -> number[]
export const ADJACENCY: { [key: number]: number[] } = {
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

// Jump Table: jump_map[from_node][jumped_node] = landing_node
export const JUMP_TABLE: { [from: number]: { [over: number]: number } } = {
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

export class AuthoritativeRulesEngine {
    static createInitialBoard(): number[] {
        const board = new Array(TOTAL_NODES).fill(PlayerId.NONE);
        // Player 2 (Ivory) at top: nodes 0 to 15
        for (let i = 0; i <= 15; i++) {
            board[i] = PlayerId.PLAYER_2;
        }
        // Middle neutral row: nodes 16 to 20 are NONE
        // Player 1 (Red) at bottom: nodes 21 to 36
        for (let i = 21; i <= 36; i++) {
            board[i] = PlayerId.PLAYER_1;
        }
        return board;
    }

    static getOpponent(player: PlayerId): PlayerId {
        return player === PlayerId.PLAYER_1 ? PlayerId.PLAYER_2 : PlayerId.PLAYER_1;
    }

    static getCapturesForPiece(board: number[], fromNode: number, player: PlayerId): any[] {
        const legalCaptures: any[] = [];
        if (board[fromNode] !== player) return legalCaptures;

        const opponent = this.getOpponent(player);
        const jumps = JUMP_TABLE[fromNode];
        if (!jumps) return legalCaptures;

        for (const overKey in jumps) {
            const overNode = parseInt(overKey);
            const landNode = jumps[overNode];
            if (board[overNode] === opponent && board[landNode] === PlayerId.NONE) {
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

    static getSimpleMovesForPiece(board: number[], fromNode: number, player: PlayerId): any[] {
        const moves: any[] = [];
        if (board[fromNode] !== player) return moves;

        const neighbors = ADJACENCY[fromNode];
        if (!neighbors) return moves;

        for (const target of neighbors) {
            if (board[target] === PlayerId.NONE) {
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

    static hasAnyCaptureForPlayer(board: number[], player: PlayerId): boolean {
        for (let i = 0; i < TOTAL_NODES; i++) {
            if (board[i] === player) {
                const caps = this.getCapturesForPiece(board, i, player);
                if (caps.length > 0) return true;
            }
        }
        return false;
    }

    static getLegalMovesForPiece(
        board: number[],
        fromNode: number,
        player: PlayerId,
        isInMultiCapture: boolean,
        multiCaptureNode: number
    ): any[] {
        if (board[fromNode] !== player) return [];

        if (isInMultiCapture) {
            if (fromNode !== multiCaptureNode) return [];
            return this.getCapturesForPiece(board, fromNode, player);
        }

        const captures = this.getCapturesForPiece(board, fromNode, player);
        const simple = this.getSimpleMovesForPiece(board, fromNode, player);
        return [...captures, ...simple];
    }

    static getAllLegalMoves(
        board: number[],
        player: PlayerId,
        isInMultiCapture: boolean,
        multiCaptureNode: number
    ): any[] {
        if (isInMultiCapture) {
            return this.getCapturesForPiece(board, multiCaptureNode, player);
        }

        const allMoves: any[] = [];
        for (let i = 0; i < TOTAL_NODES; i++) {
            if (board[i] === player) {
                const moves = this.getLegalMovesForPiece(board, i, player, false, -1);
                allMoves.push(...moves);
            }
        }
        return allMoves;
    }

    static validateMove(
        board: number[],
        from: number,
        to: number,
        isCapture: boolean,
        captured: number,
        activePlayer: PlayerId,
        isInMultiCapture: boolean,
        multiCaptureNode: number
    ): { valid: boolean; reason?: string } {
        if (from < 0 || from >= TOTAL_NODES || to < 0 || to >= TOTAL_NODES) {
            return { valid: false, reason: "Out of bounds node index" };
        }

        if (board[from] !== activePlayer) {
            return { valid: false, reason: "Piece does not belong to active player" };
        }

        if (board[to] !== PlayerId.NONE) {
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

    static applyMove(
        board: number[],
        from: number,
        to: number,
        isCapture: boolean,
        captured: number,
        activePlayer: PlayerId
    ): {
        board: number[];
        turnEnded: boolean;
        multiCaptureAvailable: boolean;
        multiCaptureNode: number;
    } {
        const nextBoard = [...board];
        nextBoard[from] = PlayerId.NONE;
        nextBoard[to] = activePlayer;

        let multiCaptureAvailable = false;
        let multiCaptureNode = -1;
        let turnEnded = true;

        if (isCapture && captured >= 0) {
            nextBoard[captured] = PlayerId.NONE;
            // Check if further jump is possible from landing node
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

    static checkGameOver(
        board: number[],
        p1Pieces: number,
        p2Pieces: number,
        nextActivePlayer: PlayerId,
        isInMultiCapture: boolean,
        multiCaptureNode: number
    ): { isGameOver: boolean; winner: PlayerId; reason: EndReason | "" } {
        if (p1Pieces <= 0) {
            return { isGameOver: true, winner: PlayerId.PLAYER_2, reason: EndReason.NORMAL_WIN };
        }
        if (p2Pieces <= 0) {
            return { isGameOver: true, winner: PlayerId.PLAYER_1, reason: EndReason.NORMAL_WIN };
        }

        const legalMoves = this.getAllLegalMoves(board, nextActivePlayer, isInMultiCapture, multiCaptureNode);
        if (legalMoves.length === 0) {
            // Stalemate: Opponent wins
            const winner = this.getOpponent(nextActivePlayer);
            return { isGameOver: true, winner, reason: EndReason.NO_MOVES };
        }

        return { isGameOver: false, winner: PlayerId.NONE, reason: "" };
    }
}
