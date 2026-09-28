extends SceneTree

const BoardData = preload("res://scripts/data/BoardData.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const RulesEngine = preload("res://scripts/rules/RulesEngine.gd")
const AIManager = preload("res://scripts/ai/AIManager.gd")

func _init() -> void:
	print("--- Running TestAI ---")
	
	for diff in [AIManager.Difficulty.EASY, AIManager.Difficulty.MEDIUM, AIManager.Difficulty.HARD]:
		var diff_name = ["EASY", "MEDIUM", "HARD"][diff]
		print("Testing AI Difficulty: %s" % diff_name)
		
		var state = GameState.new()
		# P1 makes opening move
		var p1_moves = RulesEngine.get_all_legal_moves(state)
		RulesEngine.apply_move(state, p1_moves[0])
		assert(state.active_player == BoardData.Player.PLAYER_2, "Now P2/AI turn")
		
		# AI chooses move
		var start_time = Time.get_ticks_msec()
		var ai_move = AIManager.get_best_move(state, diff, BoardData.Player.PLAYER_2)
		var elapsed = Time.get_ticks_msec() - start_time
		
		assert(not ai_move.is_empty(), "AI must return a move")
		# Verify move is among legal moves
		var legal_moves = RulesEngine.get_all_legal_moves(state)
		var found = false
		for lm in legal_moves:
			if lm["from"] == ai_move["from"] and lm["to"] == ai_move["to"]:
				found = true
				break
		assert(found, "AI move %s must be legal!" % str(ai_move))
		print("✔ %s made valid legal move in %d ms: %d -> %d" % [diff_name, elapsed, ai_move["from"], ai_move["to"]])
		
	# Test AI finding forced capture
	var cap_state = GameState.new()
	cap_state.board.fill(BoardData.Player.NONE)
	cap_state.set_piece(16, BoardData.Player.PLAYER_2) # (0,4)
	cap_state.set_piece(11, BoardData.Player.PLAYER_1) # (0,3)
	cap_state.p2_pieces = 1
	cap_state.p1_pieces = 1
	cap_state.active_player = BoardData.Player.PLAYER_2
	
	var hard_move = AIManager.get_best_move(cap_state, AIManager.Difficulty.HARD, BoardData.Player.PLAYER_2)
	assert(hard_move["is_capture"], "Hard AI must find capture opportunity")
	assert(hard_move["to"] == 6, "Landing must be node 6")
	print("✔ Hard AI successfully prioritized winning capture.")
	
	print("🎉 ALL AI TESTS PASSED!")
	quit(0)
