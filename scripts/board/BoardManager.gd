class_name BoardManager
extends Node2D

## BoardManager handles board visuals, engraved lines, node placement,
## piece tracking, animations, and input routing.

const BOARD_NODE_SCENE = preload("res://scenes/BoardNode.tscn")
const PIECE_SCENE = preload("res://scenes/Piece.tscn")

# Grid spacing configuration (centered for 1080x1920 portrait)
const BOARD_CENTER: Vector2 = Vector2(540, 960)
const CELL_DX: float = 170.0
const CELL_DY: float = 135.0

var nodes: Dictionary = {} # node_id -> BoardNode
var pieces: Dictionary = {} # node_id -> Piece

var selected_node_id: int = -1
var current_legal_moves: Array[Dictionary] = []
var is_animating: bool = false
var debug_mode: bool = false

@onready var lines_canvas: Node2D = $LinesCanvas
@onready var nodes_container: Node2D = $NodesContainer
@onready var pieces_container: Node2D = $PiecesContainer

signal piece_selected(node_id: int)
signal piece_deselected()
signal move_executed(move: Dictionary)
signal swipe_turn_completed(swipe_steps: Array)
signal invalid_tap()
signal invalid_tap_info(reason: String)

var is_swiping_capture: bool = false
var swipe_start_node: int = -1
var swipe_current_node: int = -1
var swipe_captured_nodes: Array[int] = []
var swipe_steps: Array[Dictionary] = []

var _last_interaction_frame: int = -1
var _last_interaction_node: int = -1

var current_hint_move: Dictionary = {}
var current_capture_chain_level: int = 1
var _start_anim_tween: Tween

func _ready() -> void:
	set_process_unhandled_input(true)
	_create_board_nodes()
	apply_theme(SaveManager.settings.board_theme)
	lines_canvas.queue_redraw()

func set_board_center_and_scale(center: Vector2, board_scale: float) -> void:
	position = center - Vector2(540, 960) * board_scale
	scale = Vector2(board_scale, board_scale)

func apply_theme(theme_id: String) -> void:
	var wood_path = "res://assets/textures/board_wood_classic.jpg"
	match theme_id:
		"royal_mahogany":
			wood_path = "res://assets/textures/board_wood_mahogany.jpg"
		"ivory_maple":
			wood_path = "res://assets/textures/board_wood_light.jpg"
		"royal_marble":
			wood_path = "res://assets/textures/theme_royal_marble.jpg"
		"dark_mystic":
			wood_path = "res://assets/textures/theme_dark_mystic.jpg"
		"golden_palace":
			wood_path = "res://assets/textures/theme_golden_palace.jpg"
		"green_forest":
			wood_path = "res://assets/textures/theme_green_forest.jpg"
		_:
			wood_path = "res://assets/textures/board_wood_classic.jpg"
			
	var tex = load(wood_path)
	if tex:
		if has_node("BoardWoodSprite"):
			$BoardWoodSprite.texture = tex
		if has_node("BoardWoodShadow"):
			if theme_id == "ivory_maple":
				$BoardWoodShadow.modulate = Color(0, 0, 0, 0.28)
			else:
				$BoardWoodShadow.modulate = Color(0, 0, 0, 0.45)
				
	if lines_canvas and lines_canvas.has_method("apply_theme"):
		lines_canvas.apply_theme(theme_id)

# Calculate screen position from grid coordinate (col: 0..4, row: 0..8)
static func get_node_position(col: int, row: int) -> Vector2:
	return BoardData.get_node_position(col, row)

## Calculate minimum adjacent node distance dynamically from board geometry
static func get_min_node_distance() -> float:
	return min(CELL_DX, CELL_DY)

## Calculate target piece radius: ~58% of minimum node spacing (in 55–65% range)
static func get_target_piece_radius() -> float:
	return get_min_node_distance() * 0.29

func _create_board_nodes() -> void:
	var target_radius = get_target_piece_radius()
	for node_id in range(BoardData.TOTAL_NODES):
		var coord = BoardData.NODE_COORDINATES[node_id]
		var pos = get_node_position(coord.x, coord.y)
		
		var b_node: BoardNode = BOARD_NODE_SCENE.instantiate()
		b_node.setup(node_id, coord, pos)
		b_node.set_node_radius(target_radius)
		b_node.clicked.connect(_on_node_clicked)
		nodes_container.add_child(b_node)
		nodes[node_id] = b_node

func populate_pieces_from_state(state: GameState) -> void:
	if _start_anim_tween:
		_start_anim_tween.kill()
		
	# Clear all child pieces from container to guarantee no orphaned/ghost pieces
	for child in pieces_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	pieces.clear()
	clear_selection()
	
	for node_id in range(BoardData.TOTAL_NODES):
		var p_type = state.get_piece(node_id)
		if p_type != BoardData.Player.NONE:
			_spawn_piece(p_type, node_id)

func reset_all_piece_visuals() -> void:
	if _start_anim_tween:
		_start_anim_tween.kill()
	is_animating = false
	clear_selection()
	is_drag_active = false
	dragged_piece = null
	
	for node_id in pieces.keys():
		var p: Piece = pieces[node_id]
		if is_instance_valid(p):
			p.reset_visual()
			
	# Remove any stale orphaned pieces in pieces_container
	for child in pieces_container.get_children():
		if not pieces.values().has(child):
			child.queue_free()
			
	for b_node in nodes.values():
		if is_instance_valid(b_node):
			b_node.set_highlight(BoardNode.HighlightType.NONE)

func play_match_start_animation(on_complete: Callable = Callable()) -> void:
	if _start_anim_tween:
		_start_anim_tween.kill()
	is_animating = true
	clear_selection()
	
	_start_anim_tween = create_tween().set_parallel(true)
	var count = 0
	for node_id in pieces.keys():
		var p: Piece = pieces[node_id]
		if is_instance_valid(p):
			var orig_pos = p.position
			p.position = orig_pos + Vector2(0, -50)
			p.modulate.a = 0.0
			
			var delay = float(count % 8) * 0.032
			_start_anim_tween.tween_property(p, "position", orig_pos, 0.24).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_start_anim_tween.tween_property(p, "modulate:a", 1.0, 0.16).set_delay(delay)
			count += 1
			
	AudioManager.play_sfx("move")
	HapticManager.vibrate_move()
	
	_start_anim_tween.chain().tween_callback(func():
		is_animating = false
		if on_complete.is_valid():
			on_complete.call()
	)

var dragged_piece: Piece = null
var drag_start_pos: Vector2 = Vector2.ZERO
var is_drag_active: bool = false
const DRAG_THRESHOLD: float = 16.0
const NODE_SNAP_RADIUS: float = 85.0

func _spawn_piece(player: int, node_id: int) -> Piece:
	var coord = BoardData.NODE_COORDINATES[node_id]
	var pos = get_node_position(coord.x, coord.y)
	var target_radius = get_target_piece_radius()
	
	var piece: Piece = PIECE_SCENE.instantiate()
	piece.setup(player, node_id, pos)
	piece.set_piece_radius(target_radius)
	piece.piece_clicked.connect(_on_piece_clicked)
	pieces_container.add_child(piece)
	pieces[node_id] = piece
	return piece

func should_show_capture_highlights() -> bool:
	# Only show red capture highlights in single-player VS AI mode.
	# In Local 2P and Multiplayer, capture moves are NOT shown in red (to prevent giving away captures),
	# but are shown as standard valid moves so players can still play them cleanly.
	return GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI

func select_piece_at_node(node_id: int, legal_moves: Array[Dictionary]) -> void:
	if selected_node_id == node_id:
		return
	clear_selection()
	selected_node_id = node_id
	current_legal_moves = legal_moves.duplicate()
	swipe_start_node = node_id
	swipe_current_node = node_id
	swipe_captured_nodes.clear()
	swipe_steps.clear()
	is_swiping_capture = false
	
	if pieces.has(node_id) and is_instance_valid(pieces[node_id]):
		pieces[node_id].set_selected(true)
		AudioManager.play_sfx("select")
		HapticManager.vibrate_selection()
		piece_selected.emit(node_id)
		
	# Highlight valid destination nodes
	var show_caps = should_show_capture_highlights()
	for m in legal_moves:
		var target_id = m["to"]
		if nodes.has(target_id):
			var is_cap = m.get("is_capture", false)
			var hl_type = BoardNode.HighlightType.VALID_CAPTURE if (is_cap and show_caps) else BoardNode.HighlightType.VALID_MOVE
			nodes[target_id].set_highlight(hl_type)

func clear_selection() -> void:
	current_hint_move.clear()
	if dragged_piece and is_instance_valid(dragged_piece) and is_drag_active:
		dragged_piece.snap_back_to_nominal()
	dragged_piece = null
	is_drag_active = false
	is_swiping_capture = false
	
	if selected_node_id >= 0 and pieces.has(selected_node_id) and is_instance_valid(pieces[selected_node_id]):
		pieces[selected_node_id].set_selected(false)
		
	selected_node_id = -1
	current_legal_moves.clear()
	
	for b_node in nodes.values():
		b_node.set_highlight(BoardNode.HighlightType.NONE)
		
	piece_deselected.emit()

func execute_move_visual(move: Dictionary, on_finished: Callable) -> void:
	is_animating = true
	clear_selection()
	
	var from_id = move["from"]
	var to_id = move["to"]
	var is_capture = move["is_capture"]
	var captured_id = move.get("captured", -1)
	
	if not pieces.has(from_id) or not is_instance_valid(pieces[from_id]):
		is_animating = false
		if on_finished.is_valid(): on_finished.call()
		return
		
	var moving_piece: Piece = pieces[from_id]
	pieces.erase(from_id)
	pieces[to_id] = moving_piece
	
	var target_pos = get_node_position(BoardData.NODE_COORDINATES[to_id].x, BoardData.NODE_COORDINATES[to_id].y)
	
	moving_piece.animate_move_to(target_pos, to_id, func():
		if is_capture and captured_id >= 0 and pieces.has(captured_id) and is_instance_valid(pieces[captured_id]):
			var cap_piece: Piece = pieces[captured_id]
			var cap_pos = cap_piece.position
			var cap_player = cap_piece.player_owner
			pieces.erase(captured_id)
			
			var level = current_capture_chain_level
			CaptureEffectManager.play_capture_effect(self, cap_pos, level, cap_player)
			
			cap_piece.animate_captured(func():
				is_animating = false
				if on_finished.is_valid(): on_finished.call()
			)
		else:
			AudioManager.play_sfx("move")
			HapticManager.vibrate_move()
			is_animating = false
			if on_finished.is_valid(): on_finished.call()
	)

func _unhandled_input(event: InputEvent) -> void:
	var state = GameManager.current_state
	if not GameManager.is_playing() or state == null or is_animating:
		return
	if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI and state.active_player == BoardData.Player.PLAYER_2:
		return

	# 1. Pressed down (Mouse click or Touch)
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		var click_pos = to_local(event.position)
		var clicked_node = _find_closest_node(click_pos, 85.0)
		if clicked_node >= 0:
			_handle_node_press(clicked_node, click_pos)
			get_viewport().set_input_as_handled()
		else:
			if selected_node_id >= 0:
				clear_selection()
				get_viewport().set_input_as_handled()

	# 2. Motion / Dragging
	elif (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)) or event is InputEventScreenDrag:
		if dragged_piece != null and is_instance_valid(dragged_piece):
			var curr_pos = to_local(event.position)
			if not is_drag_active and curr_pos.distance_to(drag_start_pos) > DRAG_THRESHOLD:
				is_drag_active = true
				dragged_piece.start_drag()
			if is_drag_active:
				dragged_piece.update_drag_position(curr_pos)
				_check_mid_drag_capture(curr_pos)
				get_viewport().set_input_as_handled()

	# 3. Released
	elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) or (event is InputEventScreenTouch and not event.pressed):
		var release_pos = to_local(event.position)
		_finish_drag(release_pos)

func _check_mid_drag_capture(curr_pos: Vector2) -> void:
	if dragged_piece == null or not is_instance_valid(dragged_piece):
		return
	var state = GameManager.current_state
	if state == null:
		return
		
	var captures = RulesEngine.get_captures_for_piece(state, swipe_current_node)
	if captures.is_empty():
		return
		
	for m in captures:
		var to_node = m["to"]
		var cap_node = m["captured"]
		var target_pos = get_node_position(BoardData.NODE_COORDINATES[to_node].x, BoardData.NODE_COORDINATES[to_node].y)
		
		# If user dragged within capture snap radius (68px)
		if curr_pos.distance_to(target_pos) < 68.0:
			# Execute mid-swipe jump step!
			is_swiping_capture = true
			swipe_steps.append(m)
			swipe_captured_nodes.append(cap_node)
			var capture_level = swipe_steps.size()
			
			# 1. Animate and remove captured piece with tiered VFX & SFX
			if pieces.has(cap_node) and is_instance_valid(pieces[cap_node]):
				var cap_piece: Piece = pieces[cap_node]
				var cap_pos = cap_piece.position
				var cap_player = cap_piece.player_owner
				pieces.erase(cap_node)
				cap_piece.animate_captured()
				
				# Trigger tiered visual effects, audio pitch modulation, and combo haptics!
				CaptureEffectManager.play_capture_effect(self, cap_pos, capture_level, cap_player)
				
			# 2. Update logical game state
			state.set_piece(swipe_current_node, BoardData.Player.NONE)
			state.set_piece(to_node, state.active_player)
			state.set_piece(cap_node, BoardData.Player.NONE)
			
			if state.active_player == BoardData.Player.PLAYER_1:
				state.p2_pieces = maxi(0, state.p2_pieces - 1)
				GameManager.p1_match_captures += 1
			else:
				state.p1_pieces = maxi(0, state.p1_pieces - 1)
				GameManager.p2_match_captures += 1
				
			# 3. Update pieces dictionary and dragged piece internal node
			pieces.erase(swipe_current_node)
			pieces[to_node] = dragged_piece
			dragged_piece.current_node_id = to_node
			swipe_current_node = to_node
			
			# 4. Update HUD scores immediately
			var hud = get_tree().root.find_child("GameHUD", true, false)
			if hud:
				hud.update_hud(state)
				
			# 6. Check for further chain captures from new node
			var further = RulesEngine.get_captures_for_piece(state, swipe_current_node)
			for b_node in nodes.values():
				b_node.set_highlight(BoardNode.HighlightType.NONE)
				
			if further.size() > 0:
				current_legal_moves = further
				var show_caps = should_show_capture_highlights()
				for next_m in further:
					var next_to = next_m["to"]
					if nodes.has(next_to):
						var hl = BoardNode.HighlightType.VALID_CAPTURE if show_caps else BoardNode.HighlightType.VALID_MOVE
						nodes[next_to].set_highlight(hl)
			else:
				current_legal_moves.clear()
				
			break

func _finish_drag(release_pos: Vector2) -> void:
	if dragged_piece == null or not is_instance_valid(dragged_piece):
		dragged_piece = null
		is_drag_active = false
		is_swiping_capture = false
		return
		
	var p = dragged_piece
	dragged_piece = null
	
	if not GameManager.is_playing():
		is_drag_active = false
		is_swiping_capture = false
		p.snap_back_to_nominal()
		return
		
	# CASE 1: Piece(s) were captured via swipe!
	# "And drag kore jekhane release kore debe, sekhanei or end hoye jabe."
	# "jekhane release kore debe, sekhanei o sesh hoye jabe."
	if is_swiping_capture:
		is_drag_active = false
		is_swiping_capture = false
		
		var final_node = swipe_current_node
		var final_pos = get_node_position(BoardData.NODE_COORDINATES[final_node].x, BoardData.NODE_COORDINATES[final_node].y)
		p.settle_at_node(final_pos, final_node)
		clear_selection()
		
		# Turn ENDS IMMEDIATELY wherever released!
		swipe_turn_completed.emit(swipe_steps)
		return
		
	# CASE 2: REGULAR DRAG & DROP (no mid-drag capture happened)
	if is_drag_active:
		is_drag_active = false
		var best_node = _find_closest_node(release_pos, NODE_SNAP_RADIUS)
		if best_node >= 0:
			for m in current_legal_moves:
				if m["to"] == best_node or (m["is_capture"] and m.get("captured", -1) == best_node):
					move_executed.emit(m)
					return
					
		# If drop was not valid, smoothly snap back to starting node
		p.snap_back_to_nominal()
		AudioManager.play_sfx("invalid")
		HapticManager.vibrate_invalid()
	else:
		# Just a tap
		pass

func _handle_node_press(node_id: int, press_pos: Vector2) -> void:
	var curr_frame = Engine.get_process_frames()
	if curr_frame == _last_interaction_frame and node_id == _last_interaction_node:
		return
	_last_interaction_frame = curr_frame
	_last_interaction_node = node_id
	
	var state = GameManager.current_state
	if not GameManager.is_playing() or state == null or is_animating:
		return
		
	# CASE 1: A piece is already selected
	if selected_node_id >= 0:
		# If clicked the exact same piece again:
		if node_id == selected_node_id:
			# If this was a hinted move, clicking the piece again executes the hint move directly!
			if not current_hint_move.is_empty() and current_hint_move.get("from", -1) == node_id:
				var m = current_hint_move
				current_hint_move = {}
				move_executed.emit(m)
				return
			dragged_piece = pieces.get(node_id, null)
			drag_start_pos = press_pos
			is_drag_active = false
			return
			
		# Check if clicking a valid destination node
		for m in current_legal_moves:
			if m["to"] == node_id:
				move_executed.emit(m)
				return
				
		# Check if clicking an opponent piece to jump/capture it
		for m in current_legal_moves:
			if m["is_capture"] and m.get("captured", -1) == node_id:
				move_executed.emit(m)
				return
				
		# Check if clicking ANOTHER of player's OWN pieces -> switch selection to that piece!
		var clicked_owner = state.get_piece(node_id)
		if clicked_owner == state.active_player:
			if state.is_in_multi_capture and node_id != state.multi_capture_node:
				if pieces.has(node_id): pieces[node_id].shake()
				AudioManager.play_sfx("invalid")
				HapticManager.vibrate_invalid()
				invalid_tap_info.emit("Must continue jumping with the active piece!")
				invalid_tap.emit()
				return
				
			var moves = RulesEngine.get_legal_moves_for_piece(state, node_id, SaveManager.settings.forced_capture)
			if moves.size() > 0:
				select_piece_at_node(node_id, moves)
				dragged_piece = pieces.get(node_id, null)
				drag_start_pos = press_pos
				is_drag_active = false
			else:
				if pieces.has(node_id): pieces[node_id].shake()
				AudioManager.play_sfx("invalid")
				HapticManager.vibrate_invalid()
				invalid_tap_info.emit("This piece is blocked! Select a front piece.")
				clear_selection()
				invalid_tap.emit()
			return
			
		# Clicked invalid destination or non-capturable opponent piece
		clear_selection()
		return
		
	# CASE 2: No piece is selected yet
	var piece_owner = state.get_piece(node_id)
	if piece_owner == state.active_player:
		if state.is_in_multi_capture and node_id != state.multi_capture_node:
			if pieces.has(node_id): pieces[node_id].shake()
			AudioManager.play_sfx("invalid")
			HapticManager.vibrate_invalid()
			invalid_tap_info.emit("Must continue jumping with the active piece!")
			invalid_tap.emit()
			return
			
		var moves = RulesEngine.get_legal_moves_for_piece(state, node_id, SaveManager.settings.forced_capture)
		if moves.size() > 0:
			select_piece_at_node(node_id, moves)
			dragged_piece = pieces.get(node_id, null)
			drag_start_pos = press_pos
			is_drag_active = false
		else:
			if pieces.has(node_id): pieces[node_id].shake()
			AudioManager.play_sfx("invalid")
			HapticManager.vibrate_invalid()
			invalid_tap_info.emit("This piece is blocked! Select a front piece.")
			clear_selection()
			invalid_tap.emit()
	else:
		if piece_owner == BoardData.Player.NONE:
			pass
		elif piece_owner != state.active_player:
			if state.active_player == BoardData.Player.PLAYER_1:
				invalid_tap_info.emit("You are Player 1 (RED)! Move your Red pieces at the bottom.")
			else:
				invalid_tap_info.emit("It is Player 2's turn!")
		AudioManager.play_sfx("invalid")
		invalid_tap.emit()

func _find_closest_node(pos: Vector2, max_radius: float = NODE_SNAP_RADIUS) -> int:
	var best_id = -1
	var best_dist = max_radius
	for id in nodes.keys():
		var d = nodes[id].position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_id = id
	return best_id

func _on_piece_input(piece: Piece, event: InputEvent) -> void:
	if not GameManager.is_playing() or is_animating:
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_handle_node_press(piece.current_node_id, piece.position)

func _on_piece_clicked(piece: Piece) -> void:
	if not GameManager.is_playing() or is_animating or is_drag_active:
		return
	_handle_node_press(piece.current_node_id, piece.position)

func _on_node_clicked(node_id: int) -> void:
	if not GameManager.is_playing() or is_animating or is_drag_active:
		return
	if nodes.has(node_id):
		_handle_node_press(node_id, nodes[node_id].position)

func show_hint(move: Dictionary) -> void:
	if move.is_empty() or not move.has("from") or not move.has("to"):
		return
	var from_node = move["from"]
	var target_id = move["to"]
	var legal = RulesEngine.get_legal_moves_for_piece(GameManager.current_state, from_node, SaveManager.settings.forced_capture)
	select_piece_at_node(from_node, legal)
	current_hint_move = move.duplicate()
	if nodes.has(target_id):
		var show_caps = should_show_capture_highlights()
		var hl_type = BoardNode.HighlightType.VALID_CAPTURE if (move.get("is_capture", false) and show_caps) else BoardNode.HighlightType.VALID_MOVE
		nodes[target_id].set_highlight(hl_type)
	invalid_tap_info.emit("Hint: Click the green node (or click the glowing piece) to move!")

func toggle_debug() -> void:
	debug_mode = not debug_mode
	for b_node in nodes.values():
		b_node.show_debug(debug_mode)
