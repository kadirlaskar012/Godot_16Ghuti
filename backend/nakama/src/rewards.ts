// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE REWARDS (DAILY & AD REWARDS)
// Immune to client device time modifications & duplicate claims
// ==============================================================================

import { ServerWallet } from "./wallet";

const DAILY_REWARDS_TABLE = [
    50,   // Day 1
    100,  // Day 2
    150,  // Day 3
    250,  // Day 4
    350,  // Day 5
    500,  // Day 6
    1000  // Day 7
];

export class RewardsManager {
    static getDailyRewardStatus(nk: any, userId: string): any {
        try {
            const rows = nk.sqlQuery(
                `SELECT streak_day, last_claimed_at, next_claim_available_at FROM daily_rewards WHERE user_id = $1`,
                [userId]
            );

            const now = new Date();
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

            const diffHours = (now.getTime() - lastClaim.getTime()) / (1000 * 60 * 60);

            // Can claim if at least 20 hours have elapsed since last claim
            const canClaim = diffHours >= 20.0;
            // Streak broken if over 48 hours have elapsed
            const effectiveStreak = diffHours > 48.0 ? 0 : streak;
            const nextDayIndex = effectiveStreak % 7;

            return {
                streak: effectiveStreak,
                canClaim,
                nextReward: DAILY_REWARDS_TABLE[nextDayIndex],
                rewardsTable: DAILY_REWARDS_TABLE,
                hoursUntilNextClaim: canClaim ? 0 : Math.max(0, 20.0 - diffHours)
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

    static claimDailyReward(nk: any, userId: string): { success: boolean; newBalance?: number; streak?: number; coinsAwarded?: number; error?: string } {
        const status = this.getDailyRewardStatus(nk, userId);
        if (!status.canClaim) {
            return { success: false, error: "Daily reward is not ready yet. Please wait." };
        }

        const nextStreak = (status.streak % 7) + 1;
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
        } catch (err: any) {
            // DB error
        }

        return {
            success: true,
            newBalance: tx.newBalance,
            streak: nextStreak,
            coinsAwarded: rewardCoins
        };
    }

    static claimAdReward(
        nk: any,
        userId: string,
        referenceId: string
    ): { success: boolean; newBalance?: number; coinsAwarded?: number; remainingToday?: number; error?: string } {
        try {
            // Check daily limit (max 5)
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

            // Check duplicate reference
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

            const rewardId = "ad_" + Date.now() + "_" + Math.floor(Math.random() * 10000);
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
        } catch (err: any) {
            return { success: false, error: err.message || "Failed to grant ad reward" };
        }
    }
}
