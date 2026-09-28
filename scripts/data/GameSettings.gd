class_name GameSettings
extends RefCounted

## Game Settings Model

var sound_enabled: bool = true
var music_enabled: bool = true
var haptics_enabled: bool = true
var match_timer_minutes: int = 5 # 0 = OFF, 3, 5, 10
var ai_difficulty: int = AIManager.Difficulty.MEDIUM
var forced_capture: bool = false
var board_theme: String = "classic_wood"
var piece_theme: String = "glossy_classic"
var capture_effect_theme: String = "classic_gold"

# Audio & Bus Settings
var master_volume: float = 1.0
var game_volume: float = 0.85
var voice_volume: float = 1.0

# Mute & Voice Controls (Sections 14, 17, 18)
var mic_muted: bool = true # Default OFF
var speaker_muted: bool = false
var opponent_voice_muted: bool = false
var opponent_chat_muted: bool = false
var voice_chat_enabled: bool = false

# Interaction & Localization
var quick_chat_enabled: bool = true
var emoji_enabled: bool = true
var language: String = "en"

func to_dict() -> Dictionary:
	return {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"haptics_enabled": haptics_enabled,
		"match_timer_minutes": match_timer_minutes,
		"ai_difficulty": ai_difficulty,
		"forced_capture": forced_capture,
		"board_theme": board_theme,
		"piece_theme": piece_theme,
		"capture_effect_theme": capture_effect_theme,
		"master_volume": master_volume,
		"game_volume": game_volume,
		"voice_volume": voice_volume,
		"mic_muted": mic_muted,
		"speaker_muted": speaker_muted,
		"opponent_voice_muted": opponent_voice_muted,
		"opponent_chat_muted": opponent_chat_muted,
		"voice_chat_enabled": voice_chat_enabled,
		"quick_chat_enabled": quick_chat_enabled,
		"emoji_enabled": emoji_enabled,
		"language": language
	}

func from_dict(d: Dictionary) -> void:
	sound_enabled = d.get("sound_enabled", true)
	music_enabled = d.get("music_enabled", true)
	haptics_enabled = d.get("haptics_enabled", true)
	match_timer_minutes = d.get("match_timer_minutes", 5)
	ai_difficulty = d.get("ai_difficulty", AIManager.Difficulty.MEDIUM)
	forced_capture = d.get("forced_capture", false)
	board_theme = d.get("board_theme", "classic_wood")
	piece_theme = d.get("piece_theme", "glossy_classic")
	capture_effect_theme = d.get("capture_effect_theme", "classic_gold")
	master_volume = float(d.get("master_volume", 1.0))
	game_volume = float(d.get("game_volume", 0.85))
	voice_volume = float(d.get("voice_volume", 1.0))
	mic_muted = bool(d.get("mic_muted", true))
	speaker_muted = bool(d.get("speaker_muted", false))
	opponent_voice_muted = bool(d.get("opponent_voice_muted", false))
	opponent_chat_muted = bool(d.get("opponent_chat_muted", false))
	voice_chat_enabled = bool(d.get("voice_chat_enabled", false))
	quick_chat_enabled = bool(d.get("quick_chat_enabled", true))
	emoji_enabled = bool(d.get("emoji_enabled", true))
	language = str(d.get("language", "en"))
