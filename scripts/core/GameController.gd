class_name GameController
extends Node2D

## Main Game Controller orchestrating Board, RulesEngine, GameHUD, and AI turns.

const RESULT_MODAL_SCENE = preload("res://scenes/modals/GameResultModal.tscn")
const RESET_MODAL_SCENE = preload("res://scenes/modals/ResetConfirmModal.tscn")
const LEAVE_MODAL_SCENE = preload("res://scenes/modals/LeaveConfirmModal.tscn")

@onready var board: BoardManager = $Board
@onready var hud: GameHUD = $GameHUD

var state: GameState
var ai_timer: Timer

func _ready() -> void:
	if not GameManager.is_game_active:
		GameManager.is_game_active = true
		GameManager.match_state = GameManager.MatchState.PLAYING
		if GameManager.current_state == null:
			GameManager.current_state = GameState.new()
		GameManager.current_state.reset_to_start()
		
	state = GameManager.current_state
	
	# Connect Board signals
	board.move_executed.connect(_on_move_executed)
	board.swipe_turn_completed.connect(_on_swipe_turn_completed)
	board.invalid_tap_info.connect(func(reason: String): hud.show_toast(reason))
	
	# Connect HUD signals
	hud.menu_pressed.connect(_on_menu_pressed)
	hud.undo_pressed.connect(_on_undo_pressed)
	hud.hint_pressed.connect(_on_hint_pressed)
	hud.reset_pressed.connect(_on_reset_pressed)
	hud.time_expired.connect(_on_time_expired)
	hud.player_extra_time_expired.connect(_on_hud_player_extra_time_expired)
	hud.theme_changed.connect(_on_theme_changed)
	
	# Setup AI timer
	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(ai_timer)
	
	# Apply current theme
	var cur_theme = SaveManager.settings.board_theme
	_apply_tabletop_theme(cur_theme)
	board.apply_theme(cur_theme)
	
	# Initialize board pieces and HUD
	hud.setup_players()
	board.populate_pieces_from_state(state)
	hud.update_hud(state)
	
	# Ensure BGM is continuously playing in game
	AudioManager.play_music()
	
	# Responsive layout calculation
	_update_responsive_layout()
	get_tree().root.size_changed.connect(_update_responsive_layout)
	
	if state.history.is_empty():
		board.play_match_start_animation(func():
			hud.show_toast("Match Started! Your Turn.", 1.2)
		)
	
	# Online Multiplayer Event Hook
	if GameManager.current_mode == GameManager.GameMode.ONLINE_MULTIPLAYER:
		var om = get_node_or_null("/root/OnlineMatchManager")
		if om:
			om.move_accepted.connect(_on_online_move_accepted)
			om.move_rejected.connect(_on_online_move_rejected)
			om.timer_ticked.connect(_on_online_timer_ticked)
			om.turn_timer_ticked.connect(_on_online_turn_timer_ticked)
			om.match_finished.connect(_on_online_match_finished)
			om.state_synced.connect(_on_online_state_synced)
	
	# Keyboard shortcuts for development / power users
	set_process_unhandled_input(true)

func _update_responsive_layout() -> void:
	var vp_size = get_viewport_rect().size
	var safe = SafeAreaHelper.get_safe_margins(vp_size.x)
	
	hud.apply_safe_margins(safe["top"], safe["bottom"])
	
	var safe_top = maxf(safe.get("top", 44.0), 44.0)
	var safe_bot = maxf(safe.get("bottom", 24.0), 24.0)
	var safe_left = maxf(safe.get("left", 0.0), 0.0)
	var safe_right = maxf(safe.get("right", 0.0), 0.0)
	var safe_width = maxf(200.0, vp_size.x - safe_left - safe_right)
	
	var ui_scale = clampf(vp_size.x / 1080.0, 0.35, 1.5)
	var header_bottom = safe_top + (58.0 * ui_scale)
	
	var actual_card_h = 129.0
	if hud and hud.p2_panel:
		actual_card_h = maxf(129.0 * ui_scale, hud.p2_panel.get_combined_minimum_size().y)
	var card_h = actual_card_h
	
	var is_bar_active = hud.is_bottom_bar_needed()
	var actual_bar_h = 76.0
	if hud and hud.bottom_bar:
		actual_bar_h = maxf(76.0 * ui_scale, hud.bottom_bar.get_combined_minimum_size().y)
	var bar_h = actual_bar_h if is_bar_active else 0.0
	var gap_card_to_bar = 4.0 if is_bar_active else 0.0
	var bot_ctrl_h = card_h + gap_card_to_bar + bar_h
	
	# Minimum breathing room from board edge so cards NEVER touch or overlap the board frame
	var min_board_gap = 14.0 * ui_scale
	var min_header_p2_gap = 6.0 * ui_scale
	var min_screen_bot_gap = safe_bot + (4.0 * ui_scale)
	
	var min_overhead = header_bottom + min_header_p2_gap + card_h + (min_board_gap * 2.0) + bot_ctrl_h + min_screen_bot_gap
	var avail_for_board = maxf(100.0, vp_size.y - min_overhead)
	
	# Board base dimensions in local board space:
	# Texture is 768 * 1.3 = 998.4 wide, height is 1376 * 0.98 = 1348.48 high.
	const BOARD_BASE_WIDTH: float = 998.4
	const BOARD_BASE_HEIGHT: float = 1348.48
	
	# Primary constraint: board width uses 94.8% (94–96% range) of available safe screen width.
	# Equal left and right margins, horizontally centered.
	var target_board_w = safe_width * 0.948
	var scale_by_width = target_board_w / BOARD_BASE_WIDTH
	
	# If vertical space becomes limited on shorter screens, dynamically reduce board size to prevent overlap
	var scale_by_height = avail_for_board / BOARD_BASE_HEIGHT
	
	# Uniform scale preserving aspect ratio 100% (never stretch or distort)
	var target_scale = minf(scale_by_width, scale_by_height)
	var board_w = BOARD_BASE_WIDTH * target_scale
	var board_h = BOARD_BASE_HEIGHT * target_scale
	
	# Distribute vertical slack gracefully between header, board, and screen bottom
	var slack = vp_size.y - (header_bottom + card_h + board_h + bot_ctrl_h)
	var gap_h_p2 = clampf(slack * 0.08, min_header_p2_gap, 24.0 * ui_scale)
	var gap_bar_screen = clampf(slack * 0.14, min_screen_bot_gap, safe_bot + (32.0 * ui_scale))
	
	var remaining_slack = maxf(min_board_gap * 2.0, slack - gap_h_p2 - gap_bar_screen)
	var gap_board = maxf(min_board_gap, remaining_slack / 2.0)
	
	var p2_y = header_bottom + gap_h_p2
	var board_top = p2_y + card_h + gap_board
	var board_center_y = board_top + (board_h / 2.0)
	var board_bottom = board_top + board_h
	var board_center_x = safe_left + (safe_width / 2.0)
	
	board.set_board_center_and_scale(Vector2(board_center_x, board_center_y), target_scale)
	hud.position_layout_relative_to_board(board_top, board_bottom, vp_size, gap_board, p2_y)

func _on_theme_changed(theme_id: String) -> void:
	board.apply_theme(theme_id)
	_apply_tabletop_theme(theme_id)

func _apply_tabletop_theme(theme_id: String) -> void:
	var path = "res://assets/textures/tabletop_classic.jpg"
	match theme_id:
		"royal_mahogany":
			path = "res://assets/textures/tabletop_mahogany.jpg"
		"ivory_maple":
			path = "res://assets/textures/tabletop_light.jpg"
		_:
			path = "res://assets/textures/tabletop_classic.jpg"
			
	var tex = load(path)
	if tex and has_node("BackgroundLayer/TabletopTexture"):
		var tt = $BackgroundLayer/TabletopTexture as TextureRect
		tt.texture = tex
		if theme_id == "ivory_maple":
			$BackgroundLayer/Dim.color = Color(0, 0, 0, 0.02)
			$BackgroundLayer/Vignette.modulate = Color(0, 0, 0, 0.15)
		elif theme_id == "royal_mahogany":
			$BackgroundLayer/Dim.color = Color(0.12, 0.02, 0.02, 0.12)
			$BackgroundLayer/Vignette.modulate = Color(0.25, 0.03, 0.03, 0.40)
		else:
			$BackgroundLayer/Dim.color = Color(0, 0, 0, 0.20)
			$BackgroundLayer/Vignette.modulate = Color(0, 0, 0, 0.55)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			board.toggle_debug()
		elif event.keycode == KEY_Z and event.ctrl_pressed:
			_on_undo_pressed()
		elif event.keycode == KEY_T:
			# Development-only 10-second timer test
			hud.start_debug_test_timer(10.0)
			hud.show_toast("Debug Timer: 10s Countdown Started", 1.2)
		elif event.keycode == KEY_SPACE:
			if not board.is_animating and GameManager.is_playing():
				var m = AIManager.get_best_move(state, AIManager.Difficulty.MEDIUM, state.active_player)
				if not m.is_empty():
					_on_move_executed(m)

func _on_menu_pressed() -> void:
	if not GameManager.is_game_active and GameManager.match_state != GameManager.MatchState.PLAYING:
		return
	for c in get_children():
		if c.name == "LeaveConfirmModal":
			return
			
	GameManager.pause_match()
	hud.pause_timer()
	ai_timer.stop()
	
	var modal = LEAVE_MODAL_SCENE.instantiate()
	modal.name = "LeaveConfirmModal"
	modal.continue_pressed.connect(func():
		GameManager.resume_match()
		hud.resume_timer()
		if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI and state.active_player == BoardData.Player.PLAYER_2:
			ai_timer.start(0.5)
	)
	modal.restart_pressed.connect(func():
		GameManager.restart_current_match()
		board.populate_pieces_from_state(state)
		hud.setup_players()
		hud.update_hud(state)
	)
	modal.leave_pressed.connect(func():
		hud.stop_timer()
		GameManager.go_to_main_menu()
	)
	add_child(modal)

func _on_move_executed(move: Dictionary) -> void:
	if not GameManager.is_playing():
		return
		
	# In Online Multiplayer: Send action to Nakama server for authoritative validation
	if GameManager.current_mode == GameManager.GameMode.ONLINE_MULTIPLAYER:
		var om = get_node_or_null("/root/OnlineMatchManager")
		if om:
			om.send_move_action(
				move["from"],
				move["to"],
				move["is_capture"],
				move.get("captured", -1)
			)
		return
		
	# Offline VS AI and Local 2P Gameplay (unaffected)
	var active_p = state.active_player
	var res = RulesEngine.apply_move(state, move, false)
	
	if move["is_capture"]:
		if active_p == BoardData.Player.PLAYER_1:
			GameManager.p1_match_captures += 1
		else:
			GameManager.p2_match_captures += 1
	else:
		board.current_capture_chain_level = 1
			
	hud.update_hud(state)
	
	board.execute_move_visual(move, func():
		_check_post_move_state(res)
	)

func _on_swipe_turn_completed(swipe_steps: Array) -> void:
	if not GameManager.is_playing():
		return
		
	state.is_in_multi_capture = false
	state.multi_capture_node = -1
	board.current_capture_chain_level = 1
	var completed_player = state.active_player
	state.active_player = state.get_opponent(completed_player)
	hud.update_hud(state)
	
	for step in swipe_steps:
		var entry = {
			"from": step["from"],
			"to": step["to"],
			"is_capture": true,
			"captured_node": step.get("captured", -1),
			"captured_piece": state.active_player,
			"player": completed_player,
			"prev_multi_capture": false,
			"prev_multi_node": -1,
			"turn_changed": true
		}
		state.history.append(entry)
		
	var game_over = RulesEngine.check_game_over(state, SaveManager.settings.forced_capture)
	if game_over["is_game_over"]:
		_handle_game_over(game_over["winner"], game_over["reason"], false)
		return
		
	if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI and state.active_player == BoardData.Player.PLAYER_2:
		var delay = randf_range(0.5, 0.75)
		ai_timer.start(delay)

func _on_online_move_accepted(data: Dictionary) -> void:
	var move = {
		"from": int(data["from"]),
		"to": int(data["to"]),
		"is_capture": bool(data["is_capture"]),
		"captured": int(data.get("captured", -1))
	}
	
	# Update local GameState from server-authoritative state packet
	var raw_board = data.get("board", [])
	for i in range(mini(raw_board.size(), BoardData.TOTAL_NODES)):
		state.set_piece(i, int(raw_board[i]))
	state.active_player = int(data.get("active_player", state.active_player))
	state.is_in_multi_capture = bool(data.get("is_multi_capture", false))
	state.multi_capture_node = int(data.get("multi_capture_node", -1))
	state.p1_pieces = int(data.get("p1_remaining", state.p1_pieces))
	state.p2_pieces = int(data.get("p2_remaining", state.p2_pieces))
	
	hud.update_hud(state)
	board.execute_move_visual(move, func():
		hud.update_hud(state)
	)

func _on_online_move_rejected(reason: String) -> void:
	hud.show_toast(reason, 1.5)
	AudioManager.play_sfx("invalid")
	HapticManager.vibrate_invalid()
	board.populate_pieces_from_state(state)

func _on_online_timer_ticked(remaining_seconds: int) -> void:
	hud.set_server_authoritative_time(float(remaining_seconds))

func _on_online_turn_timer_ticked(payload: Dictionary) -> void:
	hud.update_server_turn_timer(payload)

func _on_online_match_finished(result_data: Dictionary) -> void:
	var winner = int(result_data.get("winner", 0))
	var reason = str(result_data.get("end_reason", "Match completed"))
	var is_time_up = (reason == "TIME_UP" or reason == "TIMEOUT")
	_handle_game_over(winner, reason, is_time_up)

func _on_online_state_synced(sync_data: Dictionary) -> void:
	var raw_board = sync_data.get("board", [])
	for i in range(mini(raw_board.size(), BoardData.TOTAL_NODES)):
		state.set_piece(i, int(raw_board[i]))
	state.active_player = int(sync_data.get("active_player", state.active_player))
	state.is_in_multi_capture = bool(sync_data.get("is_multi_capture", false))
	state.multi_capture_node = int(sync_data.get("multi_capture_node", -1))
	board.populate_pieces_from_state(state)
	hud.update_hud(state)

func _check_post_move_state(last_move_res: Dictionary) -> void:
	if not GameManager.is_playing():
		return
		
	# 1. Check Win / Game Over
	var game_over = RulesEngine.check_game_over(state, SaveManager.settings.forced_capture)
	if game_over["is_game_over"]:
		_handle_game_over(game_over["winner"], game_over["reason"], false)
		return
		
	# 2. Check Multiple Capture Continuation
	if state.is_in_multi_capture:
		board.current_capture_chain_level += 1
		var chain_piece = state.multi_capture_node
		hud.update_hud(state)
		
		# If AI in multi-capture, continue automatically after short delay
		if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI and state.active_player == BoardData.Player.PLAYER_2:
			ai_timer.start(0.4)
		else:
			# Auto-highlight chain options for human player
			var chain_moves = RulesEngine.get_all_legal_moves(state)
			board.select_piece_at_node(chain_piece, chain_moves)
		return
	else:
		board.current_capture_chain_level = 1
		
	hud.update_hud(state)
	
	# 3. Check AI turn
	if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI and state.active_player == BoardData.Player.PLAYER_2:
		# Natural thinking delay (0.5 to 0.75 seconds)
		var delay = randf_range(0.5, 0.75)
		ai_timer.start(delay)

func _on_ai_timer_timeout() -> void:
	if not GameManager.is_playing() or state.active_player != BoardData.Player.PLAYER_2:
		return
		
	var ai_move = AIManager.get_best_move(state, GameManager.current_difficulty, BoardData.Player.PLAYER_2)
	if ai_move.is_empty():
		# AI has no legal moves -> Player 1 wins
		_handle_game_over(BoardData.Player.PLAYER_1, "AI has no moves left!", false)
		return
		
	_on_move_executed(ai_move)

func _on_undo_pressed() -> void:
	if state.history.is_empty() or board.is_animating or not GameManager.is_playing():
		return
		
	if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI:
		# If AI is currently thinking, cancel it
		ai_timer.stop()
		
		# Undo moves until it is Player 1's turn and not in mid multi-capture
		while not state.history.is_empty():
			var last_entry = state.history.back()
			var p = last_entry["player"]
			RulesEngine.undo_move(state)
			if p == BoardData.Player.PLAYER_1 and not state.is_in_multi_capture:
				break
	else:
		# Local 2P: undo 1 step
		RulesEngine.undo_move(state)
		
	board.populate_pieces_from_state(state)
	hud.update_hud(state)
	AudioManager.play_sfx("move")
	HapticManager.vibrate_move()

func _on_hint_pressed() -> void:
	if not GameManager.is_playing() or board.is_animating:
		return
		
	# Find optimal move using Hard AI evaluation
	var hint_move = AIManager.get_best_move(state, AIManager.Difficulty.HARD, state.active_player)
	if hint_move.size() > 0:
		board.show_hint(hint_move)
		AudioManager.play_sfx("select")
		HapticManager.vibrate_selection()

func _on_reset_pressed() -> void:
	if board.is_animating or not GameManager.is_playing():
		return
		
	GameManager.pause_match()
	hud.pause_timer()
	ai_timer.stop()
	
	var modal: ResetConfirmModal = RESET_MODAL_SCENE.instantiate()
	modal.confirmed.connect(func():
		GameManager.restart_current_match()
		board.populate_pieces_from_state(state)
		hud.setup_players()
		hud.update_hud(state)
	)
	modal.cancelled.connect(func():
		GameManager.resume_match()
		hud.resume_timer()
		if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI and state.active_player == BoardData.Player.PLAYER_2:
			ai_timer.start(0.5)
	)
	add_child(modal)

func _on_time_expired() -> void:
	if GameManager.match_state != GameManager.MatchState.PLAYING:
		return
		
	ai_timer.stop()
	board.reset_all_piece_visuals()
	
	var winner = BoardData.Player.NONE
	var reason = ""
	if state.p1_pieces > state.p2_pieces:
		winner = BoardData.Player.PLAYER_1
		reason = "Player 1 has more remaining pieces (%d vs %d)." % [state.p1_pieces, state.p2_pieces]
	elif state.p2_pieces > state.p1_pieces:
		winner = BoardData.Player.PLAYER_2
		reason = "Player 2 has more remaining pieces (%d vs %d)." % [state.p2_pieces, state.p1_pieces]
	else:
		winner = BoardData.Player.NONE
		reason = "Equal pieces remaining (%d each)." % state.p1_pieces
		
	_handle_game_over(winner, reason, true)

func _on_hud_player_extra_time_expired(timed_out_p: int) -> void:
	if not GameManager.is_playing():
		return
	var winner = BoardData.Player.PLAYER_2 if timed_out_p == BoardData.Player.PLAYER_1 else BoardData.Player.PLAYER_1
	var loser_name = "Player 1" if timed_out_p == BoardData.Player.PLAYER_1 else ("AI Bot" if GameManager.current_mode == GameManager.GameMode.PLAYER_VS_AI else "Player 2")
	_handle_game_over(winner, "%s ran out of Extra Time!" % loser_name, true)

func _handle_game_over(winner: int, reason: String, is_time_up: bool = false) -> void:
	ai_timer.stop()
	GameManager.end_match(winner, reason, is_time_up)
	board.reset_all_piece_visuals()
	
	# Show result modal
	var modal = RESULT_MODAL_SCENE.instantiate()
	add_child(modal)
	
	var duration = GameManager.match_duration
	var rem_pieces = state.p1_pieces if winner == BoardData.Player.PLAYER_1 else state.p2_pieces
	var caps = GameManager.p1_match_captures if winner == BoardData.Player.PLAYER_1 else GameManager.p2_match_captures
	var moves = state.history.size()
	modal.setup(winner, reason, duration, rem_pieces, caps, moves, is_time_up)
	
	modal.rematch_pressed.connect(func():
		GameManager.restart_current_match()
		board.populate_pieces_from_state(state)
		hud.setup_players()
		hud.update_hud(state)
	)
	modal.main_menu_pressed.connect(func():
		hud.stop_timer()
		GameManager.go_to_main_menu()
	)
