class_name CardPerimeterProgressBar
extends Control

## CardPerimeterProgressBar
## Draws a rounded-rectangle perimeter progress bar tracing the outer border of a profile card.
## Dynamically tracks the player's 5-minute (300-second) personal extra time bank.
## Recedes clockwise from top-center as extra time is depleted.
## Glows vibrant gold/amber normally, pulses coral/red when <= 60 seconds remain.

@export var max_time: float = 300.0:
	set(v):
		max_time = maxf(1.0, v)
		queue_redraw()

@export var current_time: float = 300.0:
	set(v):
		var old_v = current_time
		current_time = clampf(v, 0.0, max_time)
		if absf(current_time - old_v) > 0.01:
			queue_redraw()

@export var is_active: bool = false:
	set(v):
		is_active = v
		queue_redraw()

@export var is_extra_time: bool = false:
	set(v):
		is_extra_time = v
		queue_redraw()

@export var corner_radius: float = 20.0
@export var stroke_width: float = 4.5
@export var player_color: Color = Color(1.0, 0.84, 0.35, 1.0)
@export var warning_color: Color = Color(1.0, 0.26, 0.22, 1.0)
@export var track_color: Color = Color(0.25, 0.16, 0.09, 0.55)

var _pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if is_active and is_extra_time:
		_pulse_time += delta * 4.0
		queue_redraw()

func _draw() -> void:
	if size.x <= 10.0 or size.y <= 10.0:
		return
		
	var inset = stroke_width * 0.5
	var w = size.x - stroke_width
	var h = size.y - stroke_width
	var r = clampf(corner_radius - inset, 2.0, minf(w, h) * 0.5)
	var x0 = inset
	var y0 = inset
	var x1 = size.x - inset
	var y1 = size.y - inset
	
	# Build rounded rectangle polyline starting from Top-Center going clockwise
	var pts = PackedVector2Array()
	var top_mid = Vector2(x0 + w * 0.5, y0)
	pts.append(top_mid)
	
	# 1. Top right edge
	pts.append(Vector2(x1 - r, y0))
	
	# 2. Top-right arc (angles -PI/2 to 0)
	var tr_center = Vector2(x1 - r, y0 + r)
	for i in range(1, 9):
		var ang = -PI * 0.5 + (PI * 0.5) * (float(i) / 8.0)
		pts.append(tr_center + Vector2(cos(ang), sin(ang)) * r)
		
	# 3. Right edge
	pts.append(Vector2(x1, y1 - r))
	
	# 4. Bottom-right arc (angles 0 to PI/2)
	var br_center = Vector2(x1 - r, y1 - r)
	for i in range(1, 9):
		var ang = 0.0 + (PI * 0.5) * (float(i) / 8.0)
		pts.append(br_center + Vector2(cos(ang), sin(ang)) * r)
		
	# 5. Bottom edge
	pts.append(Vector2(x0 + r, y1))
	
	# 6. Bottom-left arc (angles PI/2 to PI)
	var bl_center = Vector2(x0 + r, y1 - r)
	for i in range(1, 9):
		var ang = PI * 0.5 + (PI * 0.5) * (float(i) / 8.0)
		pts.append(bl_center + Vector2(cos(ang), sin(ang)) * r)
		
	# 7. Left edge
	pts.append(Vector2(x0, y0 + r))
	
	# 8. Top-left arc (angles PI to 3*PI/2)
	var tl_center = Vector2(x0 + r, y0 + r)
	for i in range(1, 9):
		var ang = PI + (PI * 0.5) * (float(i) / 8.0)
		pts.append(tl_center + Vector2(cos(ang), sin(ang)) * r)
		
	# 9. Back to top mid
	pts.append(top_mid)
	
	# 1. Draw subtle background track along complete perimeter
	draw_polyline(pts, track_color, stroke_width, false)
	
	# 2. Compute fraction
	var frac = clampf(current_time / max_time, 0.0, 1.0)
	if frac <= 0.002:
		return # Empty bank
		
	# Compute segment lengths and total length
	var seg_lens = PackedFloat32Array()
	var total_len: float = 0.0
	for i in range(pts.size() - 1):
		var d = pts[i].distance_to(pts[i + 1])
		seg_lens.append(d)
		total_len += d
		
	var target_len = frac * total_len
	var active_pts = PackedVector2Array()
	active_pts.append(pts[0])
	var cur_dist: float = 0.0
	var final_pt: Vector2 = pts[0]
	
	for i in range(seg_lens.size()):
		var seg_l = seg_lens[i]
		if cur_dist + seg_l < target_len:
			cur_dist += seg_l
			active_pts.append(pts[i + 1])
			final_pt = pts[i + 1]
		else:
			var remain = target_len - cur_dist
			var t = clampf(remain / seg_l, 0.0, 1.0) if seg_l > 0.0001 else 0.0
			final_pt = pts[i].lerp(pts[i + 1], t)
			active_pts.append(final_pt)
			break
			
	if active_pts.size() < 2:
		return
		
	# Select color scheme:
	var col = player_color
	if current_time <= 60.0:
		# Urgent <= 1 minute warning
		col = warning_color
		if is_active and is_extra_time:
			# Pulse alpha in last minute
			var pulse = 0.78 + 0.22 * sin(_pulse_time)
			col.a *= pulse
	elif not is_active:
		col.a = 0.45
	else:
		col.a = 0.95
		
	# Draw glow layer
	var glow_col = Color(col.r, col.g, col.b, col.a * 0.4)
	draw_polyline(active_pts, glow_col, stroke_width + 4.0, false)
	
	# Draw primary sharp line
	draw_polyline(active_pts, col, stroke_width, false)
	
	# Draw glowing tip head when actively in extra time
	if is_active and is_extra_time and frac > 0.005:
		var tip_r = stroke_width * 1.35
		draw_circle(final_pt, tip_r + 2.5, glow_col)
		draw_circle(final_pt, tip_r, Color(1.0, 1.0, 1.0, col.a))
