// ==============================================================================
// 16 GUTI - NAKAMA SERVER RUNTIME MAIN ENTRYPOINT
// Registers RPCs, Match Handlers, and Authentication Hooks
// ==============================================================================

import { matchHandler } from "./match_handler";
import { ServerWallet } from "./wallet";
import { InventoryShopManager } from "./inventory_shop";
import { RewardsManager } from "./rewards";
import { ProfileStatsManager } from "./profile_stats";
import { SecurityManager } from "./security";
import { MatchmakingService } from "./matchmaking";

function InitModule(ctx: any, logger: any, nk: any, initializer: any) {
    logger.info("==================================================");
    logger.info("   16 GUTI - AUTHORITATIVE SERVER INITIALIZED    ");
    logger.info("==================================================");

    // 1. Register Authoritative Match Handler
    initializer.registerMatch("match_16guti", matchHandler);

    // 2. RPC: Server Ping & Authoritative Time
    initializer.registerRpc("rpc_ping", (ctx: any, logger: any, nk: any, payload: string) => {
        return JSON.stringify({
            server_time_ms: Date.now(),
            client_echo: payload || ""
        });
    });

    // 3. RPC: Client Version Check
    initializer.registerRpc("rpc_check_version", (ctx: any, logger: any, nk: any, payload: string) => {
        let clientVer = "1.0.0";
        try {
            const data = JSON.parse(payload);
            clientVer = data.client_version || "1.0.0";
        } catch (e) {}

        const allowed = SecurityManager.isClientVersionAllowed(clientVer, "1.0.0");
        return JSON.stringify({
            allowed,
            min_supported_version: "1.0.0",
            current_server_version: "1.0.0",
            message: allowed ? "OK" : "Please update the game to continue."
        });
    });

    // 4. RPC: Cloud Profile & Save
    initializer.registerRpc("rpc_get_profile", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const profile = ProfileStatsManager.getFullProfile(nk, userId);
        return JSON.stringify(profile);
    });

    initializer.registerRpc("rpc_update_profile", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let data: any = {};
        try { data = JSON.parse(payload); } catch (e) {}
        const result = ProfileStatsManager.updateProfile(nk, userId, data.display_name, data.avatar_id, data.settings);
        return JSON.stringify(result);
    });

    // 5. RPC: Authoritative Wallet
    initializer.registerRpc("rpc_get_wallet", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const balance = ServerWallet.getBalance(nk, userId);
        return JSON.stringify({ balance });
    });

    // 6. RPC: Shop & Inventory
    initializer.registerRpc("rpc_get_shop", (ctx: any, logger: any, nk: any, payload: string) => {
        const items = InventoryShopManager.getShopCatalog(nk);
        return JSON.stringify({ items });
    });

    initializer.registerRpc("rpc_get_inventory", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const inventory = InventoryShopManager.getUserInventory(nk, userId);
        const equipped = InventoryShopManager.getEquippedItems(nk, userId);
        return JSON.stringify({ inventory, equipped });
    });

    initializer.registerRpc("rpc_purchase_item", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let data: any = {};
        try { data = JSON.parse(payload); } catch (e) {}
        const result = InventoryShopManager.purchaseItem(nk, userId, data.item_id);
        return JSON.stringify(result);
    });

    initializer.registerRpc("rpc_equip_item", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let data: any = {};
        try { data = JSON.parse(payload); } catch (e) {}
        const result = InventoryShopManager.equipItem(nk, userId, data.category, data.item_name);
        return JSON.stringify(result);
    });

    // 7. RPC: Rewards (Daily Reward & Rewarded Ads)
    initializer.registerRpc("rpc_get_daily_reward_status", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const status = RewardsManager.getDailyRewardStatus(nk, userId);
        return JSON.stringify(status);
    });

    initializer.registerRpc("rpc_claim_daily_reward", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const result = RewardsManager.claimDailyReward(nk, userId);
        return JSON.stringify(result);
    });

    initializer.registerRpc("rpc_claim_ad_reward", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let data: any = {};
        try { data = JSON.parse(payload); } catch (e) {}
        const result = RewardsManager.claimAdReward(nk, userId, data.reference_id || `ad_${Date.now()}`);
        return JSON.stringify(result);
    });

    // 8. RPC: Match History & Achievements
    initializer.registerRpc("rpc_get_match_history", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let limit = 10;
        let offset = 0;
        try {
            const data = JSON.parse(payload);
            limit = data.limit || 10;
            offset = data.offset || 0;
        } catch (e) {}
        const history = ProfileStatsManager.getMatchHistory(nk, userId, limit, offset);
        return JSON.stringify({ matches: history });
    });

    initializer.registerRpc("rpc_get_achievements", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const achievements = ProfileStatsManager.getAchievements(nk, userId);
        return JSON.stringify({ achievements });
    });

    // 9. RPC: Matchmaking & Private Rooms
    initializer.registerRpc("rpc_find_match", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const result = MatchmakingService.findOrCreate1v1Match(nk, userId);
        return JSON.stringify(result);
    });

    initializer.registerRpc("rpc_create_room", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        const result = MatchmakingService.createPrivateRoom(nk, userId);
        return JSON.stringify(result);
    });

    initializer.registerRpc("rpc_join_room", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let data: any = {};
        try { data = JSON.parse(payload); } catch (e) {}
        const result = MatchmakingService.joinPrivateRoom(nk, userId, data.room_code || "");
        return JSON.stringify(result);
    });

    // 10. RPC: Google Play Billing verification foundation
    initializer.registerRpc("rpc_verify_purchase", (ctx: any, logger: any, nk: any, payload: string) => {
        const userId = ctx.userId;
        let data: any = {};
        try { data = JSON.parse(payload); } catch (e) {}

        if (!data.order_id || !data.purchase_token || !data.product_id) {
            return JSON.stringify({ success: false, error: "Missing purchase verification parameters" });
        }

        try {
            // Check duplicate order_id
            const existing = nk.sqlQuery(`SELECT purchase_id FROM purchase_records WHERE order_id = $1`, [data.order_id]);
            if (existing && existing.length > 0) {
                return JSON.stringify({ success: false, error: "Purchase token already redeemed" });
            }

            // In production: Validate with Google Play Developer API OAuth2 endpoint
            // For now, record legitimate transaction and award coins
            const purchaseId = "gp_" + Date.now();
            nk.sqlExec(
                `INSERT INTO purchase_records (purchase_id, user_id, order_id, product_id, purchase_token, verified)
                 VALUES ($1, $2, $3, $4, $5, true)`,
                [purchaseId, userId, data.order_id, data.product_id, data.purchase_token]
            );

            // Grant product based on product_id
            let coinsToGrant = 1000;
            if (data.product_id === "coins_5000") coinsToGrant = 5000;
            if (data.product_id === "coins_12000") coinsToGrant = 12000;

            const tx = ServerWallet.processTransaction(nk, userId, "PURCHASE", coinsToGrant, `gp_order_${data.order_id}`);

            return JSON.stringify({
                success: true,
                new_balance: tx.newBalance,
                coins_granted: coinsToGrant
            });
        } catch (err: any) {
            return JSON.stringify({ success: false, error: err.message || "Purchase validation failed" });
        }
    });

    logger.info("All 16 Guti Server RPCs & Match Handlers registered successfully.");
}

// Global hook for Nakama Goja engine
(globalThis as any).InitModule = InitModule;
