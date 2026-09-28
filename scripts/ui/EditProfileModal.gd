class_name EditProfileModal
extends CanvasLayer

## Modal to edit Player Name and select from 8 original Game Avatars in a 4x2 grid

signal saved
signal cancelled

@onready var name_input: LineEdit = find_child("NameInput", true, false)
@onready var save_btn: Button = find_child("SaveButton", true, false)
@onready var cancel_btn: Button = find_child("CancelButton", true, false)
@onready var avatar_container: GridContainer = find_child("AvatarGrid", true, false)
@onready var error_label: Label = find_child("ErrorLabel", true, false)
@onready var panel: PanelContainer = find_child("Panel", true, false)

const AVATAR_TEXTURES = [
	preload("res://assets/textures/avatar_warrior.png"),
	preload("res://assets/textures/avatar_king.png"),
	preload("res://assets/textures/avatar_queen.png"),
	preload("res://assets/textures/avatar_samurai.png"),
	preload("res://assets/textures/avatar_knight.png"),
	preload("res://assets/textures/avatar_prince.png"),
	preload("res://assets/textures/avatar_princess.png"),
	preload("res://assets/textures/avatar_mystic.png")
]

const AVATAR_NAMES = [
	"Warrior",
	"King",
	"Queen",
	"Samurai",
	"Knight",
	"Prince",
	"Princess",
	"Mystic"
]

var _selected_avatar_index: int = 0
var _avatar_cards: Array[Control] = []

func _ready() -> void:
	var p = SaveManager.player_data
	_selected_avatar_index = clampi(p.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
	if name_input:
		name_input.text = p.player_name
		name_input.max_length = 16
		name_input.text_changed.connect(func(_new_t):
			if error_label:
				error_label.visible = false
		)
		
	if error_label:
		error_label.visible = false
		
	_build_avatar_grid()
	
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
		_setup_btn(save_btn)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel_pressed)
		_setup_btn(cancel_btn)
		
	var dim = get_node_or_null("DimOverlay") as Control
	if dim:
		dim.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				_on_cancel_pressed()
		)
		
	# Entrance animation
	if panel:
		panel.scale = Vector2(0.9, 0.9)
		panel.pivot_offset = panel.custom_minimum_size / 2.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _setup_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _build_avatar_grid() -> void:
	if not avatar_container:
		return
	for c in avatar_container.get_children():
		c.queue_free()
	_avatar_cards.clear()
	
	for i in range(AVATAR_TEXTURES.size()):
		var card_btn = Button.new()
		card_btn.custom_minimum_size = Vector2(140, 150)
		card_btn.flat = true
		card_btn.focus_mode = Control.FOCUS_NONE
		
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)
		card_btn.add_child(vbox)
		
		# Avatar Circle Frame
		var frame = PanelContainer.new()
		frame.custom_minimum_size = Vector2(96, 96)
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(48)
		sb.bg_color = Color(0.12, 0.08, 0.04, 0.90)
		
		if i == _selected_avatar_index:
			sb.set_border_width_all(4)
			sb.border_color = Color(1.0, 0.88, 0.35, 1.0)
			sb.shadow_size = 14
			sb.shadow_color = Color(1.0, 0.85, 0.25, 0.45)
		else:
			sb.set_border_width_all(2)
			sb.border_color = Color(0.60, 0.45, 0.25, 0.5)
			sb.shadow_size = 4
			sb.shadow_color = Color(0, 0, 0, 0.3)
		frame.add_theme_stylebox_override("panel", sb)
		vbox.add_child(frame)
		
		var tex_rect = TextureRect.new()
		tex_rect.texture = AVATAR_TEXTURES[i]
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(88, 88)
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tex_rect)
		
		# Avatar Name Label
		var name_lbl = Label.new()
		name_lbl.text = AVATAR_NAMES[i]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		if i == _selected_avatar_index:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.60))
		vbox.add_child(name_lbl)
		
		var idx = i
		card_btn.pressed.connect(func():
			_select_avatar(idx)
		)
		avatar_container.add_child(card_btn)
		_avatar_cards.append(card_btn)

func _select_avatar(idx: int) -> void:
	AudioManager.play_sfx("click")
	HapticManager.vibrate_selection()
	_selected_avatar_index = idx
	_refresh_avatar_highlights()

func _refresh_avatar_highlights() -> void:
	for i in range(_avatar_cards.size()):
		var btn = _avatar_cards[i]
		var vbox = btn.get_child(0) as VBoxContainer
		if not vbox:
			continue
		var frame = vbox.get_child(0) as PanelContainer
		var name_lbl = vbox.get_child(1) as Label
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(48)
		sb.bg_color = Color(0.12, 0.08, 0.04, 0.90)
		
		if i == _selected_avatar_index:
			sb.set_border_width_all(4)
			sb.border_color = Color(1.0, 0.88, 0.35, 1.0)
			sb.shadow_size = 14
			sb.shadow_color = Color(1.0, 0.85, 0.25, 0.45)
			if name_lbl:
				name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		else:
			sb.set_border_width_all(2)
			sb.border_color = Color(0.60, 0.45, 0.25, 0.5)
			sb.shadow_size = 4
			sb.shadow_color = Color(0, 0, 0, 0.3)
			if name_lbl:
				name_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.60))
				
		frame.add_theme_stylebox_override("panel", sb)

func _on_save_pressed() -> void:
	AudioManager.play_sfx("click")
	var new_name = name_input.text.strip_edges() if name_input else ""
	if new_name.is_empty():
		if error_label:
			error_label.text = "Name cannot be empty!"
			error_label.visible = true
		return
		
	if new_name.length() > 16:
		new_name = new_name.substr(0, 16)
		
	var p = SaveManager.player_data
	p.player_name = new_name
	p.avatar_index = _selected_avatar_index
	SaveManager.save_data()
	
	saved.emit()
	_close_animated()

func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("click")
	cancelled.emit()
	_close_animated()

func _close_animated() -> void:
	if panel:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(panel, "modulate:a", 0.0, 0.12)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()
