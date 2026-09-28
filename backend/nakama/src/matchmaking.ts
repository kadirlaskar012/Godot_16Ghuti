// ==============================================================================
// 16 GUTI - SERVER MATCHMAKING & PRIVATE ROOM FOUNDATION
// ==============================================================================

export class MatchmakingService {
    static findOrCreate1v1Match(nk: any, userId: string): { matchId: string } {
        // Query for available matches with 1 player waiting
        try {
            const matches = nk.matchList(10, true, null, 1, 1, "+label.status:WAITING +label.mode:1v1_ONLINE");
            if (matches && matches.length > 0) {
                return { matchId: matches[0].matchId };
            }
        } catch (e) {
            // Match listing fallback
        }

        // Create new match if none available
        const matchId = nk.matchCreate("match_16guti", {
            mode: "1v1_ONLINE"
        });
        return { matchId };
    }

    static createPrivateRoom(nk: any, userId: string): { matchId: string; roomCode: string } {
        // Generate random 6-character room code (e.g. GT4892)
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

    static joinPrivateRoom(nk: any, userId: string, roomCode: string): { matchId?: string; error?: string } {
        const cleanCode = roomCode.trim().toUpperCase();
        try {
            const matches = nk.matchList(10, true, null, 1, 1, `+label.room_code:${cleanCode}`);
            if (matches && matches.length > 0) {
                return { matchId: matches[0].matchId };
            }
        } catch (e) {
            // Fallback
        }
        return { error: "Room not found or game already in progress." };
    }
}
