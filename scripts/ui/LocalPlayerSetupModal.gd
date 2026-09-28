class_name LocalPlayerSetupModal
extends CanvasLayer

signal closed

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

@onready var p1_name_input: LineEdit = find_child("P1NameInput", true, false)
@onready var p2_name_input: LineEdit = find_child("P2NameInput", true, false)
@onready var p1_avatar_row: HBoxContainer = find_child("P1AvatarRow", true, false)
@onready var p2_avatar_row: HBoxContainer = find_child("P2AvatarRow", true, false)
@onready var start_btn: Button = find_child("StartButton", true, false)
@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var dim_overlay: ColorRect = find_child("DimOverlay", true, false)

var _p1_selected_avatar: int = 0
var _p2_selected_avatar: int = 1
var _p1_cards: Array[Button] = []
var _p2_cards: Array[Button] = []

func _ready() -> void:
	if SaveManager.player_data:
		_p1_selected_avatar = clampi(SaveManager.player_data.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
		if p1_name_input:
			p1_name_input.text = SaveManager.player_data.player_name
	
	if p2_name_input:
		p2_name_input.text = "Player 2"
		
	_p2_selected_avatar = 1 if _p1_selected_avatar != 1 else 2
	
	_build_avatar_selectors()
	
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
		_setup_btn(start_btn)
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		_setup_btn(close_btn)
	if dim_overlay:
		dim_overlay.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				_on_close_pressed()
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

func _build_avatar_selectors() -> void:
	_p1_cards.clear()
	_p2_cards.clear()
	
	if p1_avatar_row:
		for c in p1_avatar_row.get_children():
			c.queue_free()
		for i in range(AVATAR_TEXTURES.size()):
			var btn = _create_avatar_button(i, 1)
			p1_avatar_row.add_child(btn)
			_p1_cards.append(btn)
			
	if p2_avatar_row:
		for c in p2_avatar_row.get_children():
			c.queue_free()
		for i in range(AVATAR_TEXTURES.size()):
			var btn = _create_avatar_button(i, 2)
			p2_avatar_row.add_child(btn)
			_p2_cards.append(btn)
			
	_refresh_highlights()

func _create_avatar_button(idx: int, player_num: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	
	var tex_rect = TextureRect.new()
	tex_rect.name = "AvatarIcon"
	tex_rect.texture = AVATAR_TEXTURES[idx]
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.offset_left = 6
	tex_rect.offset_top = 6
	tex_rect.offset_right = -6
	tex_rect.offset_bottom = -6
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex_rect)
	
	btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
		if player_num == 1:
			_p1_selected_avatar = idx
		else:
			_p2_selected_avatar = idx
		_refresh_highlights()
	)
	return btn

func _refresh_highlights() -> void:
	for i in range(_p1_cards.size()):
		var btn = _p1_cards[i]
		var is_sel = (i == _p1_selected_avatar)
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		if is_sel:
			sb.bg_color = Color(0.85, 0.25, 0.20, 0.35)
			sb.border_color = Color(1.0, 0.45, 0.40, 1.0)
			sb.set_border_width_all(3)
			btn.scale = Vector2(1.08, 1.08)
		else:
			sb.bg_color = Color(0.12, 0.08, 0.04, 0.6)
			sb.border_color = Color(0.4, 0.3, 0.2, 0.5)
			sb.set_border_width_all(1)
			btn.scale = Vector2.ONE
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		
	for i in range(_p2_cards.size()):
		var btn = _p2_cards[i]
		var is_sel = (i == _p2_selected_avatar)
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		if is_sel:
			sb.bg_color = Color(0.9, 0.8, 0.5, 0.35)
			sb.border_color = Color(1.0, 0.90, 0.45, 1.0)
			sb.set_border_width_all(3)
			btn.scale = Vector2(1.08, 1.08)
		else:
			sb.bg_color = Color(0.12, 0.08, 0.04, 0.6)
			sb.border_color = Color(0.4, 0.3, 0.2, 0.5)
			sb.set_border_width_all(1)
			btn.scale = Vector2.ONE
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	var p1_name = p1_name_input.text.strip_edges() if p1_name_input else "Player 1"
	if p1_name.is_empty():
		p1_name = "Player 1"
	var p2_name = p2_name_input.text.strip_edges() if p2_name_input else "Player 2"
	if p2_name.is_empty():
		p2_name = "Player 2"
		
	GameManager.set_local_players(p1_name, _p1_selected_avatar, p2_name, _p2_selected_avatar)
	closed.emit()
	queue_free()
	GameManager.start_match(GameManager.GameMode.LOCAL_2P)

func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	closed.emit()
	queue_free()
