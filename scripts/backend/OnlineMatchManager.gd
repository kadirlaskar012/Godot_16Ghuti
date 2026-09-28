extends Node

## OnlineMatchManager Singleton
## Manages real-time server-authoritative multiplayer match loop via Nakama WebSocket.
## Zero client authority: sends MOVE_REQUEST, receives server-validated updates.

const BackendConfig = preload("res://scripts/backend/BackendConfig.gd")
const AntiCheatManager = preload("res://scripts/backend/AntiCheatManager.gd")
## Manages real-time server-authoritative multiplayer match loop via Nakama WebSocket.
## Zero client authority: sends MOVE_REQUEST, receives server-validated updates.

enum ReconnectState {
	CONNECTED,
	CONNECTING,
	DISCONNECTED,
	RECONNECTING,
	RECONNECTED
}

enum MatchOpCode {
	OP_MOVE_REQUEST = 1,
	OP_MOVE_ACCEPTED = 2,
	OP_MOVE_REJECTED = 3,
	OP_STATE_SYNC = 4,
	OP_RESIGN = 5,
	OP_PING = 6,
	OP_TIMER_TICK = 7,
	OP_MATCH_OVER = 8,
	OP_PLAYER_RECONNECTED = 9,
	OP_PLAYER_DISCONNECTED = 10,
	OP_CHAT_MESSAGE = 11,
	OP_EMOJI_REACTION = 12,
	OP_WEBRTC_SIGNAL = 13,
	OP_VOICE_STATUS = 14
}

signal match_started(assigned_player: int, opponent_name: String)
signal move_accepted(move_data: Dictionary)
signal move_rejected(reason: String)
signal state_synced(sync_data: Dictionary)
signal timer_ticked(remaining_seconds: int)
signal turn_timer_ticked(timer_payload: Dictionary)
signal match_finished(result_data: Dictionary)
signal reconnect_state_changed(state: ReconnectState)
signal chat_received(sender_name: String, message_text: String)
signal emoji_received(player_id: int, emoji_symbol: String)
signal webrtc_signal_received(signal_payload: Dictionary)
signal voice_status_received(status_payload: Dictionary)

var current_match_id: String = ""
var local_player_index: int = BoardData.Player.PLAYER_1
var opponent_name: String = "Online Player"
var current_reconnect_state: ReconnectState = ReconnectState.DISCONNECTED

var _socket: WebSocketPeer
var _backend: BackendManager
var _reconnect_attempts: int = 0
const MAX_RECONNECT_ATTEMPTS: int = 5

func _ready() -> void:
	_socket = WebSocketPeer.new()
	_backend = get_node_or_null("/root/BackendManager")

func _process(_delta: float) -> void:
	if not _socket or current_match_id.is_empty():
		return
		
	_socket.poll()
	var state = _socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if current_reconnect_state != ReconnectState.CONNECTED:
			_set_reconnect_state(ReconnectState.CONNECTED)
			_reconnect_attempts = 0
			
		while _socket.get_available_packet_count() > 0:
			var pkt = _socket.get_packet()
			var msg_str = pkt.get_string_from_utf8()
			_process_socket_message(msg_str)
	elif state == WebSocketPeer.STATE_CLOSED:
		if current_reconnect_state == ReconnectState.CONNECTED or current_reconnect_state == ReconnectState.CONNECTING:
			if _reconnect_attempts < MAX_RECONNECT_ATTEMPTS:
				_set_reconnect_state(ReconnectState.RECONNECTING)
				_attempt_reconnect()
			else:
				_set_reconnect_state(ReconnectState.DISCONNECTED)
				current_match_id = ""

func initialize(backend: BackendManager) -> void:
	_backend = backend

func join_match(match_id: String) -> void:
	current_match_id = match_id
	_set_reconnect_state(ReconnectState.CONNECTING)
	
	var ws_url = "%s?token=%s&lang=en&status=true" % [
		BackendConfig.get_ws_url(),
		_backend.session_token
	]
	
	var err = _socket.connect_to_url(ws_url)
	if err != OK:
		_set_reconnect_state(ReconnectState.DISCONNECTED)
		push_error("[OnlineMatchManager] WebSocket connection failed: %d" % err)

func send_move_action(from_node: int, to_node: int, is_capture: bool, captured_node: int) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_warning("[OnlineMatchManager] Cannot send move: socket not open")
		return
		
	var seq = AntiCheatManager.get_next_sequence()
	var payload = {
		"from": from_node,
		"to": to_node,
		"is_capture": is_capture,
		"captured": captured_node,
		"client_seq": seq
	}
	
	_send_match_data(MatchOpCode.OP_MOVE_REQUEST, payload)

func resign_match() -> void:
	_send_match_data(MatchOpCode.OP_RESIGN, {})

func _send_match_data(op_code: int, data: Dictionary) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
		
	# Format according to Nakama envelope
	var match_data_envelope = {
		"match_data_send": {
			"match_id": current_match_id,
			"op_code": str(op_code),
			"data": Marshalls.utf8_to_base64(JSON.stringify(data)),
			"presences": []
		}
	}
	_socket.send_text(JSON.stringify(match_data_envelope))

func _process_socket_message(text: String) -> void:
	var json = JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return
		
	var d = json.data
	
	# Handle match data envelopes from Nakama
	if d.has("match_data"):
		var md = d["match_data"]
		var op = int(md.get("op_code", 0))
		var b64_data = md.get("data", "")
		var raw_str = Marshalls.base64_to_utf8(b64_data)
		var p_json = JSON.new()
		var payload: Dictionary = {}
		if p_json.parse(raw_str) == OK and p_json.data is Dictionary:
			payload = p_json.data
			
		match op:
			MatchOpCode.OP_STATE_SYNC:
				if payload.has("player_index"):
					local_player_index = int(payload["player_index"])
					opponent_name = str(payload.get("opponent_name", "Online Player"))
					match_started.emit(local_player_index, opponent_name)
				state_synced.emit(payload)
				if payload.has("turn_remaining_seconds"):
					turn_timer_ticked.emit(payload)
			MatchOpCode.OP_MOVE_ACCEPTED:
				move_accepted.emit(payload)
				if payload.has("turn_remaining_seconds"):
					turn_timer_ticked.emit(payload)
			MatchOpCode.OP_MOVE_REJECTED:
				move_rejected.emit(payload.get("reason", "Move rejected by server"))
			MatchOpCode.OP_TIMER_TICK:
				var rem = int(payload.get("match_remaining_seconds", payload.get("remaining_seconds", 300)))
				timer_ticked.emit(rem)
				turn_timer_ticked.emit(payload)
			MatchOpCode.OP_MATCH_OVER:
				match_finished.emit(payload)
			MatchOpCode.OP_PLAYER_RECONNECTED:
				_set_reconnect_state(ReconnectState.RECONNECTED)
			MatchOpCode.OP_PLAYER_DISCONNECTED:
				pass
			MatchOpCode.OP_CHAT_MESSAGE:
				var sender = str(payload.get("sender_name", "Opponent"))
				var text_msg = str(payload.get("text", ""))
				chat_received.emit(sender, text_msg)
			MatchOpCode.OP_EMOJI_REACTION:
				var p_idx = int(payload.get("player_index", 2))
				var em = str(payload.get("emoji", ""))
				emoji_received.emit(p_idx, em)
			MatchOpCode.OP_WEBRTC_SIGNAL:
				webrtc_signal_received.emit(payload)
			MatchOpCode.OP_VOICE_STATUS:
				voice_status_received.emit(payload)

func send_chat_message(message_text: String) -> void:
	var payload = {
		"sender_name": SaveManager.player_data.player_name if (SaveManager and SaveManager.player_data) else "Player",
		"text": message_text
	}
	_send_match_data(MatchOpCode.OP_CHAT_MESSAGE, payload)

func send_emoji_reaction(emoji_symbol: String) -> void:
	var payload = {
		"player_index": local_player_index,
		"emoji": emoji_symbol
	}
	_send_match_data(MatchOpCode.OP_EMOJI_REACTION, payload)

func send_webrtc_signal(signal_data: Dictionary) -> void:
	_send_match_data(MatchOpCode.OP_WEBRTC_SIGNAL, signal_data)

func send_voice_status(is_mic_on: bool, is_speaking: bool) -> void:
	var payload = {
		"player_index": local_player_index,
		"is_mic_on": is_mic_on,
		"is_speaking": is_speaking
	}
	_send_match_data(MatchOpCode.OP_VOICE_STATUS, payload)

func _attempt_reconnect() -> void:
	_reconnect_attempts += 1
	var delay = minf(8.0, 1.5 * _reconnect_attempts)
	await get_tree().create_timer(delay).timeout
	if not current_match_id.is_empty() and current_reconnect_state == ReconnectState.RECONNECTING:
		join_match(current_match_id)

func _set_reconnect_state(st: ReconnectState) -> void:
	current_reconnect_state = st
	reconnect_state_changed.emit(st)

func disconnect_match() -> void:
	if _socket:
		_socket.close()
	current_match_id = ""
	_reconnect_attempts = 0
	_set_reconnect_state(ReconnectState.DISCONNECTED)
