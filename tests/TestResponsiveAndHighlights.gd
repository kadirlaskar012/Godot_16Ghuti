extends Node

func _ready() -> void:
	print("\n=== RUNNING TEST: Responsive Layout & Two-Player Highlights ===")
	
	# -------------------------------------------------------------
	# Test 1: Capture Highlights in AI Mode vs 2P / Online Mode
	# -------------------------------------------------------------
	print("\n--- Test 1: Move Highlighting Rules ---")
	var board_scene = load("res://scenes/Board.tscn")
	var board: BoardManager = board_scene.instantiate()
	add_child(board)
	
	# Mock a state where a piece has a capture move
	var mock_state = GameState.new()
	mock_state.board.fill(BoardData.Player.NONE)
	mock_state.board[18] = BoardData.Player.PLAYER_1 # Center node (col 2, row 4)
	mock_state.board[13] = BoardData.Player.PLAYER_2 # Adjacent opponent node (col 2, row 3)
	mock_state.board[8] = BoardData.Player.NONE     # Landing empty node (col 2, row 2)
	mock_state.active_player = BoardData.Player.PLAYER_1
	GameManager.current_state = mock_state
	board.populate_pieces_from_state(mock_state)
	
	var legal_moves = RulesEngine.get_legal_moves_for_piece(mock_state, 18, false)
	assert(legal_moves.size() > 0, "Piece at 18 must have legal moves")
	var has_cap = false
	for m in legal_moves:
		if m.get("is_capture", false):
			has_cap = true
			break
	assert(has_cap, "Piece at 18 must have a capture move to node 8")
	
	# Case A: VS AI mode -> Captures MUST be highlighted as VALID_CAPTURE (Red)
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	board.select_piece_at_node(18, legal_moves)
	var hl_node_8_ai = board.nodes[8].current_highlight
	print("[AI Mode] Node 8 highlight type: ", hl_node_8_ai)
	assert(hl_node_8_ai == BoardNode.HighlightType.VALID_CAPTURE, "In AI mode, capture must be VALID_CAPTURE (Red)")
	print("✔ Test 1A Passed: AI Mode shows red capture highlight.")
	
	# Case B: Local 2 Player mode -> Captures MUST NOT be highlighted in Red (VALID_MOVE instead)
	board.clear_selection()
	GameManager.current_mode = GameManager.GameMode.LOCAL_2P
	board.select_piece_at_node(18, legal_moves)
	var hl_node_8_2p = board.nodes[8].current_highlight
	print("[Local 2P Mode] Node 8 highlight type: ", hl_node_8_2p)
	assert(hl_node_8_2p == BoardNode.HighlightType.VALID_MOVE, "In Local 2P, capture MUST be VALID_MOVE (Not Red)")
	print("✔ Test 1B Passed: Local 2P hides red capture highlight, shows regular valid move.")
	
	# Case C: Online Multiplayer mode -> Captures MUST NOT be highlighted in Red
	board.clear_selection()
	GameManager.current_mode = GameManager.GameMode.ONLINE_MULTIPLAYER
	board.select_piece_at_node(18, legal_moves)
	var hl_node_8_online = board.nodes[8].current_highlight
	print("[Online Mode] Node 8 highlight type: ", hl_node_8_online)
	assert(hl_node_8_online == BoardNode.HighlightType.VALID_MOVE, "In Online Multiplayer, capture MUST be VALID_MOVE (Not Red)")
	print("✔ Test 1C Passed: Online Multiplayer hides red capture highlight.")
	
	board.queue_free()
	
	# -------------------------------------------------------------
	# Test 2: In-Game Responsive Layout and Safe Margins
	# -------------------------------------------------------------
	print("\n--- Test 2: In-Game Layout Spacing ---")
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.is_game_active = true
	var game_scene = load("res://scenes/Game.tscn")
	var game: GameController = game_scene.instantiate()
	add_child(game)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var hud: GameHUD = game.get_node("GameHUD")
	var test_board: BoardManager = game.get_node("Board")
	var p2 = hud.find_child("P2Card", true, false)
	var p1 = hud.find_child("P1Card", true, false)
	var bb = hud.find_child("BottomBar", true, false)
	var vp = game.get_viewport_rect().size
	
	var board_scale = test_board.scale.y
	var board_wood_h = 1348.48 * board_scale
	var board_top = test_board.position.y + 960.0 * board_scale - (board_wood_h / 2.0)
	var board_bot = test_board.position.y + 960.0 * board_scale + (board_wood_h / 2.0)
	
	var p2_bottom = p2.position.y + p2.size.y
	var gap_top = board_top - p2_bottom
	var gap_bot = p1.position.y - board_bot
	var gap_card_to_bar = bb.position.y - (p1.position.y + p1.size.y)
	var screen_margin_left = p2.position.x
	var screen_margin_right = vp.x - (p2.position.x + p2.size.x)
	var bar_screen_bottom = vp.y - (bb.position.y + bb.size.y)
	
	print("Layout Metrics (1080x1920):")
	print("  P2Card: Y=", p2.position.y, " to ", p2_bottom)
	print("  Board: Top=", board_top, " Bottom=", board_bot, " Scale=", board_scale)
	print("  Gap P2 to Board: ", gap_top, " px (must be >= 20px)")
	print("  Gap Board to P1: ", gap_bot, " px (must be >= 20px)")
	print("  P1Card: Y=", p1.position.y, " to ", p1.position.y + p1.size.y)
	print("  Gap P1 to BottomBar: ", gap_card_to_bar, " px (tight gap)")
	print("  BottomBar: Y=", bb.position.y, " to ", bb.position.y + bb.size.y)
	print("  Distance to screen bottom: ", bar_screen_bottom, " px (must be > 20px)")
	print("  Side Margins: Left=", screen_margin_left, " Right=", screen_margin_right)
	
	assert(gap_top >= 20.0, "Top profile must NOT touch board! Gap must be at least 20px")
	assert(gap_bot >= 20.0, "Bottom profile must NOT touch board! Gap must be at least 20px")
	assert(bar_screen_bottom >= 20.0, "BottomBar must not clip off the screen!")
	assert(screen_margin_left <= 12.0 and screen_margin_left >= 4.0, "Side margin must be clean tight ~5-10px")
	print("✔ Test 2 Passed: In-Game Layout spacing is fully responsive and adheres to requirements!")
	
	print("\nALL RESPONSIVE & HIGHLIGHT TESTS PASSED (100%)!\n")
	get_tree().quit(0)
