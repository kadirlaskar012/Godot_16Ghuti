extends Node

func _ready() -> void:
	print("--- Capturing All Visual Proofs ---")
	
	# 1. Capture Local 2P Move Selection (Proves NO RED CAPTURE HIGHLIGHT)
	GameManager.current_mode = GameManager.GameMode.LOCAL_2P
	GameManager.is_game_active = true
	var game_scene = load("res://scenes/Game.tscn")
	var game_2p = game_scene.instantiate()
	add_child(game_2p)
	
	# Mock state with a capture available
	var board_2p: BoardManager = game_2p.get_node("Board")
	var mock_state = GameState.new()
	mock_state.board.fill(BoardData.Player.NONE)
	mock_state.board[18] = BoardData.Player.PLAYER_1
	mock_state.board[13] = BoardData.Player.PLAYER_2
	mock_state.board[8] = BoardData.Player.NONE
	mock_state.active_player = BoardData.Player.PLAYER_1
	GameManager.current_state = mock_state
	board_2p.populate_pieces_from_state(mock_state)
	game_2p.get_node("GameHUD").update_hud(mock_state)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var moves = RulesEngine.get_legal_moves_for_piece(mock_state, 18, false)
	board_2p.select_piece_at_node(18, moves)
	
	await get_tree().create_timer(0.3).timeout
	var img_2p = get_viewport().get_texture().get_image()
	if img_2p:
		img_2p.save_png("preview_2p_no_red_capture.png")
		print("✔ Saved preview_2p_no_red_capture.png")
		
	game_2p.queue_free()
	await get_tree().process_frame
	
	# 2. Capture AI Game Move Selection (Proves RED CAPTURE STILL WORKS IN AI)
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.is_game_active = true
	var game_ai = game_scene.instantiate()
	add_child(game_ai)
	
	var board_ai: BoardManager = game_ai.get_node("Board")
	var mock_state_ai = GameState.new()
	mock_state_ai.board.fill(BoardData.Player.NONE)
	mock_state_ai.board[18] = BoardData.Player.PLAYER_1
	mock_state_ai.board[13] = BoardData.Player.PLAYER_2
	mock_state_ai.board[8] = BoardData.Player.NONE
	mock_state_ai.active_player = BoardData.Player.PLAYER_1
	GameManager.current_state = mock_state_ai
	board_ai.populate_pieces_from_state(mock_state_ai)
	game_ai.get_node("GameHUD").update_hud(mock_state_ai)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var moves_ai = RulesEngine.get_legal_moves_for_piece(mock_state_ai, 18, false)
	board_ai.select_piece_at_node(18, moves_ai)
	
	await get_tree().create_timer(0.3).timeout
	var img_ai = get_viewport().get_texture().get_image()
	if img_ai:
		img_ai.save_png("preview_ai_red_capture.png")
		print("✔ Saved preview_ai_red_capture.png")
		
	game_ai.queue_free()
	await get_tree().process_frame
	
	# 3. Capture Standard In-Game Responsive Layout
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	var game_clean = game_scene.instantiate()
	add_child(game_clean)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	var img_layout = get_viewport().get_texture().get_image()
	if img_layout:
		img_layout.save_png("preview_responsive_layout.png")
		print("✔ Saved preview_responsive_layout.png")
		
	print("All visual proofs captured!")
	get_tree().quit(0)
