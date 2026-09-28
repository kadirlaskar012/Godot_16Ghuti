extends Node2D

func _ready() -> void:
	print("--- Running TestRunner: Verifying User Screenshot Move ---")
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.current_state.reset_to_start()
	GameManager.is_game_active = true
	
	var game_scene = load("res://scenes/Game.tscn")
	var game_instance = game_scene.instantiate()
	add_child(game_instance)
	
	var board: BoardManager = game_instance.board
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	while board.is_animating:
		await get_tree().process_frame
	
	# Test 1: Click HINT button (just like user did in screenshot!)
	print("1. Clicking HINT button...")
	game_instance._on_hint_pressed()
	await get_tree().process_frame
	
	var hinted_origin = board.selected_node_id
	print("Hint selected origin node: ", hinted_origin)
	assert(hinted_origin >= 0, "Hint should select origin node!")
	
	var hinted_moves = board.current_legal_moves
	print("Hint legal moves: ", hinted_moves)
	assert(hinted_moves.size() > 0, "Hint should provide legal moves!")
	
	var target_node = hinted_moves[0]["to"]
	print("2. Clicking target node: ", target_node)
	board._handle_node_press(target_node, board.nodes[target_node].position)
	
	for i in range(25):
		await get_tree().physics_frame
		await get_tree().process_frame
		
	print("Piece at origin node: ", GameManager.current_state.get_piece(hinted_origin))
	print("Piece at target node: ", GameManager.current_state.get_piece(target_node))
	assert(GameManager.current_state.get_piece(target_node) == BoardData.Player.PLAYER_1, "Target node should now have Player 1 piece!")
	print("✔ Hint-assisted move succeeded perfectly!")
	
	# Test 3: AI makes move
	print("3. Simulating AI turn...")
	while board.is_animating:
		await get_tree().process_frame
	game_instance._on_ai_timer_timeout()
	while board.is_animating:
		await get_tree().process_frame
	assert(GameManager.current_state.active_player == BoardData.Player.PLAYER_1, "Turn returned to Player 1!")
	print("✔ AI moved and turn returned to Player 1!")
	
	# Test 4: Direct mouse click on a Player 1 piece
	var p1_moves = RulesEngine.get_all_legal_moves(GameManager.current_state)
	var test_node = p1_moves[0]["from"]
	print("4. Testing direct click on piece %d..." % test_node)
	board._handle_node_press(test_node, board.nodes[test_node].position)
	
	for i in range(5):
		await get_tree().physics_frame
		await get_tree().process_frame
		
	print("Selected node after direct click: ", board.selected_node_id)
	assert(board.selected_node_id == test_node, "Piece should be selected!")
	print("✔ Direct click on piece %d selected successfully!" % test_node)
	
	print("🎉 ALL TESTS PASSED!")
	get_tree().quit(0)
