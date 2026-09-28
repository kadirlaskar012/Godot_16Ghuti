extends Node2D

func _ready() -> void:
	print("--- Running TestSwipeCapture: Verifying Swipe & Drag Capture Mechanic ---")
	GameManager.current_mode = GameManager.GameMode.LOCAL_2P
	GameManager.current_state.reset_to_start()
	GameManager.is_game_active = true
	
	var game_scene = load("res://scenes/Game.tscn")
	var game_instance = game_scene.instantiate()
	add_child(game_instance)
	
	var board: BoardManager = game_instance.board
	var state: GameState = GameManager.current_state
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	while board.is_animating:
		await get_tree().process_frame
		
	# Setup a custom board scenario with a multi-capture opportunity for Player 1:
	# P1 piece at node 24 (row 4, col 3)
	# Opponent piece at node 19 (row 3, col 3)
	# Landing node 14 (row 2, col 3) is empty
	# Opponent piece at node 9 (row 1, col 3)
	# Landing node 4 (row 0, col 2) or node 5 (row 0, col 3) is empty
	for i in range(BoardData.TOTAL_NODES):
		state.set_piece(i, BoardData.Player.NONE)
		
	# Place P1 piece at node 24
	state.set_piece(24, BoardData.Player.PLAYER_1)
	state.p1_pieces = 1
	# Place P2 piece at node 18 (can be jumped into node 12)
	state.set_piece(18, BoardData.Player.PLAYER_2)
	# Place P2 piece at node 8 (can then be jumped into node 5)
	state.set_piece(8, BoardData.Player.PLAYER_2)
	# Place an extra P2 piece at node 1 so match doesn't end prematurely
	state.set_piece(1, BoardData.Player.PLAYER_2)
	state.p2_pieces = 3
	state.active_player = BoardData.Player.PLAYER_1
	
	board.populate_pieces_from_state(state)
	game_instance.hud.update_hud(state)
	
	await get_tree().process_frame
	
	print("Scenario prepared: P1 at node 24, P2 at node 18 and node 8.")
	
	# Test 1: User presses down on piece 24
	print("1. Pressing down on piece at node 24...")
	var node24_pos = board.nodes[24].position
	board._handle_node_press(24, node24_pos)
	assert(board.selected_node_id == 24, "Node 24 must be selected!")
	assert(board.dragged_piece != null, "Dragged piece must be set!")
	
	# Test 2: User drags towards node 12 (jumping over node 18)
	print("2. Simulating drag swipe towards node 12...")
	var node12_pos = board.nodes[12].position
	board.is_drag_active = true
	board._check_mid_drag_capture(node12_pos)
	
	assert(board.is_swiping_capture, "Must enter is_swiping_capture state!")
	assert(state.get_piece(18) == BoardData.Player.NONE, "Piece 18 must be captured!")
	assert(state.get_piece(12) == BoardData.Player.PLAYER_1, "P1 piece must now be logically at node 12!")
	assert(board.swipe_current_node == 12, "Swipe current node must be 12!")
	print("✔ First jump over piece 18 executed during drag!")
	
	# Test 3: User continues dragging towards node 5 (jumping over node 8)
	print("3. Simulating continued drag swipe towards node 5...")
	var node5_pos = board.nodes[5].position
	board._check_mid_drag_capture(node5_pos)
	
	assert(state.get_piece(8) == BoardData.Player.NONE, "Piece 8 must be captured!")
	assert(state.get_piece(5) == BoardData.Player.PLAYER_1, "P1 piece must now be logically at node 5!")
	assert(board.swipe_current_node == 5, "Swipe current node must be 5!")
	print("✔ Second jump over piece 8 executed during same continuous drag gesture!")
	
	# Test 4: User releases finger
	print("4. Releasing finger (release to end turn)...")
	board._finish_drag(node5_pos)
	
	# Verify that turn ended IMMEDIATELY and switched to Player 2
	assert(state.is_in_multi_capture == false, "State must NOT be in multi_capture!")
	assert(state.active_player == BoardData.Player.PLAYER_2, "Turn must switch to Player 2 immediately upon release!")
	assert(board.selected_node_id == -1, "Selection must be cleared!")
	print("✔ Turn ended immediately upon release and switched to opponent!")
	
	# Test 5: Verify Tap-to-Move does not leave multi-capture lingering
	print("5. Verifying single move tap does not get stuck in moving...")
	# Place P2 piece at node 1, empty node 0
	state.set_piece(1, BoardData.Player.PLAYER_2)
	state.active_player = BoardData.Player.PLAYER_2
	var normal_move = {
		"from": 1,
		"to": 0,
		"is_capture": false,
		"captured": -1
	}
	game_instance._on_move_executed(normal_move)
	
	while board.is_animating:
		await get_tree().process_frame
		
	assert(state.is_in_multi_capture == false, "Must not linger in multi-capture!")
	assert(state.active_player == BoardData.Player.PLAYER_1, "Must switch back to Player 1!")
	print("✔ Normal move tap completed and switched players immediately!")
	
	print("🎉 ALL SWIPE AND DRAG CAPTURE TESTS PASSED WITH 100% SUCCESS!")
	get_tree().quit(0)
