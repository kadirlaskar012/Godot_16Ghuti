class_name BoardNode
extends Node2D

## BoardNode represents one of the 37 playable intersections on the 16 Guti board.

enum HighlightType {
	NONE = 0,
	VALID_MOVE = 1,
	VALID_CAPTURE = 2
}

var node_id: int = -1
var grid_coord: Vector2i = Vector2i.ZERO

@onready var socket_sprite: Sprite2D = $SocketSprite
@onready var move_highlight: Sprite2D = $MoveHighlight
@onready var capture_highlight: Sprite2D = $CaptureHighlight
@onready var debug_label: Label = $DebugLabel

signal clicked(node_id: int)

var current_highlight: int = HighlightType.NONE
var _pulse_tween: Tween
var _node_radius: float = 0.0

func setup(id: int, coord: Vector2i, pos: Vector2) -> void:
	node_id = id
	grid_coord = coord
	position = pos
	name = "Node_%02d" % id

## Dynamically scales the socket sprite, highlights, and touch collision to match piece radius
func set_node_radius(radius: float) -> void:
	_node_radius = radius
	# Empty socket disc is ~62% of piece diameter (~48px socket for ~78px piece)
	var socket_diameter: float = (radius * 2.0) * 0.62
	var socket_scale: float = socket_diameter / 97.0
	
	if is_node_ready():
		if socket_sprite:
			socket_sprite.scale = Vector2(socket_scale, socket_scale)
			
		if has_node("Area2D/CollisionShape2D"):
			var col = $Area2D/CollisionShape2D
			if col.shape is CircleShape2D:
				var new_shape = col.shape.duplicate() as CircleShape2D
				new_shape.radius = radius * 1.05
				col.shape = new_shape

func _ready() -> void:
	if _node_radius > 0.0:
		set_node_radius(_node_radius)
	else:
		var default_radius: float = min(BoardData.CELL_DX, BoardData.CELL_DY) * 0.29
		set_node_radius(default_radius)
		
	set_highlight(HighlightType.NONE)
	if debug_label:
		debug_label.text = str(node_id)
		debug_label.visible = false

func set_highlight(type: int) -> void:
	current_highlight = type
	if _pulse_tween:
		_pulse_tween.kill()
		
	if move_highlight: move_highlight.visible = false
	if capture_highlight: capture_highlight.visible = false
	
	var r = _node_radius if _node_radius > 0.0 else (min(BoardData.CELL_DX, BoardData.CELL_DY) * 0.29)
	var move_base_scale = (r * 2.0) / 97.0
	var capture_base_scale = (r * 2.0 * 1.05) / 109.0
	
	match type:
		HighlightType.VALID_MOVE:
			if move_highlight:
				move_highlight.visible = true
				move_highlight.scale = Vector2(move_base_scale, move_base_scale)
				_pulse_tween = create_tween().set_loops()
				_pulse_tween.tween_property(move_highlight, "scale", Vector2(move_base_scale * 1.15, move_base_scale * 1.15), 0.6).set_trans(Tween.TRANS_SINE)
				_pulse_tween.tween_property(move_highlight, "scale", Vector2(move_base_scale * 0.88, move_base_scale * 0.88), 0.6).set_trans(Tween.TRANS_SINE)
		HighlightType.VALID_CAPTURE:
			if capture_highlight:
				capture_highlight.visible = true
				capture_highlight.scale = Vector2(capture_base_scale, capture_base_scale)
				_pulse_tween = create_tween().set_loops()
				_pulse_tween.tween_property(capture_highlight, "scale", Vector2(capture_base_scale * 1.18, capture_base_scale * 1.18), 0.45).set_trans(Tween.TRANS_SINE)
				_pulse_tween.tween_property(capture_highlight, "scale", Vector2(capture_base_scale * 0.90, capture_base_scale * 0.90), 0.45).set_trans(Tween.TRANS_SINE)

func show_debug(show_id: bool) -> void:
	if debug_label:
		debug_label.visible = show_id

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(node_id)
	elif event is InputEventScreenTouch and event.pressed:
		clicked.emit(node_id)
