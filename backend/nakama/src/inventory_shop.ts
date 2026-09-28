// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE SHOP & INVENTORY
// ==============================================================================

import { ServerWallet } from "./wallet";

export class InventoryShopManager {
    static getShopCatalog(nk: any): any[] {
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

    static getUserInventory(nk: any, userId: string): string[] {
        try {
            const rows = nk.sqlQuery(
                `SELECT item_id FROM inventory WHERE user_id = $1`,
                [userId]
            );
            if (!rows) return ["classic_red", "classic_wood", "classic_sparkle", "warrior_avatar"];
            return rows.map((r: any) => r.item_id);
        } catch (e) {
            return ["classic_red", "classic_wood", "classic_sparkle", "warrior_avatar"];
        }
    }

    static getEquippedItems(nk: any, userId: string): any {
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

    static purchaseItem(nk: any, userId: string, itemId: string): { success: boolean; newBalance?: number; error?: string } {
        try {
            // 1. Fetch item
            const itemRows = nk.sqlQuery(
                `SELECT item_id, name, category, price_coins, is_active FROM shop_items WHERE item_id = $1 AND is_active = true`,
                [itemId]
            );
            if (!itemRows || itemRows.length === 0) {
                return { success: false, error: "Item not found or inactive" };
            }
            const item = itemRows[0];
            const price = parseInt(item.price_coins) || 0;

            // 2. Check ownership
            const owned = nk.sqlQuery(
                `SELECT id FROM inventory WHERE user_id = $1 AND item_id = $2`,
                [userId, itemId]
            );
            if (owned && owned.length > 0) {
                return { success: false, error: "Item already owned" };
            }

            // 3. Process payment
            const refId = `shop_buy_${userId}_${itemId}_${Date.now()}`;
            const txResult = ServerWallet.processTransaction(nk, userId, "PURCHASE", -price, refId);
            if (!txResult.success) {
                return { success: false, error: txResult.error };
            }

            // 4. Add to inventory
            nk.sqlExec(
                `INSERT INTO inventory (user_id, item_id, quantity) VALUES ($1, $2, 1)`,
                [userId, itemId]
            );

            return {
                success: true,
                newBalance: txResult.newBalance
            };
        } catch (err: any) {
            return { success: false, error: err.message || "Purchase failed" };
        }
    }

    static equipItem(nk: any, userId: string, category: string, itemName: string): { success: boolean; error?: string } {
        try {
            let col = "";
            switch (category.toUpperCase()) {
                case "GUTI_SKIN": col = "guti_skin"; break;
                case "BOARD_THEME": col = "board_theme"; break;
                case "VICTORY_EFFECT": col = "victory_effect"; break;
                case "AVATAR": col = "avatar"; break;
                default:
                    return { success: false, error: "Invalid cosmetic category" };
            }

            nk.sqlExec(
                `INSERT INTO equipped_items (user_id, ${col}) VALUES ($1, $2)
                 ON CONFLICT (user_id) DO UPDATE SET ${col} = EXCLUDED.${col}, updated_at = NOW()`,
                [userId, itemName]
            );

            return { success: true };
        } catch (err: any) {
            return { success: false, error: err.message || "Equip failed" };
        }
    }
}
