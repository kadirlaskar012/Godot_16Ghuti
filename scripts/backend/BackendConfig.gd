class_name BackendConfig
extends RefCounted

## BackendConfig
## Centralized backend environment settings (Development, Staging, Production).
## Ensures zero hardcoded production credentials in client code and easy migration.

enum ServerEnv {
	DEVELOPMENT,
	STAGING,
	PRODUCTION
}

# Current Active Environment
# Switch to ServerEnv.PRODUCTION when deploying to AWS Mumbai (ap-south-1)
const CURRENT_ENV: int = ServerEnv.DEVELOPMENT

# Client Version (enforces compatibility with Nakama server)
const CLIENT_VERSION: String = "1.0.0"
const MIN_SUPPORTED_VERSION: String = "1.0.0"

# Server-Authoritative Timer Configuration
const MATCH_DURATION: int = 300       # 5 minutes default total match duration
const TURN_NORMAL_TIME: int = 10      # 10 seconds per-turn normal time
const PLAYER_EXTRA_TIME: int = 60     # 60 seconds personal reserve per player

# Environment Definitions
const CONFIGS: Dictionary = {
	ServerEnv.DEVELOPMENT: {
		"host": "127.0.0.1",
		"port": 7350,
		"ssl": false,
		"server_key": "defaultkey",
		"region": "local_docker",
		"timeout": 8.0
	},
	ServerEnv.STAGING: {
		"host": "staging.16guti.games",
		"port": 443,
		"ssl": true,
		"server_key": "staging_secret_key_16guti",
		"region": "ap-south-1",
		"timeout": 10.0
	},
	ServerEnv.PRODUCTION: {
		"host": "api.16guti.games",
		"port": 443,
		"ssl": true,
		"server_key": "prod_secret_key_16guti_mumbai",
		"region": "ap-south-1", # AWS Mumbai
		"timeout": 10.0
	}
}

static func get_active_config() -> Dictionary:
	return CONFIGS.get(CURRENT_ENV, CONFIGS[ServerEnv.DEVELOPMENT])

static func get_http_base_url() -> String:
	var cfg = get_active_config()
	var scheme = "https://" if cfg["ssl"] else "http://"
	var port_str = "" if (cfg["port"] == 80 or cfg["port"] == 443) else ":%d" % cfg["port"]
	return "%s%s%s" % [scheme, cfg["host"], port_str]

static func get_ws_url() -> String:
	var cfg = get_active_config()
	var scheme = "wss://" if cfg["ssl"] else "ws://"
	var port_str = "" if (cfg["port"] == 80 or cfg["port"] == 443) else ":%d" % cfg["port"]
	return "%s%s%s/ws" % [scheme, cfg["host"], port_str]

static func get_server_key() -> String:
	return get_active_config()["server_key"]

static func get_timeout() -> float:
	return float(get_active_config()["timeout"])

static func get_env_name() -> String:
	match CURRENT_ENV:
		ServerEnv.DEVELOPMENT: return "DEVELOPMENT (Local Docker)"
		ServerEnv.STAGING: return "STAGING (AWS ap-south-1)"
		ServerEnv.PRODUCTION: return "PRODUCTION (AWS Mumbai)"
		_: return "UNKNOWN"
