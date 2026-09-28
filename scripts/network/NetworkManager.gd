class_name NetworkManager
extends Node

## NetworkManager provides the architectural abstraction layer for Online Multiplayer.
## It handles serialization/deserialization of game moves and state, matchmaking hooks,
## and remote message dispatching without coupling networking logic into BoardManager or RulesEngine.

enum ConnectionStatus {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	FINDING_MATCH,
	IN_MATCH,
	ERROR
}

signal status_changed(new_status: ConnectionStatus)
signal match_found(match_info: Dictionary)
signal opponent_moved(move_data: Dictionary)
signal opponent_left(reason: String)
signal sync_error(message: String)

var current_status: ConnectionStatus = ConnectionStatus.DISCONNECTED
var room_id: String = ""
var local_player_id: String = ""
var remote_player_name: String = "Online Opponent"
var is_host: bool = false

func connect_to_multiplayer_server(server_url: String = "") -> void:
	_set_status(ConnectionStatus.CONNECTING)
	# Future implementation: Initialize WebSocketClient / WebRTC / Nakama / Photon client
	print("[NetworkManager] Connecting to multiplayer server at: %s" % (server_url if server_url != "" else "default_cluster"))
	
	# Architecture hook: simulated handshake
	get_tree().create_timer(1.0).timeout.connect(func():
		_set_status(ConnectionStatus.CONNECTED)
	)

func find_match(ranked: bool = false) -> void:
	if current_status != ConnectionStatus.CONNECTED:
		push_warning("[NetworkManager] Must be connected before finding a match.")
		return
		
	_set_status(ConnectionStatus.FINDING_MATCH)
	print("[NetworkManager] Searching for %s match..." % ("Ranked" if ranked else "Casual"))

func send_move(move: Dictionary) -> void:
	if current_status != ConnectionStatus.IN_MATCH:
		return
	var payload = serialize_move(move)
	_send_payload("PLAYER_MOVE", payload)

func receive_remote_move(payload: Dictionary) -> Dictionary:
	var move = deserialize_move(payload)
	opponent_moved.emit(move)
	return move

## Serializes a move dictionary into a lightweight network packet
static func serialize_move(move: Dictionary) -> Dictionary:
	return {
		"from": move.get("from", -1),
		"to": move.get("to", -1),
		"is_capture": move.get("is_capture", false),
		"captured": move.get("captured", -1),
		"timestamp": Time.get_unix_time_from_system()
	}

## Deserializes a network packet back into a verified move dictionary
static func deserialize_move(payload: Dictionary) -> Dictionary:
	return {
		"from": int(payload.get("from", -1)),
		"to": int(payload.get("to", -1)),
		"is_capture": bool(payload.get("is_capture", false)),
		"captured": int(payload.get("captured", -1))
	}

## Serializes complete game state for re-synchronization or reconnects
static func serialize_state(state: GameState) -> Dictionary:
	var board_array: Array[int] = []
	for i in range(BoardData.TOTAL_NODES):
		board_array.append(state.get_piece(i))
	return {
		"board": board_array,
		"active_player": state.active_player,
		"p1_remaining": state.p1_remaining,
		"p2_remaining": state.p2_remaining,
		"is_chain_capture": state.is_chain_capture,
		"chain_piece_node": state.chain_piece_node
	}

## Deserializes state packet back into a GameState instance
static func deserialize_state(data: Dictionary) -> GameState:
	var state = GameState.new()
	var arr = data.get("board", [])
	for i in range(mini(arr.size(), BoardData.TOTAL_NODES)):
		state.set_piece(i, int(arr[i]))
	state.active_player = int(data.get("active_player", BoardData.Player.PLAYER_1))
	state.p1_remaining = int(data.get("p1_remaining", 16))
	state.p2_remaining = int(data.get("p2_remaining", 16))
	state.is_chain_capture = bool(data.get("is_chain_capture", false))
	state.chain_piece_node = int(data.get("chain_piece_node", -1))
	return state

func _send_payload(event: String, data: Dictionary) -> void:
	print("[NetworkManager] Outgoing [%s]: %s" % [event, JSON.stringify(data)])

func _set_status(new_status: ConnectionStatus) -> void:
	current_status = new_status
	status_changed.emit(new_status)
