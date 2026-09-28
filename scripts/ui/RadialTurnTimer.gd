class_name RadialTurnTimer
extends Control

## Radial circular progress timer with center numeric countdown

@export var max_time: float = 10.0
@export var current_time: float = 10.0:
	set(v):
		current_time = clampf(v, 0.0, max_time)
		_update_label()
		queue_redraw()

@export var is_active: bool = false:
	set(v):
		is_active = v
		_update_label()
		queue_redraw()

@export var is_extra_time: bool = false:
	set(v):
		is_extra_time = v
		_update_label()
		queue_redraw()

@export var radius: float = 32.0
@export var stroke_width: float = 6.0

var _label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0 + stroke_width * 2.0, radius * 2.0 + stroke_width * 2.0)
	
	_label = Label.new()
	_label.name = "SecondsLabel"
	_label.set_anchors_preset(PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8))
	add_child(_label)
	_update_label()

func _update_label() -> void:
	if not _label:
		return
		
	var secs = int(ceil(current_time))
	_label.text = "%02d" % max(0, secs)
	
	if not is_active:
		_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.45, 0.6))
	elif is_extra_time:
		_label.text = "00"
		_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	elif secs <= 3:
		_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	else:
		_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))

func _draw() -> void:
	var center = size / 2.0
	var bg_color = Color(0.18, 0.12, 0.06, 0.75) if is_active else Color(0.14, 0.10, 0.06, 0.4)
	
	# Background track ring
	draw_arc(center, radius, 0.0, TAU, 56, bg_color, stroke_width, true)
	
	if not is_active:
		return
		
	var frac = clampf(current_time / max_time, 0.0, 1.0)
	if is_extra_time:
		# Pulsing red indicator ring when in extra time
		var pulse_color = Color(1.0, 0.25, 0.25, 0.9)
		draw_arc(center, radius, 0.0, TAU, 56, pulse_color, stroke_width + 1.0, true)
	elif frac > 0.005:
		var start_angle = -PI / 2.0
		var sweep = frac * TAU
		var end_angle = start_angle + sweep
		
		var arc_color = Color(1.0, 0.85, 0.35, 1.0)
		var glow_color = Color(1.0, 0.75, 0.2, 0.35)
		if current_time <= 3.0:
			arc_color = Color(1.0, 0.38, 0.12, 1.0)
			glow_color = Color(1.0, 0.25, 0.1, 0.45)
			
		# Soft glow
		draw_arc(center, radius, start_angle, end_angle, 56, glow_color, stroke_width + 4.0, true)
		# Sharp main arc
		draw_arc(center, radius, start_angle, end_angle, 56, arc_color, stroke_width, true)
