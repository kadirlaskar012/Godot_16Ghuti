class_name SettingsModal
extends CanvasLayer

signal closed

@onready var cross_btn: Button = find_child("CrossButton", true, false)
@onready var sound_btn: Button = find_child("SoundToggleBtn", true, false)
@onready var music_btn: Button = find_child("MusicToggleBtn", true, false)
@onready var haptics_btn: Button = find_child("HapticsToggleBtn", true, false)
@onready var capture_btn: Button = find_child("CaptureToggleBtn", true, false)

@onready var timer_opt: OptionButton = find_child("TimerOption", true, false)
@onready var diff_opt: OptionButton = find_child("DiffOption", true, false)

@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var dim_overlay: ColorRect = find_child("DimOverlay", true, false)

# Cached initial values to allow closing without saving
var _orig_sound: bool
var _orig_music: bool
var _orig_haptics: bool
var _orig_capture: bool
var _orig_timer: int
var _orig_diff: int

func _ready() -> void:
	var s = SaveManager.settings
	_orig_sound = s.sound_enabled
	_orig_music = s.music_enabled
	_orig_haptics = s.haptics_enabled
	_orig_capture = s.forced_capture
	_orig_timer = s.match_timer_minutes
	_orig_diff = s.ai_difficulty
	
	_setup_toggle_button(sound_btn, s.sound_enabled, func(v):
		s.sound_enabled = v
		AudioManager.update_audio_settings()
	)
	_setup_toggle_button(music_btn, s.music_enabled, func(v):
		s.music_enabled = v
		AudioManager.update_audio_settings()
	)
	_setup_toggle_button(haptics_btn, s.haptics_enabled, func(v):
		s.haptics_enabled = v
	)
	_setup_toggle_button(capture_btn, s.forced_capture, func(v):
		s.forced_capture = v
	)
	
	# Timer options
	if timer_opt:
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
		
	# Diff options
	if diff_opt:
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
	if not btn:
		return
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
	sb.set_corner_radius_all(18)
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

## Cross button (✕) or tap outside: Cancel without saving changes
func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("click")
	var s = SaveManager.settings
	s.sound_enabled = _orig_sound
	s.music_enabled = _orig_music
	s.haptics_enabled = _orig_haptics
	s.forced_capture = _orig_capture
	s.match_timer_minutes = _orig_timer
	s.ai_difficulty = _orig_diff
	GameManager.current_difficulty = _orig_diff
	AudioManager.update_audio_settings()
	closed.emit()
	queue_free()

## "SAVE & CLOSE" button: Persist changes permanently
func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.save_data()
	closed.emit()
	queue_free()

func _style_option_popup(opt: OptionButton) -> void:
	if not opt:
		return
	var popup: PopupMenu = opt.get_popup()
	if not popup:
		return
	popup.add_theme_font_size_override("font_size", 30)
	popup.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	popup.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.45, 1.0))
	popup.add_theme_constant_override("v_separation", 18)
	popup.add_theme_constant_override("item_start_padding", 28)
	popup.add_theme_constant_override("item_end_padding", 24)
	
	var sb_popup = StyleBoxFlat.new()
	sb_popup.bg_color = Color(0.14, 0.08, 0.04, 0.98)
	sb_popup.set_border_width_all(2)
	sb_popup.border_color = Color(0.85, 0.70, 0.35, 0.95)
	sb_popup.set_corner_radius_all(14)
	sb_popup.content_margin_left = 28
	sb_popup.content_margin_right = 28
	sb_popup.content_margin_top = 20
	sb_popup.content_margin_bottom = 20
	sb_popup.shadow_size = 18
	sb_popup.shadow_color = Color(0, 0, 0, 0.6)
	popup.add_theme_stylebox_override("panel", sb_popup)

