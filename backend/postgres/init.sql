-- ==============================================================================
-- 16 GUTI (SHOLO GUTI) - AUTHORITATIVE POSTGRESQL SCHEMA
-- Provider-independent schema for Docker local dev & AWS Mumbai RDS
-- ==============================================================================

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS profiles (
    user_id VARCHAR(128) PRIMARY KEY,
    display_name VARCHAR(64) NOT NULL DEFAULT 'Guti Player',
    avatar_id INT NOT NULL DEFAULT 0,
    level INT NOT NULL DEFAULT 1,
    xp INT NOT NULL DEFAULT 0,
    settings JSONB NOT NULL DEFAULT '{"sfx": true, "bgm": true, "haptics": true}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_profiles_updated ON profiles(updated_at);

-- 2. WALLETS (Server authoritative balance)
CREATE TABLE IF NOT EXISTS wallets (
    user_id VARCHAR(128) PRIMARY KEY,
    balance BIGINT NOT NULL DEFAULT 500 CHECK (balance >= 0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. COIN TRANSACTIONS (Authoritative Ledger)
CREATE TABLE IF NOT EXISTS coin_transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    type VARCHAR(32) NOT NULL, -- MATCH_REWARD, WIN_REWARD, DAILY_REWARD, ACHIEVEMENT_REWARD, AD_REWARD, PURCHASE, ADMIN_ADJUSTMENT
    amount INT NOT NULL,
    reference_id VARCHAR(128) UNIQUE, -- Idempotency protection against duplicate requests
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_coin_tx_user ON coin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_coin_tx_created ON coin_transactions(created_at);

-- 4. INVENTORY
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    item_id VARCHAR(64) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, item_id)
);
CREATE INDEX IF NOT EXISTS idx_inventory_user ON inventory(user_id);

-- 5. SHOP ITEMS (Authoritative Catalog)
CREATE TABLE IF NOT EXISTS shop_items (
    item_id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    category VARCHAR(32) NOT NULL, -- GUTI_SKIN, BOARD_THEME, VICTORY_EFFECT, AVATAR
    price_coins INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. EQUIPPED ITEMS
CREATE TABLE IF NOT EXISTS equipped_items (
    user_id VARCHAR(128) PRIMARY KEY,
    guti_skin VARCHAR(64) NOT NULL DEFAULT 'Classic Red',
    board_theme VARCHAR(64) NOT NULL DEFAULT 'Classic Wood',
    victory_effect VARCHAR(64) NOT NULL DEFAULT 'Classic Sparkle',
    avatar VARCHAR(64) NOT NULL DEFAULT 'Warrior',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. MATCHES
CREATE TABLE IF NOT EXISTS matches (
    match_id VARCHAR(64) PRIMARY KEY,
    player_1 VARCHAR(128) NOT NULL,
    player_2 VARCHAR(128) NOT NULL,
    mode VARCHAR(32) NOT NULL DEFAULT '1v1_ONLINE',
    status VARCHAR(32) NOT NULL DEFAULT 'COMPLETED', -- WAITING, READY, PLAYING, TIME_UP, COMPLETED, CANCELLED, ABANDONED
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INT NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_matches_p1 ON matches(player_1);
CREATE INDEX IF NOT EXISTS idx_matches_p2 ON matches(player_2);

-- 8. MATCH PLAYERS
CREATE TABLE IF NOT EXISTS match_players (
    match_id VARCHAR(64) NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL,
    player_index INT NOT NULL, -- 1 or 2
    captures INT NOT NULL DEFAULT 0,
    remaining_pieces INT NOT NULL DEFAULT 16,
    score INT NOT NULL DEFAULT 0,
    PRIMARY KEY(match_id, user_id)
);

-- 9. MATCH MOVES (Audit trail & replay/anti-cheat validation)
CREATE TABLE IF NOT EXISTS match_moves (
    move_id SERIAL PRIMARY KEY,
    match_id VARCHAR(64) NOT NULL,
    turn_number INT NOT NULL,
    player_id VARCHAR(128) NOT NULL,
    from_node INT NOT NULL,
    to_node INT NOT NULL,
    is_capture BOOLEAN NOT NULL DEFAULT false,
    captured_node INT DEFAULT -1,
    client_seq INT NOT NULL DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_match_moves_match ON match_moves(match_id);

-- 10. MATCH RESULTS
CREATE TABLE IF NOT EXISTS match_results (
    match_id VARCHAR(64) PRIMARY KEY REFERENCES matches(match_id) ON DELETE CASCADE,
    winner_id VARCHAR(128),
    loser_id VARCHAR(128),
    end_reason VARCHAR(64) NOT NULL, -- NORMAL_WIN, NO_MOVES, TIME_UP, OPPONENT_DISCONNECTED, FORFEIT
    summary JSONB DEFAULT '{}'::jsonb
);

-- 11. PLAYER STATISTICS
CREATE TABLE IF NOT EXISTS player_statistics (
    user_id VARCHAR(128) PRIMARY KEY,
    matches_played INT NOT NULL DEFAULT 0,
    wins INT NOT NULL DEFAULT 0,
    losses INT NOT NULL DEFAULT 0,
    draws INT NOT NULL DEFAULT 0,
    captures INT NOT NULL DEFAULT 0,
    win_streak INT NOT NULL DEFAULT 0,
    best_streak INT NOT NULL DEFAULT 0,
    total_play_time FLOAT NOT NULL DEFAULT 0.0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 12. ACHIEVEMENTS
CREATE TABLE IF NOT EXISTS achievements (
    achievement_id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(32) NOT NULL DEFAULT 'PROGRESSION',
    target_value INT NOT NULL DEFAULT 1,
    reward_coins INT NOT NULL DEFAULT 100,
    reward_xp INT NOT NULL DEFAULT 50
);

-- 13. PLAYER ACHIEVEMENTS
CREATE TABLE IF NOT EXISTS player_achievements (
    user_id VARCHAR(128) NOT NULL,
    achievement_id VARCHAR(64) NOT NULL REFERENCES achievements(achievement_id) ON DELETE CASCADE,
    current_value INT NOT NULL DEFAULT 0,
    is_unlocked BOOLEAN NOT NULL DEFAULT false,
    unlocked_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY(user_id, achievement_id)
);

-- 14. DAILY REWARDS
CREATE TABLE IF NOT EXISTS daily_rewards (
    user_id VARCHAR(128) PRIMARY KEY,
    streak_day INT NOT NULL DEFAULT 0,
    last_claimed_at TIMESTAMP WITH TIME ZONE,
    next_claim_available_at TIMESTAMP WITH TIME ZONE
);

-- 15. AD REWARDS
CREATE TABLE IF NOT EXISTS ad_rewards (
    reward_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    reference_id VARCHAR(128) UNIQUE NOT NULL,
    reward_type VARCHAR(32) NOT NULL DEFAULT 'COINS',
    coins_granted INT NOT NULL DEFAULT 50,
    claimed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_ad_rewards_user_date ON ad_rewards(user_id, claimed_date);

-- 16. PURCHASE RECORDS (Google Play Billing verification ledger)
CREATE TABLE IF NOT EXISTS purchase_records (
    purchase_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    order_id VARCHAR(128) UNIQUE NOT NULL,
    product_id VARCHAR(64) NOT NULL,
    purchase_token TEXT NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 17. SECURITY EVENTS (Anti-cheat logging)
CREATE TABLE IF NOT EXISTS security_events (
    event_id SERIAL PRIMARY KEY,
    user_id VARCHAR(128),
    event_type VARCHAR(64) NOT NULL, -- invalid_move, rate_limit, duplicate_transaction, invalid_reward, old_client_version, reconnect_abuse
    metadata JSONB DEFAULT '{}'::jsonb,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_security_user ON security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_type ON security_events(event_type);

-- 18. PLAYER RESTRICTIONS
CREATE TABLE IF NOT EXISTS player_restrictions (
    restriction_id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    restriction_type VARCHAR(32) NOT NULL, -- WARNING, TEMP_RESTRICTION, BAN
    reason TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_player_restrictions_user ON player_restrictions(user_id);

-- 19. GAME SETTINGS (Centralized Server Configuration)
CREATE TABLE IF NOT EXISTS game_settings (
    setting_key VARCHAR(64) PRIMARY KEY,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- SEED DEFAULT DATA
-- ==============================================================================

-- Seed Game Settings
INSERT INTO game_settings (setting_key, setting_value, description) VALUES
('match_duration', '300', 'Authoritative match duration in seconds (5 minutes)'),
('rewarded_ads_per_day', '5', 'Max allowed rewarded ad claims per day per user'),
('win_reward_coins', '100', 'Coin reward for winning a match'),
('win_reward_xp', '150', 'XP reward for winning a match'),
('loss_reward_coins', '20', 'Coin reward for finishing a loss'),
('loss_reward_xp', '50', 'XP reward for finishing a loss'),
('minimum_client_version', '1.0.0', 'Minimum supported Godot client version')
ON CONFLICT (setting_key) DO NOTHING;

-- Seed Shop Items
INSERT INTO shop_items (item_id, name, category, price_coins, is_active, metadata) VALUES
('classic_red', 'Classic Red', 'GUTI_SKIN', 0, true, '{"description": "Traditional glossy red lacquer"}'::jsonb),
('ruby_guti', 'Ruby Radiance', 'GUTI_SKIN', 500, true, '{"description": "Polished crimson gemstone with gold trim"}'::jsonb),
('gold_guti', 'Royal Gold', 'GUTI_SKIN', 1200, true, '{"description": "Solid brass gilded with pure 24k luster"}'::jsonb),
('emerald_guti', 'Imperial Emerald', 'GUTI_SKIN', 2000, true, '{"description": "Rare deep emerald green gem finish"}'::jsonb),
('diamond_guti', 'Celestial Diamond', 'GUTI_SKIN', 3500, true, '{"description": "Crystalline diamond prism reflect"}'::jsonb),

('classic_wood', 'Classic Walnut', 'BOARD_THEME', 0, true, '{"description": "Warm aged walnut tabletop"}'::jsonb),
('royal_mahogany', 'Royal Mahogany', 'BOARD_THEME', 600, true, '{"description": "Deep lustrous mahogany with brass inlays"}'::jsonb),
('ivory_maple', 'Ivory Maple', 'BOARD_THEME', 1200, true, '{"description": "Clean light maple grain with gold etchings"}'::jsonb),

('classic_sparkle', 'Golden Sparkle', 'VICTORY_EFFECT', 0, true, '{"description": "Warm golden sparkles on victory"}'::jsonb),
('fireworks', 'Royal Fireworks', 'VICTORY_EFFECT', 800, true, '{"description": "Vibrant festive fireworks display"}'::jsonb),

('warrior_avatar', 'Warrior', 'AVATAR', 0, true, '{"index": 0}'::jsonb),
('king_avatar', 'King', 'AVATAR', 300, true, '{"index": 1}'::jsonb),
('queen_avatar', 'Queen', 'AVATAR', 300, true, '{"index": 2}'::jsonb),
('samurai_avatar', 'Samurai', 'AVATAR', 700, true, '{"index": 3}'::jsonb),
('knight_avatar', 'Knight', 'AVATAR', 700, true, '{"index": 4}'::jsonb),
('prince_avatar', 'Royal Prince', 'AVATAR', 1000, true, '{"index": 5}'::jsonb),
('princess_avatar', 'Royal Princess', 'AVATAR', 1000, true, '{"index": 6}'::jsonb),
('mystic_avatar', 'Mystic Player', 'AVATAR', 1500, true, '{"index": 7}'::jsonb)
ON CONFLICT (item_id) DO NOTHING;

-- Seed Achievements
INSERT INTO achievements (achievement_id, title, description, category, target_value, reward_coins, reward_xp) VALUES
('first_win', 'First Victory', 'Win your first 16 Guti match', 'PROGRESSION', 1, 100, 50),
('wins_10', 'Apprentice Tactician', 'Win 10 matches', 'PROGRESSION', 10, 300, 150),
('wins_50', 'Master of the Board', 'Win 50 matches', 'PROGRESSION', 50, 1000, 500),
('wins_100', 'Grandmaster of 16 Guti', 'Win 100 matches', 'PROGRESSION', 100, 2500, 1000),
('captures_10', 'Sharp Claws', 'Capture 10 opponent pieces in online matches', 'COMBAT', 10, 100, 50),
('captures_100', 'Voracious Predator', 'Capture 100 opponent pieces in online matches', 'COMBAT', 100, 500, 250),
('streak_3', 'On Fire', 'Achieve a 3-match win streak', 'STREAK', 3, 200, 100),
('streak_5', 'Unstoppable', 'Achieve a 5-match win streak', 'STREAK', 5, 500, 250),
('play_10', 'Dedicated Player', 'Play 10 matches to completion', 'PARTICIPATION', 10, 150, 75)
ON CONFLICT (achievement_id) DO NOTHING;
