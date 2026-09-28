// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE CLOUD PROFILE, STATS & MATCH HISTORY
// ==============================================================================

import { ServerWallet } from "./wallet";
import { InventoryShopManager } from "./inventory_shop";

export class ProfileStatsManager {
    static getFullProfile(nk: any, userId: string): any {
        try {
            // Profile & Level/XP
            let profile: any = {
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

            // Wallet
            const coins = ServerWallet.getBalance(nk, userId);

            // Equipped items
            const equipped = InventoryShopManager.getEquippedItems(nk, userId);

            // Inventory
            const inventory = InventoryShopManager.getUserInventory(nk, userId);

            // Stats
            let stats = {
                matches_played: 0,
                wins: 0,
                losses: 0,
                draws: 0,
                captures: 0,
                win_streak: 0,
                best_streak: 0,
                total_play_time: 0.0
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
        } catch (err: any) {
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

    static updateProfile(
        nk: any,
        userId: string,
        displayName?: string,
        avatarId?: number,
        settings?: any
    ): { success: boolean; error?: string } {
        try {
            // Sanitize display name (length 2-24, alphanumeric + spaces)
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
        } catch (e: any) {
            return { success: false, error: e.message || "Failed to update profile" };
        }
    }

    static getMatchHistory(nk: any, userId: string, limit: number = 10, offset: number = 0): any[] {
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

    static getAchievements(nk: any, userId: string): any[] {
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
}
