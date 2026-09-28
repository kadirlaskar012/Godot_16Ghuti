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
		"capture_effect_theme": capture_effect_theme
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
