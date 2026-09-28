class_name RadialTurnTimer
extends Control

## Radial circular watch icon timer with center numeric countdown (10s normal turn timer).
## Designed with classic pocket-watch styling: top winder crown & loop, metallic gold bezel,
## 12 hour dial ticks, sweeping countdown arc, and crisp central countdown seconds.

@export var max_time: float = 10.0:
	set(v):
		max_time = maxf(1.0, v)
		queue_redraw()

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

@export var radius: float = 30.0
@export var stroke_width: float = 5.0

var _label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(82, 86)
	
	_label = Label.new()
	_label.name = "SecondsLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	add_child(_label)
	_layout_label()
	_update_label()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_label()

func _layout_label() -> void:
	if not _label:
		return
	var center = Vector2(size.x * 0.5, size.y * 0.5 + 5.0)
	_label.position = center - Vector2(radius, radius)
	_label.size = Vector2(radius * 2.0, radius * 2.0)

func _update_label() -> void:
	if not _label:
		return
		
	var secs = int(ceil(current_time))
	_label.text = "%02d" % max(0, secs)
	
	if not is_active:
		_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.45, 0.45))
	elif is_extra_time:
		_label.text = "00"
		_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif secs <= 3:
		_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.15))
	else:
		_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))

func _draw() -> void:
	var center = Vector2(size.x * 0.5, size.y * 0.5 + 5.0)
	
	# 1. Top Crown (Stopwatch / Pocket watch winder knob)
	var crown_y = center.y - radius - 5.0
	var crown_col = Color(0.92, 0.78, 0.4, 0.95) if is_active else Color(0.55, 0.45, 0.3, 0.45)
	var crown_hl = Color(1.0, 0.92, 0.65, 0.95) if is_active else Color(0.65, 0.55, 0.4, 0.45)
	
	# Top arch ring/loop
	draw_arc(Vector2(center.x, crown_y - 9.0), 5.5, -PI * 0.88, -PI * 0.12, 16, crown_col, 2.0)
	# Stem
	draw_rect(Rect2(center.x - 3.0, crown_y - 4.5, 6.0, 5.0), crown_col)
	# Cap button
	draw_line(Vector2(center.x - 6.0, crown_y - 5.5), Vector2(center.x + 6.0, crown_y - 5.5), crown_hl, 2.5)
	
	# 2. Outer Bezel & Case Rim (Polished metallic watch casing)
	var bezel_col = Color(0.9, 0.75, 0.35, 0.95) if is_active else Color(0.48, 0.38, 0.25, 0.5)
	var case_bg = Color(0.08, 0.05, 0.02, 0.92)
	draw_circle(center, radius + 4.0, case_bg)
	draw_arc(center, radius + 4.0, 0.0, TAU, 56, bezel_col, 2.5)
	draw_arc(center, radius + 1.5, 0.0, TAU, 56, Color(0.2, 0.14, 0.08, 0.8), 1.5)
	
	# 3. Dial Face background (Dark obsidian glass)
	draw_circle(center, radius, Color(0.12, 0.08, 0.04, 0.95))
	
	# 4. 12 Hour Tick Marks around the watch dial
	var tick_col = Color(0.9, 0.78, 0.45, 0.75) if is_active else Color(0.5, 0.4, 0.28, 0.35)
	for i in range(12):
		var ang = (float(i) / 12.0) * TAU - PI * 0.5
		var dir = Vector2(cos(ang), sin(ang))
		var outer_pt = center + dir * (radius - 1.5)
		var is_cardinal = (i % 3 == 0)
		var tick_len = 5.0 if is_cardinal else 3.0
		var inner_pt = center + dir * (radius - 1.5 - tick_len)
		var tick_w = 1.8 if is_cardinal else 1.1
		draw_line(inner_pt, outer_pt, tick_col, tick_w)
		
	# 5. Background track ring for timer
	var track_col = Color(0.25, 0.17, 0.1, 0.45)
	var arc_radius = radius - 5.5
	draw_arc(center, arc_radius, 0.0, TAU, 56, track_col, stroke_width)
	
	if not is_active:
		return
		
	var frac = clampf(current_time / max_time, 0.0, 1.0)
	
	if is_extra_time:
		# Pulsing red ring when in extra time
		var pulse_color = Color(1.0, 0.25, 0.25, 0.9)
		draw_arc(center, arc_radius, 0.0, TAU, 56, pulse_color, stroke_width + 0.5, true)
	elif frac > 0.005:
		var start_angle = -PI * 0.5
		var sweep = frac * TAU
		var end_angle = start_angle + sweep
		
		var arc_color = Color(1.0, 0.88, 0.38, 1.0)
		var glow_color = Color(1.0, 0.78, 0.25, 0.4)
		if current_time <= 3.0:
			arc_color = Color(1.0, 0.35, 0.1, 1.0)
			glow_color = Color(1.0, 0.22, 0.08, 0.5)
			
		# Soft glow underlay
		draw_arc(center, arc_radius, start_angle, end_angle, 56, glow_color, stroke_width + 3.5, true)
		# Sharp main arc
		draw_arc(center, arc_radius, start_angle, end_angle, 56, arc_color, stroke_width, true)
