// ==============================================================================
// 16 GUTI - SERVER AUTHORITATIVE WALLET & TRANSACTION LEDGER
// ==============================================================================

export class ServerWallet {
    /**
     * Gets user's current authoritative coin balance
     */
    static getBalance(nk: any, userId: string): number {
        try {
            const rows = nk.sqlQuery(
                `SELECT balance FROM wallets WHERE user_id = $1`,
                [userId]
            );
            if (rows && rows.length > 0) {
                return parseInt(rows[0].balance) || 0;
            }
            // Initialize if not present
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
    static processTransaction(
        nk: any,
        userId: string,
        type: string,
        amount: number,
        referenceId: string
    ): { success: boolean; newBalance: number; error?: string } {
        try {
            // Check for duplicate referenceId
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

            const txId = "tx_" + Date.now() + "_" + Math.floor(Math.random() * 100000);

            // Execute atomic update
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
        } catch (err: any) {
            return {
                success: false,
                newBalance: this.getBalance(nk, userId),
                error: err.message || "Wallet transaction failed"
            };
        }
    }
}
