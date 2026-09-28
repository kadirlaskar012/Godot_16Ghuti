class_name Piece
extends Node2D

## Piece token for 16 Guti / Sholo Guti
## Supports glossy 2.5D visual presentation, dynamic drop shadow, selection lift, jump arc, bounce landing, and capture particle bursts.

var player_owner: int = BoardData.Player.NONE
var current_node_id: int = -1
var is_selected: bool = false
var is_dragging: bool = false

@onready var shadow: Sprite2D = $Shadow
@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow
@onready var area: Area2D = $Area2D

signal piece_clicked(piece: Piece)
signal piece_input_event(piece: Piece, event: InputEvent)

const TEXTURE_RED = preload("res://assets/textures/piece_red.png")
const TEXTURE_IVORY = preload("res://assets/textures/piece_ivory.png")
const CAPTURE_PARTICLE_SCENE = preload("res://scenes/effects/CaptureParticle.tscn")

var _target_radius: float = 0.0
var _base_scale: Vector2 = Vector2(0.184, 0.184) # Responsive piece diameter (~78px for 135px node spacing, ~58% ratio)
var _shadow_base_scale: Vector2 = Vector2(0.54, 0.54)
var _shadow_nominal_pos: Vector2 = Vector2(0, 6)
var _glow_base_scale: Vector2 = Vector2(0.60, 0.60)

var _active_tween: Tween
var _glow_tween: Tween
var _nominal_position: Vector2

func setup(player: int, initial_node: int, initial_pos: Vector2) -> void:
	player_owner = player
	current_node_id = initial_node
	position = initial_pos
	_nominal_position = initial_pos
	scale = Vector2.ONE
	modulate = Color.WHITE
	name = "Piece_P%d_N%02d" % [player, initial_node]

## Dynamically calculates piece radius, sprite scale, drop shadow, and touch collision
func set_piece_radius(radius: float) -> void:
	_target_radius = radius
	var target_diameter: float = radius * 2.0
	# Inside the 512x512 piece texture, the visible circular disc is 425.0 px across
	var disc_diameter: float = 425.0
	var scale_val: float = target_diameter / disc_diameter
	_base_scale = Vector2(scale_val, scale_val)
	
	# Drop shadow slightly exceeds piece diameter (~1.08x, 155px wide in 256x256 texture)
	var shadow_scale: float = (target_diameter * 1.08) / 155.0
	_shadow_base_scale = Vector2(shadow_scale, shadow_scale)
	_shadow_nominal_pos = Vector2(0.0, max(4.0, radius * 0.15))
	
	# Selection glow halo (~1.25x piece diameter, 160px visible circle in 256x256 texture)
	var glow_scale: float = (target_diameter * 1.25) / 160.0
	_glow_base_scale = Vector2(glow_scale, glow_scale)
	
	if is_node_ready():
		if sprite:
			sprite.scale = _base_scale
		if shadow:
			shadow.scale = _shadow_base_scale
			shadow.position = _shadow_nominal_pos
		if glow:
			glow.scale = _glow_base_scale
			
		if area and area.has_node("CollisionShape2D"):
			var col = area.get_node("CollisionShape2D")
			if col.shape is CircleShape2D:
				var new_shape = col.shape.duplicate() as CircleShape2D
				new_shape.radius = radius * 1.05
				col.shape = new_shape

func reset_visual() -> void:
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
		
	is_selected = false
	is_dragging = false
	z_index = 0
	position = _nominal_position
	scale = Vector2.ONE
	modulate = Color.WHITE
	
	if sprite:
		sprite.position = Vector2.ZERO
		sprite.scale = _base_scale
		sprite.modulate = Color.WHITE
		if player_owner == BoardData.Player.PLAYER_1:
			sprite.texture = TEXTURE_RED
		else:
			sprite.texture = TEXTURE_IVORY
			
	if shadow:
		shadow.position = _shadow_nominal_pos
		shadow.scale = _shadow_base_scale
		shadow.modulate = Color(0, 0, 0, 0.52)
		
	if glow:
		glow.visible = false

func _ready() -> void:
	if _target_radius > 0.0:
		set_piece_radius(_target_radius)
	else:
		var default_radius: float = min(BoardData.CELL_DX, BoardData.CELL_DY) * 0.29
		set_piece_radius(default_radius)
		
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if player_owner == BoardData.Player.PLAYER_1:
			sprite.texture = TEXTURE_RED
		else:
			sprite.texture = TEXTURE_IVORY
		sprite.scale = _base_scale
		
	if glow:
		glow.visible = false
		glow.scale = _glow_base_scale
		
	if shadow:
		shadow.scale = _shadow_base_scale
		shadow.position = _shadow_nominal_pos
		shadow.modulate = Color(0, 0, 0, 0.52)

func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return
	is_selected = selected
	
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
		
	_active_tween = create_tween().set_parallel(true)
	
	if is_selected:
		z_index = 20
		# Stay firmly grounded on nominal position without airborne lift
		_active_tween.tween_property(self, "position", _nominal_position, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(sprite, "scale", _base_scale * 1.05, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Shadow stays on board, gently darkens
		if shadow:
			_active_tween.tween_property(shadow, "position", _shadow_nominal_pos + Vector2(0, 2.0), 0.12)
			_active_tween.tween_property(shadow, "scale", _shadow_base_scale * 1.02, 0.12)
			_active_tween.tween_property(shadow, "modulate:a", 0.55, 0.12)
		
		if glow:
			glow.visible = true
			glow.modulate = Color(1.0, 0.88, 0.22, 0.90)
			glow.scale = _glow_base_scale
			_glow_tween = create_tween().set_loops()
			_glow_tween.tween_property(glow, "scale", _glow_base_scale * 1.08, 0.55).set_trans(Tween.TRANS_SINE)
			_glow_tween.tween_property(glow, "scale", _glow_base_scale * 0.96, 0.55).set_trans(Tween.TRANS_SINE)
	else:
		z_index = 0
		# Land back down smoothly
		_active_tween.tween_property(self, "position", _nominal_position, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(sprite, "scale", _base_scale, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if shadow:
			_active_tween.tween_property(shadow, "position", _shadow_nominal_pos, 0.14)
			_active_tween.tween_property(shadow, "scale", _shadow_base_scale, 0.14)
			_active_tween.tween_property(shadow, "modulate:a", 0.52, 0.14)
		if glow:
			glow.visible = false

func start_drag() -> void:
	is_dragging = true
	is_selected = true
	z_index = 50
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
		
	var t = create_tween().set_parallel(true)
	# Subtle tactile scaling, strictly grounded
	t.tween_property(sprite, "scale", _base_scale * 1.04, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shadow:
		t.tween_property(shadow, "position", _shadow_nominal_pos + Vector2(0, 2.0), 0.08)
		t.tween_property(shadow, "scale", _shadow_base_scale * 1.02, 0.08)
		t.tween_property(shadow, "modulate:a", 0.55, 0.08)
	if glow:
		glow.visible = true
		glow.modulate = Color(1.0, 0.9, 0.3, 0.85)
		glow.scale = _glow_base_scale * 1.04

func update_drag_position(target_pos: Vector2) -> void:
	# Centered directly on finger/cursor with zero vertical displacement
	position = target_pos

func snap_back_to_nominal(on_complete: Callable = Callable()) -> void:
	is_dragging = false
	z_index = 0
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
		
	_active_tween = create_tween().set_parallel(true)
	_active_tween.tween_property(self, "position", _nominal_position, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(sprite, "scale", _base_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shadow:
		_active_tween.tween_property(shadow, "position", _shadow_nominal_pos, 0.18)
		_active_tween.tween_property(shadow, "scale", _shadow_base_scale, 0.18)
		_active_tween.tween_property(shadow, "modulate:a", 0.52, 0.18)
	if glow:
		glow.visible = false
	if on_complete.is_valid():
		_active_tween.chain().tween_callback(on_complete)

func settle_at_node(target_pos: Vector2, target_node: int, on_complete: Callable = Callable()) -> void:
	is_dragging = false
	is_selected = false
	z_index = 0
	current_node_id = target_node
	_nominal_position = target_pos
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
	if glow:
		glow.visible = false
		
	_active_tween = create_tween().set_parallel(true)
	_active_tween.tween_property(self, "position", target_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(sprite, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shadow:
		_active_tween.tween_property(shadow, "position", _shadow_nominal_pos, 0.12)
		_active_tween.tween_property(shadow, "scale", _shadow_base_scale, 0.12)
		_active_tween.tween_property(shadow, "modulate:a", 0.52, 0.12)
	if on_complete.is_valid():
		_active_tween.chain().tween_callback(on_complete)

func animate_move_to(target_pos: Vector2, target_node: int, on_complete: Callable = Callable()) -> void:
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
	if glow:
		glow.visible = false
		
	is_dragging = false
	is_selected = false
	z_index = 10
	current_node_id = target_node
	_nominal_position = target_pos
	
	var start_pos = position
	var move_duration = 0.28
	
	_active_tween = create_tween()
	# Subtle 2.0px glide for grounded tabletop feel across board lines
	var max_lift: float = 2.0
	_active_tween.tween_method(func(t: float):
		var horizontal_pos = start_pos.lerp(target_pos, t)
		var arc_lift = -sin(t * PI) * max_lift
		position = horizontal_pos + Vector2(0, arc_lift)
		if shadow:
			shadow.position = _shadow_nominal_pos
			shadow.modulate.a = 0.52
	, 0.0, 1.0, move_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Subtle landing settle
	_active_tween.tween_callback(func():
		z_index = 0
		if shadow:
			shadow.position = _shadow_nominal_pos
			shadow.modulate.a = 0.52
			
		var bounce_tween = create_tween()
		bounce_tween.tween_property(sprite, "scale", Vector2(_base_scale.x * 1.05, _base_scale.y * 0.95), 0.05)
		bounce_tween.tween_property(sprite, "scale", _base_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if on_complete.is_valid():
			on_complete.call()
	)

func animate_captured(on_complete: Callable = Callable()) -> void:
	if _active_tween:
		_active_tween.kill()
	if _glow_tween:
		_glow_tween.kill()
	if glow:
		glow.visible = false
		
	var tween = create_tween().set_parallel(true)
	# Dissolve cleanly in-place without lifting upward into the sky
	tween.tween_property(self, "scale", Vector2(0.12, 0.12), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.20).set_trans(Tween.TRANS_QUAD)
	
	tween.chain().tween_callback(func():
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)

func shake() -> void:
	var shake_tween = create_tween()
	var orig_x = position.x
	shake_tween.tween_property(self, "position:x", orig_x - 7.0, 0.04)
	shake_tween.tween_property(self, "position:x", orig_x + 7.0, 0.05)
	shake_tween.tween_property(self, "position:x", orig_x - 4.0, 0.04)
	shake_tween.tween_property(self, "position:x", orig_x + 4.0, 0.04)
	shake_tween.tween_property(self, "position:x", orig_x, 0.04)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	piece_input_event.emit(self, event)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		piece_clicked.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		piece_clicked.emit(self)
