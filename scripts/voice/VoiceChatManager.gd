extends Node

## VoiceChatManager
## 1-to-1 WebRTC Voice Chat for Online Multiplayer using Nakama for Signaling.
## Fully decoupled and fail-safe: Voice issues NEVER break gameplay.
## Complies with privacy rules: mic default OFF, explicit permission, zero recording.

enum VoiceStatus {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	FAILED
}

signal status_changed(new_status: VoiceStatus)
signal speaking_changed(is_speaking: bool)
signal opponent_speaking_changed(is_speaking: bool)
signal permission_result(granted: bool)

var current_status: VoiceStatus = VoiceStatus.DISCONNECTED
var is_mic_enabled: bool = false
var is_speaker_enabled: bool = true
var is_opponent_muted: bool = false
var is_local_speaking: bool = false
var is_opponent_speaking: bool = false

var _peer_connection: WebRTCPeerConnection
var _online_manager: Node

func _ready() -> void:
	_online_manager = get_node_or_null("/root/OnlineMatchManager")
	if _online_manager:
		if _online_manager.has_signal("webrtc_signal_received"):
			_online_manager.webrtc_signal_received.connect(_on_webrtc_signal_received)
		if _online_manager.has_signal("voice_status_received"):
			_online_manager.voice_status_received.connect(_on_voice_status_received)

func initialize_session() -> void:
	_cleanup_session()
	_peer_connection = WebRTCPeerConnection.new()
	
	# ICE server configuration (STUN/TURN)
	var config = {
		"iceServers": [
			{"urls": ["stun:stun.l.google.com:19302"]},
			{"urls": ["stun:stun1.l.google.com:19302"]}
		]
	}
	_peer_connection.initialize(config)
	_peer_connection.session_description_created.connect(_on_session_description_created)
	_peer_connection.ice_candidate_created.connect(_on_ice_candidate_created)
	
	_set_status(VoiceStatus.CONNECTING)

func toggle_microphone() -> void:
	if not is_mic_enabled:
		enable_microphone()
	else:
		disable_microphone()

func enable_microphone() -> void:
	# Android runtime microphone permission check
	if OS.get_name() == "Android":
		var perm = "android.permission.RECORD_AUDIO"
		var granted = OS.get_granted_permissions()
		if not perm in granted:
			OS.request_permission(perm)
			is_mic_enabled = false
			permission_result.emit(false)
			return

	is_mic_enabled = true
	if _online_manager and _online_manager.has_method("send_voice_status"):
		_online_manager.send_voice_status(true, is_local_speaking)
	_sync_audio_bus()

func disable_microphone() -> void:
	is_mic_enabled = false
	is_local_speaking = false
	if _online_manager and _online_manager.has_method("send_voice_status"):
		_online_manager.send_voice_status(false, false)
	_sync_audio_bus()

func set_speaker_enabled(enabled: bool) -> void:
	is_speaker_enabled = enabled
	_sync_audio_bus()

func set_opponent_muted(muted: bool) -> void:
	is_opponent_muted = muted
	_sync_audio_bus()

func set_voice_volume(volume_linear: float) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("set_bus_volume"):
		am.set_bus_volume("Voice", volume_linear)

func _sync_audio_bus() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("set_bus_mute"):
		var should_mute_voice = not is_speaker_enabled or is_opponent_muted
		am.set_bus_mute("Voice", should_mute_voice)

func _on_session_description_created(type: String, sdp: String) -> void:
	if not _peer_connection:
		return
	_peer_connection.set_local_description(type, sdp)
	if _online_manager and _online_manager.has_method("send_webrtc_signal"):
		_online_manager.send_webrtc_signal({
			"type": type,
			"sdp": sdp
		})

func _on_ice_candidate_created(media: String, index: int, name_str: String) -> void:
	if _online_manager and _online_manager.has_method("send_webrtc_signal"):
		_online_manager.send_webrtc_signal({
			"type": "candidate",
			"media": media,
			"index": index,
			"name": name_str
		})

func _on_webrtc_signal_received(signal_payload: Dictionary) -> void:
	if not _peer_connection:
		initialize_session()
		
	var sig_type = signal_payload.get("type", "")
	match sig_type:
		"offer":
			var sdp = signal_payload.get("sdp", "")
			_peer_connection.set_remote_description("offer", sdp)
			_peer_connection.create_answer()
		"answer":
			var sdp = signal_payload.get("sdp", "")
			_peer_connection.set_remote_description("answer", sdp)
			_set_status(VoiceStatus.CONNECTED)
		"candidate":
			var media = signal_payload.get("media", "")
			var idx = int(signal_payload.get("index", 0))
			var cand_name = signal_payload.get("name", "")
			_peer_connection.add_ice_candidate(media, idx, cand_name)

func _on_voice_status_received(payload: Dictionary) -> void:
	var speaking = bool(payload.get("is_speaking", false))
	if speaking != is_opponent_speaking:
		is_opponent_speaking = speaking
		opponent_speaking_changed.emit(speaking)

func _set_status(st: VoiceStatus) -> void:
	current_status = st
	status_changed.emit(st)

func end_session() -> void:
	disable_microphone()
	_cleanup_session()
	_set_status(VoiceStatus.DISCONNECTED)

func _cleanup_session() -> void:
	if _peer_connection:
		_peer_connection.close()
		_peer_connection = null
	is_local_speaking = false
	is_opponent_speaking = false
