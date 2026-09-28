extends Node

## CaptureEffectManager Singleton
## Manages multi-level capture visual effects (VFX), expanding shockwave rings,
## sparkle particles, floating combo badges, sound pitch modulation, and extensible cosmetic effect themes.

# Extensible Effect Themes for future Shop / Cosmetic purchases
const THEMES: Dictionary = {
	"classic_gold": {
		"id": "classic_gold",
		"name": "Classic Gold",
		"p1_color": Color(1.0, 0.42, 0.35, 1.0), # Warm ruby
		"p2_color": Color(1.0, 0.88, 0.42, 1.0), # Golden ivory
		"ring_color": Color(1.0, 0.86, 0.40, 0.88),
		"combo_color": Color(1.0, 0.92, 0.45, 1.0),
		"outline_color": Color(0.18, 0.10, 0.02, 0.95),
		"particle_texture": "res://assets/textures/particle_sparkle.png"
	},
	"ruby_blaze": {
		"id": "ruby_blaze",
		"name": "Ruby Blaze",
		"p1_color": Color(1.0, 0.22, 0.18, 1.0),
		"p2_color": Color(1.0, 0.50, 0.20, 1.0),
		"ring_color": Color(1.0, 0.32, 0.18, 0.92),
		"combo_color": Color(1.0, 0.45, 0.25, 1.0),
		"outline_color": Color(0.25, 0.04, 0.02, 0.95),
		"particle_texture": "res://assets/textures/particle_sparkle.png"
	},
	"emerald_mystic": {
		"id": "emerald_mystic",
		"name": "Emerald Mystic",
		"p1_color": Color(0.20, 0.95, 0.60, 1.0),
		"p2_color": Color(0.40, 1.0, 0.75, 1.0),
		"ring_color": Color(0.25, 0.92, 0.55, 0.90),
		"combo_color": Color(0.35, 1.0, 0.70, 1.0),
		"outline_color": Color(0.02, 0.20, 0.10, 0.95),
		"particle_texture": "res://assets/textures/particle_sparkle.png"
	},
	"royal_amethyst": {
		"id": "royal_amethyst",
		"name": "Royal Amethyst",
		"p1_color": Color(0.82, 0.40, 1.0, 1.0),
		"p2_color": Color(0.92, 0.60, 1.0, 1.0),
		"ring_color": Color(0.78, 0.35, 0.98, 0.90),
		"combo_color": Color(0.90, 0.65, 1.0, 1.0),
		"outline_color": Color(0.18, 0.02, 0.25, 0.95),
		"particle_texture": "res://assets/textures/particle_sparkle.png"
	}
}

const SPARKLE_TEXTURE = preload("res://assets/textures/particle_sparkle.png")

## Custom CanvasItem Node for rendering smooth hardware-accelerated shockwave rings
class ShockwaveRing extends Node2D:
	var current_radius: float = 8.0
	var max_radius: float = 45.0
	var ring_color: Color = Color(1.0, 0.86, 0.40, 0.88)
	var line_width: float = 3.2
	var fade_alpha: float = 1.0
	var has_rays: bool = false
	var ray_count: int = 8
	var ray_length: float = 14.0

	func _draw() -> void:
		var c = Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * fade_alpha)
		if current_radius > 1.0 and line_width > 0.1:
			draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, c, line_width, true)
		
		# For Level 3: Radiant glint spikes radiating outwards
		if has_rays and current_radius > 15.0:
			var ray_c = Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * fade_alpha * 0.75)
			for i in range(ray_count):
				var angle = (TAU / float(ray_count)) * float(i)
				var dir = Vector2(cos(angle), sin(angle))
				var p_start = dir * (current_radius - 4.0)
				var p_end = dir * (current_radius + ray_length * fade_alpha)
				draw_line(p_start, p_end, ray_c, line_width * 0.75, true)

## Triggers multi-level capture visual effects at the specified position
func play_capture_effect(parent: Node2D, at_pos: Vector2, level: int = 1, captured_player: int = BoardData.Player.NONE) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var theme = get_active_theme()
	var bounded_level = clampi(level, 1, 4)

	# 1. Spawn Shockwave Ring(s)
	_spawn_shockwave(parent, at_pos, bounded_level, theme)

	# 2. Spawn Particle Burst
	_spawn_particles(parent, at_pos, bounded_level, theme, captured_player)

	# 3. Spawn Floating Combo Badge (for Level 2 and above)
	if bounded_level >= 2:
		_spawn_combo_badge(parent, at_pos, bounded_level, theme)

	# 4. Modulate SFX Pitch per Level
	var pitch = 1.0
	if bounded_level == 2:
		pitch = 1.18
	elif bounded_level >= 3:
		pitch = 1.32
	AudioManager.play_sfx("capture", pitch)

	# 5. Tactile Haptic Pattern per Level
	HapticManager.vibrate_combo(bounded_level)

## Spawns expanding shockwave ring(s) based on capture level
func _spawn_shockwave(parent: Node2D, at_pos: Vector2, level: int, theme: Dictionary) -> void:
	var ring_col = theme.get("ring_color", Color(1.0, 0.86, 0.40, 0.88))
	
	if level == 1:
		# Single clean shockwave ring (normal, grounded effect)
		var ring = ShockwaveRing.new()
		ring.position = at_pos
		ring.max_radius = 42.0
		ring.ring_color = ring_col
		ring.line_width = 3.0
		parent.add_child(ring)
		_animate_ring(ring, 42.0, 0.32)
	elif level == 2:
		# Double expanding shockwave ring
		var ring1 = ShockwaveRing.new()
		ring1.position = at_pos
		ring1.max_radius = 58.0
		ring1.ring_color = ring_col
		ring1.line_width = 3.5
		parent.add_child(ring1)
		_animate_ring(ring1, 58.0, 0.38)
		
		# Staggered second ring
		var t = get_tree().create_timer(0.07)
		t.timeout.connect(func():
			if not is_instance_valid(parent): return
			var ring2 = ShockwaveRing.new()
			ring2.position = at_pos
			ring2.max_radius = 44.0
			ring2.ring_color = ring_col.lightened(0.15)
			ring2.line_width = 2.6
			parent.add_child(ring2)
			_animate_ring(ring2, 44.0, 0.32)
		)
	else:
		# Level 3+: Radiant shockwave ring with glint rays
		var ring1 = ShockwaveRing.new()
		ring1.position = at_pos
		ring1.max_radius = 74.0
		ring1.ring_color = ring_col
		ring1.line_width = 4.0
		ring1.has_rays = true
		ring1.ray_count = 8
		ring1.ray_length = 16.0
		parent.add_child(ring1)
		_animate_ring(ring1, 74.0, 0.42)
		
		var t = get_tree().create_timer(0.06)
		t.timeout.connect(func():
			if not is_instance_valid(parent): return
			var ring2 = ShockwaveRing.new()
			ring2.position = at_pos
			ring2.max_radius = 52.0
			ring2.ring_color = ring_col.lightened(0.20)
			ring2.line_width = 3.0
			parent.add_child(ring2)
			_animate_ring(ring2, 52.0, 0.36)
		)

func _animate_ring(ring: ShockwaveRing, target_radius: float, duration: float) -> void:
	var tw = ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "current_radius", target_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "fade_alpha", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(ring, "line_width", 0.5, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Periodically redraw during tween
	var step_tween = ring.create_tween().set_loops(int(duration * 60.0))
	step_tween.tween_callback(ring.queue_redraw).set_delay(0.016)
	
	tw.chain().tween_callback(func():
		ring.queue_free()
	)

## Spawns sparkle particles scaled cleanly per level
func _spawn_particles(parent: Node2D, at_pos: Vector2, level: int, theme: Dictionary, captured_player: int) -> void:
	var part = CPUParticles2D.new()
	part.texture = SPARKLE_TEXTURE
	part.position = at_pos
	part.one_shot = true
	part.explosiveness = 0.90
	part.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	part.emission_sphere_radius = 16.0
	part.spread = 180.0
	part.gravity = Vector2(0, 35.0)
	
	# Color based on theme and captured player
	var p_color: Color = theme.get("p2_color", Color(1.0, 0.88, 0.42, 1.0))
	if captured_player == BoardData.Player.PLAYER_1:
		p_color = theme.get("p1_color", Color(1.0, 0.42, 0.35, 1.0))
	part.color = p_color
	
	if level == 1:
		part.amount = 14
		part.lifetime = 0.36
		part.initial_velocity_min = 60.0
		part.initial_velocity_max = 110.0
		part.scale_amount_min = 0.35
		part.scale_amount_max = 0.60
	elif level == 2:
		part.amount = 24
		part.lifetime = 0.42
		part.initial_velocity_min = 80.0
		part.initial_velocity_max = 145.0
		part.scale_amount_min = 0.40
		part.scale_amount_max = 0.72
	else:
		part.amount = 36
		part.lifetime = 0.48
		part.initial_velocity_min = 100.0
		part.initial_velocity_max = 180.0
		part.scale_amount_min = 0.45
		part.scale_amount_max = 0.85

	parent.add_child(part)
	part.emitting = true
	
	# Auto free after lifetime
	var free_timer = get_tree().create_timer(part.lifetime + 0.15)
	free_timer.timeout.connect(func():
		if is_instance_valid(part):
			part.queue_free()
	)

## Spawns stylized combo floating text ("2x COMBO!", "3x TRIPLE COMBO!")
func _spawn_combo_badge(parent: Node2D, at_pos: Vector2, level: int, theme: Dictionary) -> void:
	var label = Label.new()
	var text_str = "2x COMBO!"
	if level == 3:
		text_str = "3x TRIPLE COMBO!"
	elif level >= 4:
		text_str = "%dx MEGA COMBO!" % level
		
	label.text = text_str
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var combo_col = theme.get("combo_color", Color(1.0, 0.92, 0.45, 1.0))
	var outline_col = theme.get("outline_color", Color(0.18, 0.10, 0.02, 0.95))
	
	var font_size = 28 if level == 2 else 32
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", combo_col)
	label.add_theme_color_override("font_outline_color", outline_col)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 2)
	
	label.size = Vector2(240, 40)
	# Center anchor
	label.pivot_offset = Vector2(120, 20)
	label.position = at_pos + Vector2(-120, -32)
	label.scale = Vector2(0.5, 0.5)
	label.z_index = 80
	
	parent.add_child(label)
	
	var tw = label.create_tween().set_parallel(true)
	# Punchy pop-in bounce
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Gentle rise upward
	tw.tween_property(label, "position:y", label.position.y - 36.0, 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Smooth fade out towards the end
	var fade_tw = label.create_tween()
	fade_tw.tween_interval(0.38)
	fade_tw.tween_property(label, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD)
	
	fade_tw.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

## Returns the active theme dictionary based on player settings
func get_active_theme() -> Dictionary:
	var sm = get_node_or_null("/root/SaveManager")
	var theme_id = "classic_gold"
	if sm and sm.settings and not sm.settings.capture_effect_theme.is_empty():
		theme_id = sm.settings.capture_effect_theme
	return THEMES.get(theme_id, THEMES["classic_gold"])

## Future Shop support: Retrieves all available effects for purchasing / equipping
func get_available_themes() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in THEMES.keys():
		list.append(THEMES[k])
	return list

## Future Shop support: Sets and persists the selected effect theme
func set_active_theme(theme_id: String) -> void:
	if THEMES.has(theme_id):
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.settings:
			sm.settings.capture_effect_theme = theme_id
			sm.save_data()
