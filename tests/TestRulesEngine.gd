extends SceneTree

const BoardData = preload("res://scripts/data/BoardData.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const RulesEngine = preload("res://scripts/rules/RulesEngine.gd")

func _init() -> void:
	print("--- Running TestRulesEngine ---")
	
	var state = GameState.new()
	assert(state.p1_pieces == 16, "P1 should start with 16 pieces")
	assert(state.p2_pieces == 16, "P2 should start with 16 pieces")
	assert(state.active_player == BoardData.Player.PLAYER_1, "P1 should start first")
	
	# 1. Starting moves test
	var start_moves = RulesEngine.get_all_legal_moves(state)
	assert(start_moves.size() > 0, "P1 must have valid opening moves into the center empty row")
	print("✔ Initial legal moves detected: %d opening moves available." % start_moves.size())
	
	# Verify that only row 3 pieces can move initially (into row 4)
	for m in start_moves:
		assert(not m["is_capture"], "No captures possible on turn 1")
		assert(BoardData.EMPTY_START_NODES.has(m["to"]), "Opening move must land on empty center row")
	print("✔ Opening moves properly target empty row 4.")
	
	# 2. Test Simple Move Execution and Turn Switching
	var move1 = start_moves[0]
	var res1 = RulesEngine.apply_move(state, move1)
	assert(res1["success"], "Move 1 should succeed")
	assert(res1["turn_ended"], "Turn should end after simple move")
	assert(state.active_player == BoardData.Player.PLAYER_2, "Turn should switch to Player 2")
	assert(state.get_piece(move1["from"]) == BoardData.Player.NONE, "Original node must now be empty")
	assert(state.get_piece(move1["to"]) == BoardData.Player.PLAYER_1, "Target node must have P1 piece")
	print("✔ Simple move execution and turn switching verified.")
	
	# 3. Test Undo
	var undo_ok = RulesEngine.undo_move(state)
	assert(undo_ok, "Undo should succeed")
	assert(state.active_player == BoardData.Player.PLAYER_1, "Turn should return to P1")
	assert(state.get_piece(move1["from"]) == BoardData.Player.PLAYER_1, "Piece restored to origin")
	assert(state.get_piece(move1["to"]) == BoardData.Player.NONE, "Target node empty again")
	print("✔ Undo simple move verified.")
	
	# 4. Test Capture and Multiple Capture Sequence
	# Setup synthetic state:
	# P1 at Node 6 (0,2). Opponent P2 at Node 11 (0,3). Empty at Node 16 (0,4).
	# Opponent P2 at Node 21 (0,5). Empty at Node 26 (0,6).
	var custom_state = GameState.new()
	custom_state.board.fill(BoardData.Player.NONE)
	custom_state.set_piece(6, BoardData.Player.PLAYER_1) # (0,2)
	custom_state.set_piece(11, BoardData.Player.PLAYER_2) # (0,3)
	custom_state.set_piece(21, BoardData.Player.PLAYER_2) # (0,5)
	custom_state.p1_pieces = 1
	custom_state.p2_pieces = 2
	custom_state.active_player = BoardData.Player.PLAYER_1
	
	# From node 6, capture should be: 6 over 11 to 16
	var caps = RulesEngine.get_captures_for_piece(custom_state, 6)
	assert(caps.size() == 1, "Should find exactly 1 capture from node 6")
	assert(caps[0]["to"] == 16, "Landing should be node 16")
	assert(caps[0]["captured"] == 11, "Captured piece should be node 11")
	print("✔ Capture detection verified.")
	
	# Execute Jump 1
	var cap_res1 = RulesEngine.apply_move(custom_state, caps[0])
	assert(cap_res1["success"], "Jump 1 must succeed")
	assert(cap_res1["multi_capture_available"], "Second capture should be available!")
	assert(not cap_res1["turn_ended"], "Turn should NOT end because multi-capture is available")
	assert(custom_state.active_player == BoardData.Player.PLAYER_1, "Turn must stay with Player 1")
	assert(custom_state.is_in_multi_capture, "State must indicate multi-capture mode")
	assert(custom_state.multi_capture_node == 16, "Multi-capture piece must be at landing node 16")
	assert(custom_state.get_piece(11) == BoardData.Player.NONE, "Captured node 11 must be removed")
	assert(custom_state.p2_pieces == 1, "P2 pieces should be decremented to 1")
	print("✔ First jump of multi-capture executed properly.")
	
	# Now only node 16 can move in multi-capture
	var chained_moves = RulesEngine.get_all_legal_moves(custom_state)
	assert(chained_moves.size() == 1, "Only the second capture from node 16 should be legal")
	assert(chained_moves[0]["from"] == 16, "Move must start from 16")
	assert(chained_moves[0]["to"] == 26, "Move must jump over 21 to 26")
	print("✔ Multi-capture constraint enforced (only continuing piece can jump).")
	
	# Execute Jump 2
	var cap_res2 = RulesEngine.apply_move(custom_state, chained_moves[0])
	assert(cap_res2["success"], "Jump 2 must succeed")
	assert(not cap_res2["multi_capture_available"], "No third capture exists")
	assert(cap_res2["turn_ended"], "Turn should now end")
	assert(custom_state.active_player == BoardData.Player.PLAYER_2, "Turn switched to P2")
	assert(custom_state.p2_pieces == 0, "P2 should have 0 pieces left")
	assert(custom_state.get_piece(21) == BoardData.Player.NONE, "Second captured piece removed")
	print("✔ Multiple capture chain completed successfully.")
	
	# 5. Win detection test
	var over = RulesEngine.check_game_over(custom_state)
	assert(over["is_game_over"], "Game should be over")
	assert(over["winner"] == BoardData.Player.PLAYER_1, "Player 1 should win by wiping out P2")
	print("✔ Elimination win condition detected: %s" % over["reason"])
	
	# 6. Test Undo across multi-capture chain
	var undo_j2 = RulesEngine.undo_move(custom_state)
	assert(undo_j2, "Undo jump 2 should succeed")
	assert(custom_state.active_player == BoardData.Player.PLAYER_1, "Active player restored to P1")
	assert(custom_state.p2_pieces == 1, "P2 piece count restored to 1")
	assert(custom_state.get_piece(21) == BoardData.Player.PLAYER_2, "Captured piece 21 restored")
	assert(custom_state.is_in_multi_capture, "Multi capture state restored")
	
	var undo_j1 = RulesEngine.undo_move(custom_state)
	assert(undo_j1, "Undo jump 1 should succeed")
	assert(custom_state.p2_pieces == 2, "P2 piece count restored to 2")
	assert(custom_state.get_piece(11) == BoardData.Player.PLAYER_2, "Captured piece 11 restored")
	assert(custom_state.get_piece(6) == BoardData.Player.PLAYER_1, "P1 piece back at 6")
	assert(not custom_state.is_in_multi_capture, "Multi-capture cleared")
	print("✔ Multi-capture chain undo verified.")
	
	# 7. Test Immobilization Win condition (Stalemate)
	var trap_state = GameState.new()
	trap_state.board.fill(BoardData.Player.NONE)
	# Put P2 piece at node 0 (corner top-left), surrounded by P1 pieces at neighbors 1 and 3
	trap_state.set_piece(0, BoardData.Player.PLAYER_2)
	trap_state.set_piece(1, BoardData.Player.PLAYER_1)
	trap_state.set_piece(3, BoardData.Player.PLAYER_1)
	# Also block jump landing spots: 2 and 8
	trap_state.set_piece(2, BoardData.Player.PLAYER_1)
	trap_state.set_piece(8, BoardData.Player.PLAYER_1)
	trap_state.p1_pieces = 4
	trap_state.p2_pieces = 1
	trap_state.active_player = BoardData.Player.PLAYER_2
	
	var trap_over = RulesEngine.check_game_over(trap_state)
	assert(trap_over["is_game_over"], "Game should be over because P2 has no moves")
	assert(trap_over["winner"] == BoardData.Player.PLAYER_1, "Player 1 should win by immobilizing P2")
	print("✔ Immobilization / block win detected: %s" % trap_over["reason"])
	
	print("🎉 ALL RULES ENGINE TESTS PASSED!")
	quit(0)
