class_name SettingsModal
extends CanvasLayer

signal closed

const LocalizationManager = preload("res://scripts/utils/LocalizationManager.gd")

@onready var cross_btn: Button = find_child("CrossButton", true, false)
@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var dim_overlay: ColorRect = find_child("DimOverlay", true, false)

# Gameplay
@onready var diff_opt: OptionButton = find_child("DiffOption", true, false)
@onready var timer_opt: OptionButton = find_child("TimerOption", true, false)
@onready var capture_btn: Button = find_child("CaptureToggleBtn", true, false)
@onready var haptics_btn: Button = find_child("HapticsToggleBtn", true, false)

# Audio
@onready var sound_btn: Button = find_child("SoundToggleBtn", true, false)
@onready var music_btn: Button = find_child("MusicToggleBtn", true, false)

# Voice & Chat (Online)
@onready var voice_chat_btn: Button = find_child("VoiceChatToggleBtn", true, false)
@onready var mic_mute_btn: Button = find_child("MicMuteToggleBtn", true, false)
@onready var speaker_mute_btn: Button = find_child("SpeakerMuteToggleBtn", true, false)
@onready var opp_voice_mute_btn: Button = find_child("OppVoiceMuteToggleBtn", true, false)
@onready var opp_chat_mute_btn: Button = find_child("OppChatMuteToggleBtn", true, false)
@onready var quick_chat_btn: Button = find_child("QuickChatToggleBtn", true, false)
@onready var emoji_btn: Button = find_child("EmojiToggleBtn", true, false)

# Language
@onready var lang_opt: OptionButton = find_child("LangOption", true, false)

# Cached initial values for Cancel
var _orig: Dictionary = {}

func _ready() -> void:
	var s = SaveManager.settings
	_orig = {
		"sound": s.sound_enabled,
		"music": s.music_enabled,
		"haptics": s.haptics_enabled,
		"capture": s.forced_capture,
		"timer": s.match_timer_minutes,
		"diff": s.ai_difficulty,
		"voice_chat": s.voice_chat_enabled,
		"mic_muted": s.mic_muted,
		"speaker_muted": s.speaker_muted,
		"opp_voice_muted": s.opponent_voice_muted,
		"opp_chat_muted": s.opponent_chat_muted,
		"quick_chat": s.quick_chat_enabled,
		"emoji": s.emoji_enabled,
		"lang": s.language
	}
	
	# Gameplay Toggles
	_setup_toggle_button(capture_btn, s.forced_capture, func(v): s.forced_capture = v)
	_setup_toggle_button(haptics_btn, s.haptics_enabled, func(v): s.haptics_enabled = v)
	
	# Audio Toggles
	_setup_toggle_button(sound_btn, s.sound_enabled, func(v):
		s.sound_enabled = v
		AudioManager.update_audio_settings()
	)
	_setup_toggle_button(music_btn, s.music_enabled, func(v):
		s.music_enabled = v
		AudioManager.update_audio_settings()
	)
	
	# Voice & Chat Toggles
	_setup_toggle_button(voice_chat_btn, s.voice_chat_enabled, func(v):
		s.voice_chat_enabled = v
	)
	_setup_toggle_button(mic_mute_btn, s.mic_muted, func(v):
		s.mic_muted = v
		AudioManager.sync_all_bus_settings()
	)
	_setup_toggle_button(speaker_mute_btn, s.speaker_muted, func(v):
		s.speaker_muted = v
		AudioManager.sync_all_bus_settings()
	)
	_setup_toggle_button(opp_voice_mute_btn, s.opponent_voice_muted, func(v):
		s.opponent_voice_muted = v
		AudioManager.sync_all_bus_settings()
	)
	_setup_toggle_button(opp_chat_mute_btn, s.opponent_chat_muted, func(v):
		s.opponent_chat_muted = v
	)
	_setup_toggle_button(quick_chat_btn, s.quick_chat_enabled, func(v):
		s.quick_chat_enabled = v
	)
	_setup_toggle_button(emoji_btn, s.emoji_enabled, func(v):
		s.emoji_enabled = v
	)
	
	# OptionButtons
	_setup_diff_options(s)
	_setup_timer_options(s)
	_setup_lang_options(s)
	
	if cross_btn:
		cross_btn.pressed.connect(_on_cancel_pressed)
		_setup_btn(cross_btn)
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		_setup_btn(close_btn)
	if dim_overlay:
		dim_overlay.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				_on_cancel_pressed()
		)

func _setup_diff_options(s: GameSettings) -> void:
	if not diff_opt: return
	diff_opt.clear()
	diff_opt.add_item("🤖 AI Difficulty: Easy", AIManager.Difficulty.EASY)
	diff_opt.add_item("🤖 AI Difficulty: Medium (Balanced)", AIManager.Difficulty.MEDIUM)
	diff_opt.add_item("🤖 AI Difficulty: Hard (Expert)", AIManager.Difficulty.HARD)
	diff_opt.selected = s.ai_difficulty
	diff_opt.item_selected.connect(func(idx):
		s.ai_difficulty = diff_opt.get_item_id(idx)
		GameManager.current_difficulty = s.ai_difficulty
		AudioManager.play_sfx("click")
	)
	_style_option_popup(diff_opt)

func _setup_timer_options(s: GameSettings) -> void:
	if not timer_opt: return
	timer_opt.clear()
	timer_opt.add_item("⏱️ Match Timer: OFF", 0)
	timer_opt.add_item("⏱️ Match Timer: 3 Minutes", 3)
	timer_opt.add_item("⏱️ Match Timer: 5 Minutes (Default)", 5)
	timer_opt.add_item("⏱️ Match Timer: 10 Minutes", 10)
	for i in range(timer_opt.item_count):
		if timer_opt.get_item_id(i) == s.match_timer_minutes:
			timer_opt.selected = i
			break
	timer_opt.item_selected.connect(func(idx):
		s.match_timer_minutes = timer_opt.get_item_id(idx)
		AudioManager.play_sfx("click")
	)
	_style_option_popup(timer_opt)

func _setup_lang_options(s: GameSettings) -> void:
	if not lang_opt: return
	lang_opt.clear()
	lang_opt.add_item("🌐 English (United States)", 0)
	lang_opt.add_item("🌐 বাংলা (Bengali)", 1)
	lang_opt.selected = 1 if s.language == "bn" else 0
	lang_opt.item_selected.connect(func(idx):
		var code = "bn" if idx == 1 else "en"
		s.language = code
		LocalizationManager.set_language(code)
		AudioManager.play_sfx("click")
	)
	_style_option_popup(lang_opt)

func _setup_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _setup_toggle_button(btn: Button, initial_val: bool, on_changed: Callable) -> void:
	if not btn: return
	btn.set_meta("is_on", initial_val)
	_update_toggle_visual(btn, initial_val)
	btn.pressed.connect(func():
		var current_val = bool(btn.get_meta("is_on", false))
		var new_val = not current_val
		btn.set_meta("is_on", new_val)
		_update_toggle_visual(btn, new_val)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
		on_changed.call(new_val)
	)

func _update_toggle_visual(btn: Button, is_on: bool) -> void:
	btn.text = "ON  ●" if is_on else "○  OFF"
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(16)
	if is_on:
		sb.bg_color = Color(0.18, 0.65, 0.28, 0.95)
		sb.border_color = Color(0.55, 1.0, 0.65, 1.0)
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		sb.bg_color = Color(0.20, 0.14, 0.10, 0.85)
		sb.border_color = Color(0.5, 0.4, 0.3, 0.6)
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6, 0.85))
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("click")
	var s = SaveManager.settings
	s.sound_enabled = _orig.get("sound", true)
	s.music_enabled = _orig.get("music", true)
	s.haptics_enabled = _orig.get("haptics", true)
	s.forced_capture = _orig.get("capture", false)
	s.match_timer_minutes = _orig.get("timer", 5)
	s.ai_difficulty = _orig.get("diff", AIManager.Difficulty.MEDIUM)
	s.voice_chat_enabled = _orig.get("voice_chat", false)
	s.mic_muted = _orig.get("mic_muted", true)
	s.speaker_muted = _orig.get("speaker_muted", false)
	s.opponent_voice_muted = _orig.get("opp_voice_muted", false)
	s.opponent_chat_muted = _orig.get("opp_chat_muted", false)
	s.quick_chat_enabled = _orig.get("quick_chat", true)
	s.emoji_enabled = _orig.get("emoji", true)
	s.language = _orig.get("lang", "en")
	GameManager.current_difficulty = s.ai_difficulty
	LocalizationManager.set_language(s.language)
	AudioManager.update_audio_settings()
	closed.emit()
	queue_free()

func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.save_data()
	closed.emit()
	queue_free()

func _style_option_popup(opt: OptionButton) -> void:
	if not opt: return
	var popup: PopupMenu = opt.get_popup()
	if not popup: return
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	popup.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.45, 1.0))
	popup.add_theme_constant_override("v_separation", 16)
	popup.add_theme_constant_override("item_start_padding", 24)
	popup.add_theme_constant_override("item_end_padding", 20)
	
	var sb_popup = StyleBoxFlat.new()
	sb_popup.bg_color = Color(0.14, 0.08, 0.04, 0.98)
	sb_popup.set_border_width_all(2)
	sb_popup.border_color = Color(0.85, 0.70, 0.35, 0.95)
	sb_popup.set_corner_radius_all(14)
	sb_popup.content_margin_left = 24
	sb_popup.content_margin_right = 24
	sb_popup.content_margin_top = 18
	sb_popup.content_margin_bottom = 18
	sb_popup.shadow_size = 18
	sb_popup.shadow_color = Color(0, 0, 0, 0.6)
	popup.add_theme_stylebox_override("panel", sb_popup)
