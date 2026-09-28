class_name GameState
extends RefCounted

## Pure Game State representation for 16 Guti / Sholo Guti.
## Designed to be lightweight and fast for AI Minimax simulations and Undo stacks.

var board: PackedByteArray # Size 37, entries: 0 (EMPTY), 1 (PLAYER_1), 2 (PLAYER_2)
var active_player: int = BoardData.Player.PLAYER_1
var p1_pieces: int = BoardData.PIECES_PER_PLAYER
var p2_pieces: int = BoardData.PIECES_PER_PLAYER

# Multiple capture state
var is_in_multi_capture: bool = false
var multi_capture_node: int = -1

# History stack for undo
var history: Array[Dictionary] = []

func _init() -> void:
	board = PackedByteArray()
	board.resize(BoardData.TOTAL_NODES)
	reset_to_start()

func reset_to_start() -> void:
	board.fill(BoardData.Player.NONE)
	for n in BoardData.P1_START_NODES:
		board[n] = BoardData.Player.PLAYER_1
	for n in BoardData.P2_START_NODES:
		board[n] = BoardData.Player.PLAYER_2
		
	active_player = BoardData.Player.PLAYER_1
	p1_pieces = BoardData.PIECES_PER_PLAYER
	p2_pieces = BoardData.PIECES_PER_PLAYER
	is_in_multi_capture = false
	multi_capture_node = -1
	history.clear()

func clone() -> GameState:
	var copy = GameState.new()
	copy.board = self.board.duplicate()
	copy.active_player = self.active_player
	copy.p1_pieces = self.p1_pieces
	copy.p2_pieces = self.p2_pieces
	copy.is_in_multi_capture = self.is_in_multi_capture
	copy.multi_capture_node = self.multi_capture_node
	# History doesn't need to be cloned for AI rollouts
	return copy

func get_piece(node_id: int) -> int:
	if node_id < 0 or node_id >= BoardData.TOTAL_NODES:
		return BoardData.Player.NONE
	return board[node_id]

func set_piece(node_id: int, player: int) -> void:
	if node_id >= 0 and node_id < BoardData.TOTAL_NODES:
		board[node_id] = player

func get_opponent(player: int) -> int:
	if player == BoardData.Player.PLAYER_1:
		return BoardData.Player.PLAYER_2
	elif player == BoardData.Player.PLAYER_2:
		return BoardData.Player.PLAYER_1
	return BoardData.Player.NONE

func get_remaining_pieces(player: int) -> int:
	return p1_pieces if player == BoardData.Player.PLAYER_1 else p2_pieces
