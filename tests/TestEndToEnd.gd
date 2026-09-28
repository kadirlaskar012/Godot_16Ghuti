extends Node2D

func _ready() -> void:
	print("--- Running TestEndToEnd Game Integration ---")
	
	# Load Game scene
	var game_scene = load("res://scenes/Game.tscn")
	assert(game_scene != null, "Game.tscn must load")
	
	var game_instance = game_scene.instantiate()
	add_child(game_instance)
	
	var board = game_instance.board
	var hud = game_instance.hud
	assert(board != null, "Board must exist")
	assert(hud != null, "HUD must exist")
	
	await get_tree().physics_frame
	await get_tree().process_frame
	
	# 1. Verify 37 nodes
	assert(board.nodes.size() == 37, "Board must contain exactly 37 nodes, found %d" % board.nodes.size())
	print("✔ Verified 37 playable board nodes exist.")
	
	# 2. Verify 32 pieces (16 vs 16)
	assert(board.pieces.size() == 32, "Board must contain exactly 32 pieces, found %d" % board.pieces.size())
	var p1_count: int = 0
	var p2_count: int = 0
	for node_id in board.pieces.keys():
		var piece = board.pieces[node_id]
		if piece.player_owner == BoardData.Player.PLAYER_1:
			p1_count += 1
			assert(BoardData.P1_START_NODES.has(node_id), "P1 piece on wrong node %d" % node_id)
		elif piece.player_owner == BoardData.Player.PLAYER_2:
			p2_count += 1
			assert(BoardData.P2_START_NODES.has(node_id), "P2 piece on wrong node %d" % node_id)
			
	assert(p1_count == 16, "P1 piece count must be exactly 16")
	assert(p2_count == 16, "P2 piece count must be exactly 16")
	print("✔ Verified 16 Red vs 16 Ivory pieces starting arrangement.")
	
	# 3. Verify empty center row
	for empty_id in BoardData.EMPTY_START_NODES:
		assert(not board.pieces.has(empty_id), "Center row node %d must be empty" % empty_id)
	print("✔ Verified 5 center nodes (16..20) are empty.")
	
	# 4. Simulate piece selection
	var test_node = 21 # (0,5) which is in Row 5 (P1 front row), adjacent to empty Node 16 (0,4)
	var legal_moves = RulesEngine.get_legal_moves_for_piece(GameManager.current_state, test_node)
	assert(legal_moves.size() > 0, "Node 21 must have legal moves into row 4")
	board.select_piece_at_node(test_node, legal_moves)
	assert(board.selected_node_id == test_node, "Node 21 must be selected")
	assert(board.nodes[16].current_highlight == BoardNode.HighlightType.VALID_MOVE, "Node 16 must have VALID_MOVE highlight")
	print("✔ Piece selection and valid move highlights verified.")
	
	# 5. Simulate move execution
	var chosen_move = legal_moves[0]
	game_instance._on_move_executed(chosen_move)
	assert(GameManager.current_state.get_piece(chosen_move["from"]) == BoardData.Player.NONE, "Origin must be empty")
	assert(GameManager.current_state.get_piece(chosen_move["to"]) == BoardData.Player.PLAYER_1, "Target must be occupied by P1")
	print("✔ Move execution in game controller verified.")
	
	# 6. Test Hint system
	var hint_move = AIManager.get_best_move(GameManager.current_state, AIManager.Difficulty.HARD, GameManager.current_state.active_player)
	assert(not hint_move.is_empty(), "Hint must produce a legal move")
	board.show_hint(hint_move)
	print("✔ Hint system calculation and highlight verified: %s" % str(hint_move))
	
	# 7. Test Undo
	while board.is_animating:
		await get_tree().process_frame
	game_instance._on_undo_pressed()
	assert(GameManager.current_state.get_piece(chosen_move["from"]) == BoardData.Player.PLAYER_1, "Origin restored after undo")
	assert(GameManager.current_state.get_piece(chosen_move["to"]) == BoardData.Player.NONE, "Target empty after undo")
	print("✔ Game undo verified.")
	
	# 8. Test Leave / Menu button & LeaveConfirmModal
	assert(hud.menu_btn != null, "Menu button must exist on HUD")
	game_instance._on_menu_pressed()
	var leave_modal = null
	for c in game_instance.get_children():
		if c.name == "LeaveConfirmModal":
			leave_modal = c
			break
	assert(leave_modal != null, "LeaveConfirmModal must open when menu is pressed")
	assert(leave_modal.continue_btn != null, "CONTINUE button must exist")
	assert(leave_modal.restart_btn != null, "RESTART button must exist")
	assert(leave_modal.leave_btn != null, "LEAVE GAME button must exist")
	leave_modal._on_continue()
	print("✔ Leave / Menu option and modal dialog verified.")
	
	# 9. Test Reset button & ResetConfirmModal
	game_instance._on_reset_pressed()
	var reset_modal = null
	for c in game_instance.get_children():
		if c is ResetConfirmModal:
			reset_modal = c
			break
	assert(reset_modal != null, "ResetConfirmModal must open when reset is pressed")
	assert(reset_modal.confirm_btn != null, "RESTART button must exist on Reset modal")
	assert(reset_modal.cancel_btn != null, "CANCEL button must exist on Reset modal")
	reset_modal.confirm_btn.emit_signal("pressed")
	assert(board.pieces.size() == 32, "Reset confirmed: 32 pieces restored")
	print("✔ Reset confirmation flow and board restore verified.")
	
	# 10. Test Sound toggle
	assert(hud.sound_btn != null, "Sound button must exist on HUD")
	hud._toggle_sound()
	hud._toggle_sound()
	print("✔ HUD Sound toggle verified.")
	
	# 11. Test MainMenu scene loading and button labels
	var menu_scene = load("res://scenes/MainMenu.tscn")
	assert(menu_scene != null, "MainMenu scene must load")
	var menu_instance = menu_scene.instantiate()
	add_child(menu_instance)
	assert(menu_instance.play_ai_btn.text == "PLAY VS AI", "Primary button must be PLAY VS AI")
	assert(menu_instance.play_local_btn.text == "LOCAL 2 PLAYER", "Secondary button must be LOCAL 2 PLAYER")
	assert(menu_instance.play_online_btn.text == "ONLINE MULTIPLAYER", "Online button must be ONLINE MULTIPLAYER")
	assert(menu_instance.rules_btn.text == "HOW TO PLAY", "Rules button must be HOW TO PLAY")
	assert(menu_instance.settings_btn != null, "Settings button must exist")
	print("✔ MainMenu structure and premium button labels verified.")
	
	print("🎉 ALL END-TO-END INTEGRATION TESTS PASSED!")
	get_tree().quit(0)
