class_name CircularProgress
extends Control

## Custom antialiased circular progress ring for Win Rate visualization

@export var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, 100.0)
		queue_redraw()

@export var radius: float = 46.0
@export var stroke_width: float = 8.0
@export var bg_color: Color = Color(0.20, 0.14, 0.08, 0.75)
@export var fill_color: Color = Color(0.35, 0.85, 0.40, 1.0)
@export var glow_color: Color = Color(0.35, 0.85, 0.40, 0.28)

func _draw() -> void:
	var center = size / 2.0
	
	# Background track ring
	draw_arc(center, radius, 0.0, TAU, 64, bg_color, stroke_width, true)
	
	# Progress arc
	if value > 0.01:
		var start_angle = -PI / 2.0
		var sweep = (value / 100.0) * TAU
		var end_angle = start_angle + sweep
		
		# Glow outline
		draw_arc(center, radius, start_angle, end_angle, 64, glow_color, stroke_width + 5.0, true)
		# Crisp main arc
		draw_arc(center, radius, start_angle, end_angle, 64, fill_color, stroke_width, true)
