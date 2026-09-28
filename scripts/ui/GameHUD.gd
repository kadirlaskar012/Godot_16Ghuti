class_name GameHUD
extends CanvasLayer

## GameHUD manages top opponent card, header bar, match timer, theme switching,
## 7-second circular radial turn timers, extra-time badges, and bottom player card.
## Responsive for all mobile aspect ratios with safe area inset protection.

signal undo_pressed
signal hint_pressed
signal reset_pressed
signal menu_pressed
signal time_expired
signal theme_changed(theme_id: String)

@onready var top_margin: MarginContainer = $TopMargin
@onready var header_bar: HBoxContainer = find_child("HeaderBar", true, false)
@onready var menu_btn: Button = find_child("MenuButton", true, false)
@onready var sound_btn: Button = find_child("SoundButton", true, false)
@onready var theme_btn: Button = find_child("ThemeButton", true, false)
@onready var timer_label: Label = find_child("TimerLabel", true, false)

# Opponent (Player 2)
@onready var p2_panel: PanelContainer = find_child("P2Card", true, false)
@onready var p2_avatar: TextureRect = p2_panel.find_child("Avatar", true, false)
@onready var p2_name_label: Label = p2_panel.find_child("PlayerName", true, false)
@onready var p2_subtitle: Label = p2_panel.find_child("SubTitle", true, false)
@onready var p2_count_label: Label = p2_panel.find_child("PieceCount", true, false)
@onready var p2_beads_container: HBoxContainer = p2_panel.find_child("P2Beads", true, false)
@onready var p2_glow_border: ReferenceRect = p2_panel.find_child("GlowBorder", true, false)
@onready var p2_radial: Control = p2_panel.find_child("P2RadialTimer", true, false)
@onready var p2_extra_badge: PanelContainer = p2_panel.find_child("P2ExtraBadge", true, false)
@onready var p2_extra_label: Label = p2_panel.find_child("P2ExtraLabel", true, false)

# Player 1 (Me / User)
@onready var p1_panel: PanelContainer = find_child("P1Card", true, false)
@onready var p1_avatar: TextureRect = p1_panel.find_child("Avatar", true, false)
@onready var p1_name_label: Label = p1_panel.find_child("PlayerName", true, false)
@onready var p1_subtitle: Label = p1_panel.find_child("SubTitle", true, false)
@onready var p1_count_label: Label = p1_panel.find_child("PieceCount", true, false)
@onready var p1_beads_container: HBoxContainer = p1_panel.find_child("P1Beads", true, false)
@onready var p1_radial: Control = p1_panel.find_child("P1RadialTimer", true, false)
@onready var p1_extra_badge: PanelContainer = p1_panel.find_child("P1ExtraBadge", true, false)
@onready var p1_extra_label: Label = p1_panel.find_child("P1ExtraLabel", true, false)
@onready var p1_glow_border: ReferenceRect = p1_panel.find_child("GlowBorder", true, false)

# Action Bar
@onready var bottom_bar: Control = find_child("BottomBar", true, false)
@onready var undo_btn: Button = find_child("UndoButton", true, false)
@onready var hint_btn: Button = find_child("HintButton", true, false)
@onready var reset_btn: Button = find_child("ResetButton", true, false)

# Bead visual piece indicators (16 beads per player)
var _p1_bead_panels: Array[Panel] = []
var _p2_bead_panels: Array[Panel] = []
var _bead_style_p1_act: StyleBoxFlat
var _bead_style_p1_dim: StyleBoxFlat
var _bead_style_p2_act: StyleBoxFlat
var _bead_style_p2_dim: StyleBoxFlat

# Test compatibility fields
var turn_timer_box: Control
var turn_timer_title: Label
var turn_timer_value: Label
var p1_badge_label: Label

var timer_total_duration: float = float(BackendConfig.MATCH_DURATION)
var timer_remaining_seconds: float = float(BackendConfig.MATCH_DURATION)
var timer_accumulated_elapsed: float = 0.0
var timer_start_ticks: int = 0
var timer_active: bool = false
var _turn_pulse_tween: Tween
var _timer_pulse_tween: Tween
var _last_pulse_second: int = -1
var _active_toast: PanelContainer

# 7-Second Normal Turn Timer & 60-Second Personal Extra Time Reserves
var turn_normal_duration: float = float(BackendConfig.TURN_NORMAL_TIME) # 7.0s
var player_extra_duration: float = float(BackendConfig.PLAYER_EXTRA_TIME) # 60.0s
var current_turn_remaining: float = float(BackendConfig.TURN_NORMAL_TIME)
var current_is_extra_time: bool = false
var p1_extra_time_remaining: float = float(BackendConfig.PLAYER_EXTRA_TIME)
var p2_extra_time_remaining: float = float(BackendConfig.PLAYER_EXTRA_TIME)
var active_turn_player: int = BoardData.Player.PLAYER_1
var _last_turn_tick_sec: int = -1
var _last_extra_tick_sec: int = -1

const AVATAR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/avatar_warrior.png"),
	preload("res://assets/textures/avatar_king.png"),
	preload("res://assets/textures/avatar_queen.png"),
	preload("res://assets/textures/avatar_samurai.png"),
	preload("res://assets/textures/avatar_knight.png"),
	preload("res://assets/textures/avatar_prince.png"),
	preload("res://assets/textures/avatar_princess.png"),
	preload("res://assets/textures/avatar_mystic.png"),
]
const AVATAR_AI = preload("res://assets/textures/avatar_ai.png")

var _last_p1_count: int = 16
var _last_p2_count: int = 16

const THEMES: Array[Dictionary] = [
	{"id": "classic_wood", "name": "Classic Dark Walnut"},
	{"id": "royal_mahogany", "name": "Royal Mahogany"},
	{"id": "ivory_maple", "name": "Ivory Maple (Light Mode)"}
]

func _ready() -> void:
	# Test compatibility controls
	turn_timer_box = Control.new()
	turn_timer_box.visible = true
	turn_timer_title = Label.new()
	turn_timer_value = Label.new()
	add_child(turn_timer_box)
	turn_timer_box.add_child(turn_timer_title)
	turn_timer_box.add_child(turn_timer_value)
	p1_badge_label = p1_extra_label
	
	if menu_btn:
		menu_btn.pressed.connect(func(): menu_pressed.emit())
		_setup_button_animation(menu_btn)
	if sound_btn:
		sound_btn.pressed.connect(_toggle_sound)
		_setup_button_animation(sound_btn)
	if theme_btn:
		theme_btn.pressed.connect(_cycle_theme)
		_setup_button_animation(theme_btn)
	if undo_btn:
		undo_btn.pressed.connect(func(): undo_pressed.emit())
		_setup_button_animation(undo_btn)
	if hint_btn:
		hint_btn.pressed.connect(func(): hint_pressed.emit())
		_setup_button_animation(hint_btn)
	if reset_btn:
		reset_btn.pressed.connect(func(): reset_pressed.emit())
		_setup_button_animation(reset_btn)
	
	if timer_label:
		timer_label.visible = false
	
	_update_sound_icon()
	_update_theme_btn_text()
	_setup_bead_indicators()
	setup_players()
	update_hud(GameManager.current_state)

func _init_bead_styles() -> void:
	if _bead_style_p1_act != null:
		return
	_bead_style_p1_act = StyleBoxFlat.new()
	_bead_style_p1_act.bg_color = Color(0.92, 0.22, 0.22, 1.0)
	_bead_style_p1_act.border_color = Color(1.0, 0.85, 0.35, 0.9)
	_bead_style_p1_act.set_border_width_all(1)
	_bead_style_p1_act.set_corner_radius_all(6)
	
	_bead_style_p1_dim = StyleBoxFlat.new()
	_bead_style_p1_dim.bg_color = Color(0.25, 0.15, 0.15, 0.3)
	_bead_style_p1_dim.border_color = Color(0.4, 0.3, 0.3, 0.25)
	_bead_style_p1_dim.set_border_width_all(1)
	_bead_style_p1_dim.set_corner_radius_all(6)
	
	_bead_style_p2_act = StyleBoxFlat.new()
	_bead_style_p2_act.bg_color = Color(0.96, 0.93, 0.84, 1.0)
	_bead_style_p2_act.border_color = Color(0.85, 0.72, 0.45, 0.9)
	_bead_style_p2_act.set_border_width_all(1)
	_bead_style_p2_act.set_corner_radius_all(6)
	
	_bead_style_p2_dim = StyleBoxFlat.new()
	_bead_style_p2_dim.bg_color = Color(0.2, 0.2, 0.2, 0.3)
	_bead_style_p2_dim.border_color = Color(0.4, 0.4, 0.4, 0.25)
	_bead_style_p2_dim.set_border_width_all(1)
	_bead_style_p2_dim.set_corner_radius_all(6)

func _setup_bead_indicators() -> void:
	_init_bead_styles()
	if p1_beads_container:
		for c in p1_beads_container.get_children():
			c.queue_free()
		_p1_bead_panels.clear()
		for i in range(16):
			var b = Panel.new()
			b.custom_minimum_size = Vector2(10, 10)
			b.add_theme_stylebox_override("panel", _bead_style_p1_act)
			p1_beads_container.add_child(b)
			_p1_bead_panels.append(b)
			
	if p2_beads_container:
		for c in p2_beads_container.get_children():
			c.queue_free()
		_p2_bead_panels.clear()
		for i in range(16):
			var b = Panel.new()
			b.custom_minimum_size = Vector2(10, 10)
			b.add_theme_stylebox_override("panel", _bead_style_p2_act)
			p2_beads_container.add_child(b)
			_p2_bead_panels.append(b)

func _update_beads(p1_count: int, p2_count: int) -> void:
	for i in range(_p1_bead_panels.size()):
		var b = _p1_bead_panels[i]
		if is_instance_valid(b):
			if i < p1_count:
				b.add_theme_stylebox_override("panel", _bead_style_p1_act)
			else:
				b.add_theme_stylebox_override("panel", _bead_style_p1_dim)
			
	for i in range(_p2_bead_panels.size()):
		var b = _p2_bead_panels[i]
		if is_instance_valid(b):
			if i < p2_count:
				b.add_theme_stylebox_override("panel", _bead_style_p2_act)
			else:
				b.add_theme_stylebox_override("panel", _bead_style_p2_dim)

func apply_safe_margins(top_val: float, _bottom_val: float) -> void:
	if top_margin:
		top_margin.add_theme_constant_override("margin_top", int(maxf(top_val, 48.0)))

func get_top_zone_height() -> float:
	var m_top = 48.0
	if top_margin:
		m_top = float(top_margin.get_theme_constant("margin_top"))
	return m_top + 68.0

func get_bottom_zone_height() -> float:
	return 120.0

func is_bottom_bar_needed() -> bool:
	if GameManager.current_mode == GameManager.GameMode.ONLINE_MULTIPLAYER:
		return false
	return true

## Positions P2Card, P1Card, and BottomBar dynamically with proper breathing room.
## Guarantees profiles NEVER touch board borders on any mobile aspect ratio.
func position_layout_relative_to_board(board_top: float, board_bottom: float, vp_size: Vector2, gap_board: float = 24.0, p2_y_override: float = -1.0) -> void:
	var ui_scale: float = clampf(vp_size.x / 1080.0, 0.35, 1.5)
	var margin_x: float = 8.0 * ui_scale
	var card_w: float = vp_size.x - (margin_x * 2.0)
	var actual_card_h: float = 129.0
	if p2_panel:
		actual_card_h = maxf(129.0 * ui_scale, p2_panel.get_combined_minimum_size().y)
	var card_h: float = actual_card_h
	var is_bar_needed: bool = is_bottom_bar_needed()
	var actual_bar_h: float = 76.0
	if bottom_bar:
		actual_bar_h = maxf(76.0 * ui_scale, bottom_bar.get_combined_minimum_size().y)
	var bar_h: float = actual_bar_h if is_bar_needed else 0.0
	var gap_card_to_bar: float = 4.0 if is_bar_needed else 0.0
	
	var safe_top: float = float(top_margin.get_theme_constant("margin_top")) if top_margin else 44.0
	var header_bottom: float = safe_top + (58.0 * ui_scale)
	
	var p2_y: float = p2_y_override
	if p2_y < 0.0:
		var top_avail = board_top - header_bottom
		var top_slack = maxf(0.0, top_avail - card_h)
		var gap_top = maxf(gap_board, top_slack * 0.50)
		p2_y = board_top - card_h - gap_top
		p2_y = maxf(p2_y, header_bottom + (6.0 * ui_scale))
		
	if p2_panel:
		p2_panel.position = Vector2(margin_x, p2_y)
		p2_panel.size = Vector2(card_w, card_h)
		
	var p1_y: float = board_bottom + gap_board
	if p1_panel:
		p1_panel.position = Vector2(margin_x, p1_y)
		p1_panel.size = Vector2(card_w, card_h)
		
	if bottom_bar:
		bottom_bar.visible = is_bar_needed
		if is_bar_needed:
			var actual_p1_h: float = p1_panel.size.y if p1_panel else card_h
			var bar_y: float = p1_y + actual_p1_h + gap_card_to_bar
			bottom_bar.position = Vector2(margin_x, bar_y)
			bottom_bar.size = Vector2(card_w, bar_h)

func _setup_button_animation(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.93, 0.93), 0.08).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _cycle_theme() -> void:
	var cur = SaveManager.settings.board_theme
	var cur_idx = 0
	for i in range(THEMES.size()):
		if THEMES[i]["id"] == cur:
			cur_idx = i
			break
	var next_idx = (cur_idx + 1) % THEMES.size()
	var new_theme = THEMES[next_idx]
	
	SaveManager.settings.board_theme = new_theme["id"]
	SaveManager.save_data()
	_update_theme_btn_text()
	theme_changed.emit(new_theme["id"])
	show_toast("Theme: %s" % new_theme["name"], 1.5)

func _update_theme_btn_text() -> void:
	var cur = SaveManager.settings.board_theme
	if cur == "ivory_maple":
		theme_btn.text = "☀️ LIGHT"
	elif cur == "royal_mahogany":
		theme_btn.text = "🍷 RED OAK"
	else:
		theme_btn.text = "🪵 WALNUT"

func _toggle_sound() -> void:
	if SaveManager.settings:
		SaveManager.settings.sound_enabled = not SaveManager.settings.sound_enabled
		SaveManager.settings.music_enabled = SaveManager.settings.sound_enabled
		SaveManager.save_data()
		AudioManager.update_audio_settings()
		_update_sound_icon()
		HapticManager.vibrate_selection()

func _update_sound_icon() -> void:
	if SaveManager.settings and (SaveManager.settings.sound_enabled or SaveManager.settings.music_enabled):
		sound_btn.text = "🔊"
	else:
		sound_btn.text = "🔇"

func _animate_piece_count_change(label: Label, new_count: int) -> void:
	label.pivot_offset = Vector2(60, 20)
	var tw = create_tween()
	tw.tween_property(label, "scale", Vector2(1.30, 1.30), 0.10).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		label.text = "%d Guti" % new_count
	)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _format_bank_time(secs: float) -> String:
	var total_s = int(ceil(maxf(0.0, secs)))
	var m = total_s / 60
	var s = total_s % 60
	return "%02d:%02d" % [m, s]

func _format_extra_display(secs: float) -> String:
	if GameManager.current_mode == GameManager.GameMode.ONLINE_MULTIPLAYER:
		return "EXTRA: %ds" % int(ceil(secs))
	return _format_bank_time(secs)

func setup_players() -> void:
	var mode = GameManager.current_mode
	
	# Reset turn timers to fresh match state (60-second personal extra time reserve per player)
	player_extra_duration = float(BackendConfig.PLAYER_EXTRA_TIME)
	p1_extra_time_remaining = player_extra_duration
	p2_extra_time_remaining = player_extra_duration
	current_turn_remaining = turn_normal_duration
	current_is_extra_time = false
	active_turn_player = BoardData.Player.PLAYER_1
	_last_turn_tick_sec = -1
	_last_extra_tick_sec = -1
	
	if mode == GameManager.GameMode.PLAYER_VS_AI:
		# Player 1 (User)
		p1_name_label.text = SaveManager.player_data.player_name
		var p1_av = clampi(SaveManager.player_data.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
		p1_avatar.texture = AVATAR_TEXTURES[p1_av]
		p1_subtitle.text = "RED (YOU)"
		
		# Player 2 (AI Bot) - High resolution AI Grandmaster
		var diff_str = ["EASY", "MEDIUM", "HARD"][GameManager.current_difficulty]
		p2_name_label.text = "AI BOT (%s)" % diff_str
		p2_avatar.texture = AVATAR_AI
		p2_subtitle.text = "IVORY OPPONENT"
		
		# Buttons: Hint and Reset AVAILABLE in VS AI
		hint_btn.visible = true
		reset_btn.visible = true
		undo_btn.visible = true
		
	elif mode == GameManager.GameMode.LOCAL_2P:
		# Real customized profiles from LocalPlayerSetupModal
		var p1_name = GameManager.p1_custom_name if not GameManager.p1_custom_name.is_empty() else SaveManager.player_data.player_name
		var p1_av = GameManager.p1_custom_avatar_idx if GameManager.p1_custom_avatar_idx >= 0 else SaveManager.player_data.avatar_index
		p1_name_label.text = p1_name
		p1_avatar.texture = AVATAR_TEXTURES[clampi(p1_av, 0, AVATAR_TEXTURES.size() - 1)]
		p1_subtitle.text = "RED PLAYER 1"
		
		var p2_name = GameManager.p2_custom_name if not GameManager.p2_custom_name.is_empty() else "Player 2"
		var p2_av = GameManager.p2_custom_avatar_idx if GameManager.p2_custom_avatar_idx >= 0 else 1
		p2_name_label.text = p2_name
		p2_avatar.texture = AVATAR_TEXTURES[clampi(p2_av, 0, AVATAR_TEXTURES.size() - 1)]
		p2_subtitle.text = "IVORY PLAYER 2"
		
		# Buttons per user requirement: NO Hints, NO Reset in Local 2 Player
		hint_btn.visible = false
		reset_btn.visible = false
		undo_btn.visible = true
		
	elif mode == GameManager.GameMode.ONLINE_MULTIPLAYER:
		p1_name_label.text = SaveManager.player_data.player_name
		var p1_av = clampi(SaveManager.player_data.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
		p1_avatar.texture = AVATAR_TEXTURES[p1_av]
		p1_subtitle.text = "RED (YOU)"
		
		var om = get_node_or_null("/root/OnlineMatchManager")
		p2_name_label.text = om.opponent_name if om else "Online Opponent"
		p2_avatar.texture = AVATAR_TEXTURES[1]
		p2_subtitle.text = "IVORY OPPONENT"
		
		hint_btn.visible = false
		reset_btn.visible = false
		undo_btn.visible = false
		
	# Main match timer removed per user requirement (only 10s turn timer & 5m bank per player)
	timer_active = false
	timer_total_duration = 300.0
	timer_remaining_seconds = 300.0
	if timer_label:
		timer_label.text = "05:00"
		timer_label.visible = false
			
	if p1_radial:
		p1_radial.max_time = turn_normal_duration
		p1_radial.current_time = turn_normal_duration
	if p2_radial:
		p2_radial.max_time = turn_normal_duration
		p2_radial.current_time = turn_normal_duration
		
	_update_turn_timer_display()

func set_server_authoritative_time(remaining: float) -> void:
	timer_remaining_seconds = remaining
	_update_timer_display()

func update_server_turn_timer(turn_data: Dictionary) -> void:
	if turn_data.has("turn_remaining_seconds"):
		current_turn_remaining = float(turn_data["turn_remaining_seconds"])
	if turn_data.has("is_extra_time"):
		current_is_extra_time = bool(turn_data["is_extra_time"])
	if turn_data.has("p1_extra_time"):
		p1_extra_time_remaining = float(turn_data["p1_extra_time"])
	if turn_data.has("p2_extra_time"):
		p2_extra_time_remaining = float(turn_data["p2_extra_time"])
	if turn_data.has("match_remaining_seconds"):
		timer_remaining_seconds = float(turn_data["match_remaining_seconds"])
	elif turn_data.has("remaining_seconds"):
		timer_remaining_seconds = float(turn_data["remaining_seconds"])
		
	if turn_timer_title:
		turn_timer_title.text = "EXTRA TIME" if current_is_extra_time else "TURN"
	if turn_timer_value:
		turn_timer_value.text = "%02d" % int(ceil(current_turn_remaining))
		if not current_is_extra_time:
			if current_turn_remaining <= 3.0:
				turn_timer_value.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
			else:
				turn_timer_value.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		else:
			if current_turn_remaining <= 10.0:
				turn_timer_value.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			else:
				turn_timer_value.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
				
	_update_turn_timer_display()
	_update_timer_display()

func reset_turn_timer() -> void:
	current_turn_remaining = turn_normal_duration
	current_is_extra_time = false
	_last_turn_tick_sec = -1
	_last_extra_tick_sec = -1
	_update_turn_timer_display()

func _update_turn_timer_display() -> void:
	var is_p1_active = (active_turn_player == BoardData.Player.PLAYER_1)
	
	if p1_radial:
		p1_radial.is_active = is_p1_active
		p1_radial.is_extra_time = (is_p1_active and current_is_extra_time)
		p1_radial.current_time = current_turn_remaining if is_p1_active else turn_normal_duration
		
	if p2_radial:
		p2_radial.is_active = not is_p1_active
		p2_radial.is_extra_time = (not is_p1_active and current_is_extra_time)
		p2_radial.current_time = current_turn_remaining if not is_p1_active else turn_normal_duration
		
	if p1_extra_label:
		p1_extra_label.text = _format_extra_display(p1_extra_time_remaining)
		if is_p1_active and current_is_extra_time:
			p1_extra_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		else:
			p1_extra_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			
	if p2_extra_label:
		p2_extra_label.text = _format_extra_display(p2_extra_time_remaining)
		if not is_p1_active and current_is_extra_time:
			p2_extra_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		else:
			p2_extra_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func pause_timer() -> void:
	if timer_active:
		var elapsed_since_start = float(Time.get_ticks_msec() - timer_start_ticks) / 1000.0
		timer_accumulated_elapsed += elapsed_since_start

func resume_timer() -> void:
	if timer_active:
		timer_start_ticks = Time.get_ticks_msec()

func stop_timer() -> void:
	timer_active = false

func start_debug_test_timer(seconds: float = 10.0) -> void:
	timer_total_duration = seconds
	timer_remaining_seconds = seconds
	timer_accumulated_elapsed = 0.0
	timer_start_ticks = Time.get_ticks_msec()
	timer_active = true
	if timer_label:
		timer_label.visible = true
	_update_timer_display()

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
		
	# 1. Overall Match Timer countdown
	if timer_active:
		var elapsed_since_start = float(Time.get_ticks_msec() - timer_start_ticks) / 1000.0
		var total_elapsed = timer_accumulated_elapsed + elapsed_since_start
		timer_remaining_seconds = max(0.0, timer_total_duration - total_elapsed)
		_update_timer_display()
		
		if timer_remaining_seconds <= 0.0:
			timer_remaining_seconds = 0.0
			timer_active = false
			_update_timer_display()
			_on_time_up_reached()
			time_expired.emit()
			return
			
	# 2. Turn Timer & Personal Extra Time countdown (for offline / local modes)
	if GameManager.current_mode != GameManager.GameMode.ONLINE_MULTIPLAYER:
		if not current_is_extra_time:
			current_turn_remaining = maxf(0.0, current_turn_remaining - delta)
			
			# Note: Per user request, NO ticking clock sound when normal turn timer is ending.
			# Clock tick sound plays only when extra time is being used.
				
			if current_turn_remaining <= 0.0:
				current_turn_remaining = 0.0
				current_is_extra_time = true
				AudioManager.play_sfx("alert")
				HapticManager.vibrate_invalid()
				show_toast("Extra Time Activated!", 1.0)
		else:
			# Extra time decreases for active player from their personal 5-min bank
			if active_turn_player == BoardData.Player.PLAYER_1:
				p1_extra_time_remaining = maxf(0.0, p1_extra_time_remaining - delta)
				var ex_sec = int(ceil(p1_extra_time_remaining))
				if ex_sec != _last_extra_tick_sec:
					_last_extra_tick_sec = ex_sec
					AudioManager.play_sfx("tick", 1.08)
					
				if p1_extra_time_remaining <= 0.0:
					p1_extra_time_remaining = 0.0
					_on_player_extra_time_expired(BoardData.Player.PLAYER_1)
					return
			else:
				p2_extra_time_remaining = maxf(0.0, p2_extra_time_remaining - delta)
				var ex_sec = int(ceil(p2_extra_time_remaining))
				if ex_sec != _last_extra_tick_sec:
					_last_extra_tick_sec = ex_sec
					AudioManager.play_sfx("tick", 1.08)
					
				if p2_extra_time_remaining <= 0.0:
					p2_extra_time_remaining = 0.0
					_on_player_extra_time_expired(BoardData.Player.PLAYER_2)
					return
					
		_update_turn_timer_display()

func _on_player_extra_time_expired(timed_out_player: int) -> void:
	var winner = BoardData.Player.PLAYER_2 if timed_out_player == BoardData.Player.PLAYER_1 else BoardData.Player.PLAYER_1
	var loser_name = p1_name_label.text if timed_out_player == BoardData.Player.PLAYER_1 else p2_name_label.text
	_on_time_up_reached()
	GameManager.end_match(winner, "%s ran out of Extra Time!" % loser_name, true)

func _on_time_up_reached() -> void:
	if _turn_pulse_tween:
		_turn_pulse_tween.kill()
	if _timer_pulse_tween:
		_timer_pulse_tween.kill()
		
	if undo_btn:
		undo_btn.disabled = true
		undo_btn.modulate.a = 0.4
	if hint_btn:
		hint_btn.disabled = true
		hint_btn.modulate.a = 0.4
	if reset_btn:
		reset_btn.disabled = true
		reset_btn.modulate.a = 0.4
	
	if p1_glow_border: p1_glow_border.visible = false
	if p2_glow_border: p2_glow_border.visible = false

func _update_timer_display() -> void:
	if not timer_label:
		return
	var total_secs = int(ceil(timer_remaining_seconds))
	var mins = total_secs / 60
	var secs = total_secs % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	
	if timer_remaining_seconds > 60.0:
		timer_label.modulate = Color(1.0, 0.85, 0.4)
		timer_label.scale = Vector2.ONE
		_last_pulse_second = -1
	elif timer_remaining_seconds > 10.0:
		timer_label.modulate = Color(1.0, 0.65, 0.25)
		timer_label.scale = Vector2.ONE
		_last_pulse_second = -1
	elif timer_remaining_seconds > 0.0:
		timer_label.modulate = Color(1.0, 0.32, 0.32)
		if total_secs != _last_pulse_second:
			_last_pulse_second = total_secs
			timer_label.pivot_offset = timer_label.size / 2.0
			if _timer_pulse_tween:
				_timer_pulse_tween.kill()
			_timer_pulse_tween = create_tween()
			_timer_pulse_tween.tween_property(timer_label, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_QUAD)
			_timer_pulse_tween.tween_property(timer_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		timer_label.text = "00:00"
		timer_label.modulate = Color(1.0, 0.25, 0.25)
		timer_label.scale = Vector2.ONE

func update_hud(state: GameState) -> void:
	if state == null:
		return
		
	# Piece counts with animation
	if state.p1_pieces != _last_p1_count:
		_animate_piece_count_change(p1_count_label, state.p1_pieces)
		_last_p1_count = state.p1_pieces
	else:
		p1_count_label.text = "%d Guti" % state.p1_pieces
		
	if state.p2_pieces != _last_p2_count:
		_animate_piece_count_change(p2_count_label, state.p2_pieces)
		_last_p2_count = state.p2_pieces
	else:
		p2_count_label.text = "%d Guti" % state.p2_pieces
	
	_update_beads(state.p1_pieces, state.p2_pieces)
	
	# Turn switch detection: reset 7s normal timer when turn switches to other player
	var new_active_p = state.active_player
	if new_active_p != active_turn_player:
		active_turn_player = new_active_p
		current_turn_remaining = turn_normal_duration
		current_is_extra_time = false
		_last_turn_tick_sec = -1
		_last_extra_tick_sec = -1
		_update_turn_timer_display()
		
	# Turn highlight & pulse on player cards
	if _turn_pulse_tween:
		_turn_pulse_tween.kill()
		
	_turn_pulse_tween = create_tween().set_loops()
	
	if active_turn_player == BoardData.Player.PLAYER_1:
		p1_panel.modulate.a = 1.0
		if p1_glow_border: p1_glow_border.visible = true
		p2_panel.modulate.a = 0.65
		if p2_glow_border: p2_glow_border.visible = false
		
		if p1_glow_border:
			_turn_pulse_tween.tween_property(p1_glow_border, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
			_turn_pulse_tween.tween_property(p1_glow_border, "modulate:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE)
			
		p1_subtitle.text = "YOUR TURN (RED)" if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI else "PLAYER 1 TURN (RED)"
		p1_subtitle.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		
		if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI:
			p2_subtitle.text = "WAITING..."
			p2_subtitle.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
		else:
			p2_subtitle.text = "WAITING..."
			p2_subtitle.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	else:
		p2_panel.modulate.a = 1.0
		if p2_glow_border: p2_glow_border.visible = true
		p1_panel.modulate.a = 0.65
		if p1_glow_border: p1_glow_border.visible = false
		
		if p2_glow_border:
			_turn_pulse_tween.tween_property(p2_glow_border, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
			_turn_pulse_tween.tween_property(p2_glow_border, "modulate:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE)
			
		if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI:
			p2_subtitle.text = "AI IS THINKING..."
			p2_subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
		else:
			p2_subtitle.text = "PLAYER 2 TURN (IVORY)"
			p2_subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
			
		p1_subtitle.text = "WAITING..."
		p1_subtitle.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
				
	var can_undo = not state.history.is_empty() and GameManager.is_game_active
	if undo_btn:
		undo_btn.disabled = not can_undo
		undo_btn.modulate.a = 1.0 if can_undo else 0.45

func show_toast(msg: String, duration: float = 1.5) -> void:
	if _active_toast and is_instance_valid(_active_toast):
		_active_toast.queue_free()
		
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.94)
	style.border_color = Color(1.0, 0.8, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	panel.add_child(lbl)
	
	panel.anchors_preset = Control.PRESET_CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = 180
	panel.offset_bottom = 240
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(panel)
	_active_toast = panel
	
	panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	tw.tween_interval(duration)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(panel.queue_free)
