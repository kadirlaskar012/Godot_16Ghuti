class_name SmoothScrollContainer
extends ScrollContainer

## Smooth physics-based inertial touch scrolling for mobile devices.
## Provides fluid kinetic drag, flick momentum, and smooth friction deceleration.

@export var friction: float = 6.0
@export var drag_sensitivity: float = 1.0

var _velocity_y: float = 0.0
var _is_dragging: bool = false
var _start_touch_pos: Vector2 = Vector2.ZERO
var _last_drag_pos_y: float = 0.0
var _last_drag_time: float = 0.0
var _drag_started: bool = false

func _ready() -> void:
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_deadzone = 8
	# Set all non-button child controls to pass mouse events so dragging is never blocked
	call_deferred("_make_children_pass_mouse")

func _make_children_pass_mouse() -> void:
	_set_mouse_filter_recursive(self)

func _set_mouse_filter_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not (child is Button or child is LineEdit or child is OptionButton):
			if child.mouse_filter == Control.MOUSE_FILTER_STOP:
				child.mouse_filter = Control.MOUSE_FILTER_PASS
		_set_mouse_filter_recursive(child)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	var global_rect = get_global_rect()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if global_rect.has_point(event.global_position):
					_start_touch_pos = event.global_position
					_last_drag_pos_y = event.global_position.y
					_last_drag_time = Time.get_ticks_msec() / 1000.0
					_velocity_y = 0.0
					_is_dragging = true
					_drag_started = false
			else:
				if _is_dragging:
					_is_dragging = false
					_drag_started = false
					
	elif event is InputEventMouseMotion:
		if _is_dragging:
			var dy = event.global_position.y - _last_drag_pos_y
			if not _drag_started and absf(event.global_position.y - _start_touch_pos.y) > 8.0:
				_drag_started = true
			if _drag_started:
				var now = Time.get_ticks_msec() / 1000.0
				var dt = maxf(0.001, now - _last_drag_time)
				scroll_vertical -= int(dy * drag_sensitivity)
				var instant_vel = -dy / dt
				_velocity_y = lerpf(_velocity_y, instant_vel, 0.45)
				_last_drag_pos_y = event.global_position.y
				_last_drag_time = now
				
	elif event is InputEventScreenTouch:
		if event.pressed:
			if global_rect.has_point(event.position):
				_start_touch_pos = event.position
				_last_drag_pos_y = event.position.y
				_last_drag_time = Time.get_ticks_msec() / 1000.0
				_velocity_y = 0.0
				_is_dragging = true
				_drag_started = false
		else:
			if _is_dragging:
				_is_dragging = false
				_drag_started = false
				
	elif event is InputEventScreenDrag:
		if _is_dragging:
			var dy = event.relative.y
			if not _drag_started and absf(event.position.y - _start_touch_pos.y) > 8.0:
				_drag_started = true
			if _drag_started:
				var now = Time.get_ticks_msec() / 1000.0
				var dt = maxf(0.001, now - _last_drag_time)
				scroll_vertical -= int(dy * drag_sensitivity)
				var instant_vel = -dy / dt
				_velocity_y = lerpf(_velocity_y, instant_vel, 0.45)
				_last_drag_time = now

func _process(delta: float) -> void:
	if not _is_dragging and absf(_velocity_y) > 10.0:
		scroll_vertical += int(_velocity_y * delta)
		_velocity_y = lerpf(_velocity_y, 0.0, friction * delta)
		if absf(_velocity_y) <= 10.0:
			_velocity_y = 0.0
