class_name AIManager
extends RefCounted

## AI Decision Engine for 16 Guti / Sholo Guti
## Supports EASY, MEDIUM, and HARD difficulties.

enum Difficulty {
	EASY = 0,
	MEDIUM = 1,
	HARD = 2
}

# Central positional weights (higher connectivity = greater strategic advantage)
const POSITION_WEIGHTS: Array[int] = [
	# Row 0
	1, 2, 1,
	# Row 1
	2, 3, 2,
	# Row 2 (5x5 top)
	2, 3, 5, 3, 2,
	# Row 3 (5x5 upper mid)
	3, 4, 6, 4, 3,
	# Row 4 (5x5 center)
	4, 6, 8, 6, 4,
	# Row 5 (5x5 lower mid)
	3, 4, 6, 4, 3,
	# Row 6 (5x5 bottom)
	2, 3, 5, 3, 2,
	# Row 7
	2, 3, 2,
	# Row 8
	1, 2, 1
]

static func get_best_move(state: GameState, difficulty: int, ai_player: int = BoardData.Player.PLAYER_2) -> Dictionary:
	var legal_moves = RulesEngine.get_all_legal_moves(state)
	if legal_moves.is_empty():
		return {}
		
	# If only 1 legal move, take it immediately
	if legal_moves.size() == 1:
		return legal_moves[0]
		
	match difficulty:
		Difficulty.EASY:
			return _get_easy_move(state, legal_moves)
		Difficulty.MEDIUM:
			return _get_medium_move(state, legal_moves, ai_player)
		Difficulty.HARD:
			return _get_hard_move(state, legal_moves, ai_player)
		_:
			return _get_medium_move(state, legal_moves, ai_player)

# EASY: Simple random selection, 60% chance to prioritize captures if available
static func _get_easy_move(_state: GameState, legal_moves: Array[Dictionary]) -> Dictionary:
	var captures: Array[Dictionary] = []
	for m in legal_moves:
		if m["is_capture"]:
			captures.append(m)
			
	if captures.size() > 0 and randf() < 0.65:
		return captures[randi() % captures.size()]
		
	return legal_moves[randi() % legal_moves.size()]

# MEDIUM: 1-ply lookahead with capture prioritization and safety evaluation
static func _get_medium_move(state: GameState, legal_moves: Array[Dictionary], ai_player: int) -> Dictionary:
	var best_score: float = -999999.0
	var best_moves: Array[Dictionary] = []
	var opponent: int = state.get_opponent(ai_player)
	
	for move in legal_moves:
		var sim_state: GameState = state.clone()
		var res: Dictionary = RulesEngine.apply_move(sim_state, move, false)
		
		var score: float = 0.0
		if move["is_capture"]:
			score += 150.0
			
		# Check if the piece moved into danger
		var opp_captures = RulesEngine.get_all_legal_moves(sim_state)
		var is_threatened: bool = false
		for opp_m in opp_captures:
			if opp_m["is_capture"] and opp_m["captured"] == move["to"]:
				is_threatened = true
				break
				
		if is_threatened:
			score -= 90.0
			
		# Positional weight
		score += POSITION_WEIGHTS[move["to"]] * 3.0
		
		# Small random jitter to break ties naturally
		score += randf() * 5.0
		
		if score > best_score:
			best_score = score
			best_moves.clear()
			best_moves.append(move)
		elif abs(score - best_score) < 0.001:
			best_moves.append(move)
			
	return best_moves[randi() % best_moves.size()]

# HARD: Minimax with Alpha-Beta pruning (depth 3)
static func _get_hard_move(state: GameState, legal_moves: Array[Dictionary], ai_player: int) -> Dictionary:
	var best_score: float = -999999.0
	var best_moves: Array[Dictionary] = []
	var alpha: float = -999999.0
	var beta: float = 999999.0
	
	# Order moves to improve alpha-beta pruning (captures first)
	var ordered_moves: Array[Dictionary] = _order_moves(legal_moves)
	
	for move in ordered_moves:
		var sim_state: GameState = state.clone()
		RulesEngine.apply_move(sim_state, move, false)
		
		var score: float = _minimax(sim_state, 2, alpha, beta, false, ai_player)
		
		if score > best_score:
			best_score = score
			best_moves.clear()
			best_moves.append(move)
			alpha = max(alpha, best_score)
		elif abs(score - best_score) < 0.001:
			best_moves.append(move)
			
	return best_moves[randi() % best_moves.size()]

static func _order_moves(moves: Array[Dictionary]) -> Array[Dictionary]:
	var captures: Array[Dictionary] = []
	var non_captures: Array[Dictionary] = []
	for m in moves:
		if m["is_capture"]:
			captures.append(m)
		else:
			non_captures.append(m)
	captures.append_array(non_captures)
	return captures

static func _minimax(state: GameState, depth: int, alpha: float, beta: float, is_maximizing: bool, ai_player: int) -> float:
	var opponent: int = state.get_opponent(ai_player)
	
	# Terminal check
	var game_over: Dictionary = RulesEngine.check_game_over(state)
	if game_over["is_game_over"]:
		if game_over["winner"] == ai_player:
			return 100000.0 + depth * 100.0
		elif game_over["winner"] == opponent:
			return -100000.0 - depth * 100.0
		else:
			return 0.0 # Draw
			
	if depth <= 0:
		return _evaluate_state(state, ai_player)
		
	var legal_moves = RulesEngine.get_all_legal_moves(state)
	if legal_moves.is_empty():
		return -100000.0 if is_maximizing else 100000.0
		
	var ordered_moves = _order_moves(legal_moves)
	
	if is_maximizing:
		var max_eval: float = -999999.0
		for move in ordered_moves:
			var sim: GameState = state.clone()
			RulesEngine.apply_move(sim, move, false)
			var val: float = _minimax(sim, depth - 1, alpha, beta, false, ai_player)
			max_eval = max(max_eval, val)
			alpha = max(alpha, val)
			if beta <= alpha:
				break
		return max_eval
	else:
		var min_eval: float = 999999.0
		for move in ordered_moves:
			var sim: GameState = state.clone()
			RulesEngine.apply_move(sim, move, false)
			var val: float = _minimax(sim, depth - 1, alpha, beta, true, ai_player)
			min_eval = min(min_eval, val)
			beta = min(beta, val)
			if beta <= alpha:
				break
		return min_eval

# Heuristic static evaluation function
static func _evaluate_state(state: GameState, ai_player: int) -> float:
	var opponent: int = state.get_opponent(ai_player)
	var ai_pieces: int = state.get_remaining_pieces(ai_player)
	var opp_pieces: int = state.get_remaining_pieces(opponent)
	
	# 1. Material score (strongest weight)
	var score: float = (ai_pieces - opp_pieces) * 200.0
	
	# 2. Positional and board control score
	var pos_score: float = 0.0
	for node in range(BoardData.TOTAL_NODES):
		var p: int = state.get_piece(node)
		if p == ai_player:
			pos_score += POSITION_WEIGHTS[node] * 2.0
		elif p == opponent:
			pos_score -= POSITION_WEIGHTS[node] * 2.0
			
	score += pos_score
	
	# 3. Capture opportunities bonus
	var ai_moves = RulesEngine.get_all_legal_moves(state)
	var ai_caps: int = 0
	for m in ai_moves:
		if m["is_capture"]:
			ai_caps += 1
	score += ai_caps * 25.0
	
	return score
