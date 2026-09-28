class_name RulesEngine
extends RefCounted

## Rules Engine for 16 Guti / Sholo Guti
## Implements movement, jumping/capture, multiple capture chains, win conditions, and undo.

enum GameResult {
	IN_PROGRESS = 0,
	PLAYER_1_WINS = 1,
	PLAYER_2_WINS = 2,
	DRAW = 3
}

# Get all legal captures possible for a specific piece
static func get_captures_for_piece(state: GameState, from_node: int) -> Array[Dictionary]:
	var legal_captures: Array[Dictionary] = []
	var piece_owner: int = state.get_piece(from_node)
	if piece_owner == BoardData.Player.NONE:
		return legal_captures
		
	var opponent: int = state.get_opponent(piece_owner)
	if not BoardData.JUMP_TABLE.has(from_node):
		return legal_captures
		
	var jump_targets: Dictionary = BoardData.JUMP_TABLE[from_node]
	for over_node in jump_targets.keys():
		var land_node: int = jump_targets[over_node]
		# Check if over_node has an opponent piece and land_node is empty
		if state.get_piece(over_node) == opponent and state.get_piece(land_node) == BoardData.Player.NONE:
			legal_captures.append({
				"from": from_node,
				"to": land_node,
				"is_capture": true,
				"captured": over_node
			})
			
	return legal_captures

# Get all 1-step adjacent moves for a specific piece
static func get_simple_moves_for_piece(state: GameState, from_node: int) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	var piece_owner: int = state.get_piece(from_node)
	if piece_owner == BoardData.Player.NONE:
		return moves
		
	if not BoardData.ADJACENCY.has(from_node):
		return moves
		
	var neighbors: Array = BoardData.ADJACENCY[from_node]
	for target in neighbors:
		if state.get_piece(target) == BoardData.Player.NONE:
			moves.append({
				"from": from_node,
				"to": target,
				"is_capture": false,
				"captured": -1
			})
			
	return moves

# Checks if the active player has ANY capture available anywhere on the board
static func has_any_capture_for_player(state: GameState, player: int) -> bool:
	for node in range(BoardData.TOTAL_NODES):
		if state.get_piece(node) == player:
			var caps = get_captures_for_piece(state, node)
			if caps.size() > 0:
				return true
	return false

# Get all legal moves for a specific piece given current state
static func get_legal_moves_for_piece(state: GameState, from_node: int, forced_capture: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if state.get_piece(from_node) != state.active_player:
		return result
		
	# If in multi-capture chain, ONLY the designated piece can move, and ONLY captures are legal
	if state.is_in_multi_capture:
		if from_node != state.multi_capture_node:
			return result
		return get_captures_for_piece(state, from_node)
		
	var captures: Array[Dictionary] = get_captures_for_piece(state, from_node)
	
	if forced_capture and has_any_capture_for_player(state, state.active_player):
		# If forced capture is enabled and any capture is possible on board, must capture
		return captures
		
	result = captures.duplicate()
	result.append_array(get_simple_moves_for_piece(state, from_node))
	return result

# Get all legal moves for the current active player
static func get_all_legal_moves(state: GameState, forced_capture: bool = false) -> Array[Dictionary]:
	var all_moves: Array[Dictionary] = []
	
	# If currently in multi-capture, only moves for multi_capture_node are valid
	if state.is_in_multi_capture:
		return get_captures_for_piece(state, state.multi_capture_node)
		
	var must_capture: bool = forced_capture and has_any_capture_for_player(state, state.active_player)
	
	for node in range(BoardData.TOTAL_NODES):
		if state.get_piece(node) == state.active_player:
			if must_capture:
				all_moves.append_array(get_captures_for_piece(state, node))
			else:
				all_moves.append_array(get_legal_moves_for_piece(state, node, false))
				
	return all_moves

# Apply a move to the game state
static func apply_move(state: GameState, move: Dictionary, allow_multi_capture: bool = true) -> Dictionary:
	var from_node: int = move["from"]
	var to_node: int = move["to"]
	var is_capture: bool = move["is_capture"]
	var captured_node: int = move.get("captured", -1)
	var active_p: int = state.active_player
	
	# Record history for undo
	var history_entry: Dictionary = {
		"from": from_node,
		"to": to_node,
		"is_capture": is_capture,
		"captured_node": captured_node,
		"captured_piece": state.get_piece(captured_node) if is_capture else BoardData.Player.NONE,
		"player": active_p,
		"prev_multi_capture": state.is_in_multi_capture,
		"prev_multi_node": state.multi_capture_node,
		"turn_changed": false
	}
	
	# Move piece
	state.set_piece(from_node, BoardData.Player.NONE)
	state.set_piece(to_node, active_p)
	
	var multi_capture_available: bool = false
	
	if is_capture:
		# Remove captured opponent piece
		state.set_piece(captured_node, BoardData.Player.NONE)
		if active_p == BoardData.Player.PLAYER_1:
			state.p2_pieces -= 1
		else:
			state.p1_pieces -= 1
			
		# Check for multiple capture continuation
		if allow_multi_capture:
			var further_captures = get_captures_for_piece(state, to_node)
			if further_captures.size() > 0:
				multi_capture_available = true
				state.is_in_multi_capture = true
				state.multi_capture_node = to_node
				history_entry["turn_changed"] = false
				state.history.append(history_entry)
				return {
					"success": true,
					"is_capture": true,
					"captured_node": captured_node,
					"turn_ended": false,
					"multi_capture_available": true,
					"multi_capture_node": to_node
				}
				
	# If not continuing multi-capture, turn ends and switches
	state.is_in_multi_capture = false
	state.multi_capture_node = -1
	state.active_player = state.get_opponent(active_p)
	history_entry["turn_changed"] = true
	state.history.append(history_entry)
	
	return {
		"success": true,
		"is_capture": is_capture,
		"captured_node": captured_node,
		"turn_ended": true,
		"multi_capture_available": false,
		"multi_capture_node": -1
	}

# Undo the last move
static func undo_move(state: GameState) -> bool:
	if state.history.is_empty():
		return false
		
	var entry: Dictionary = state.history.pop_back()
	var from_node: int = entry["from"]
	var to_node: int = entry["to"]
	var is_capture: bool = entry["is_capture"]
	var captured_node: int = entry["captured_node"]
	var captured_piece: int = entry["captured_piece"]
	var player: int = entry["player"]
	
	# Reverse piece movement
	state.set_piece(to_node, BoardData.Player.NONE)
	state.set_piece(from_node, player)
	
	# Restore captured piece if any
	if is_capture and captured_node >= 0:
		state.set_piece(captured_node, captured_piece)
		if player == BoardData.Player.PLAYER_1:
			state.p2_pieces += 1
		else:
			state.p1_pieces += 1
			
	# Restore state flags
	state.active_player = player
	state.is_in_multi_capture = entry["prev_multi_capture"]
	state.multi_capture_node = entry["prev_multi_node"]
	
	return true

# Check win / end condition
static func check_game_over(state: GameState, forced_capture: bool = false) -> Dictionary:
	# 1. Elimination win
	if state.p1_pieces <= 0:
		return {
			"is_game_over": true,
			"winner": BoardData.Player.PLAYER_2,
			"reason": "All Player 1 pieces captured!"
		}
	if state.p2_pieces <= 0:
		return {
			"is_game_over": true,
			"winner": BoardData.Player.PLAYER_1,
			"reason": "All Player 2 pieces captured!"
		}
		
	# 2. Immobilization / Blocked (Stalemate win)
	var legal_moves = get_all_legal_moves(state, forced_capture)
	if legal_moves.is_empty():
		var winner: int = state.get_opponent(state.active_player)
		var p_name = "Player 1" if state.active_player == BoardData.Player.PLAYER_1 else "Player 2"
		return {
			"is_game_over": true,
			"winner": winner,
			"reason": "%s has no legal moves left!" % p_name
		}
		
	return {
		"is_game_over": false,
		"winner": BoardData.Player.NONE,
		"reason": ""
	}
