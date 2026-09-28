// ==============================================================================
// 16 GUTI - SERVER SECURITY & ANTI-CHEAT LAYER
// ==============================================================================

interface RateLimitTracker {
    count: number;
    resetTimeMs: number;
}

const rateLimitMap: { [userId: string]: RateLimitTracker } = {};
const suspicionScoreMap: { [userId: string]: number } = {};

export class SecurityManager {
    /**
     * Sliding-window rate limiter
     */
    static checkRateLimit(userId: string, maxRequests: number = 8, windowMs: number = 1000): boolean {
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
    static isClientVersionAllowed(clientVersion: string, minVersion: string = "1.0.0"): boolean {
        if (!clientVersion) return false;
        const parse = (v: string) => v.split('.').map(n => parseInt(n) || 0);
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
    static addSuspicionScore(nk: any, userId: string, points: number, reason: string, meta: any = {}) {
        const current = (suspicionScoreMap[userId] || 0) + points;
        suspicionScoreMap[userId] = current;

        this.recordSecurityEvent(nk, userId, "suspicious_activity", {
            reason,
            pointsAdded: points,
            totalScore: current,
            meta
        });

        if (current >= 100) {
            // Apply temp restriction / warning flag
            try {
                if (nk && nk.sqlExec) {
                    nk.sqlExec(
                        `INSERT INTO player_restrictions (user_id, restriction_type, reason, expires_at)
                         VALUES ($1, 'TEMP_RESTRICTION', $2, NOW() + INTERVAL '24 hours')`,
                        [userId, reason]
                    );
                }
            } catch (err) {
                // Ignore if db unavailable
            }
        }
    }

    /**
     * Persists security audit event to PostgreSQL table
     */
    static recordSecurityEvent(nk: any, userId: string, eventType: string, metadata: any) {
        try {
            if (nk && nk.sqlExec) {
                nk.sqlExec(
                    `INSERT INTO security_events (user_id, event_type, metadata)
                     VALUES ($1, $2, $3)`,
                    [userId, eventType, JSON.stringify(metadata)]
                );
            }
        } catch (e) {
            // In-memory fallback or stdout
        }
    }
}
