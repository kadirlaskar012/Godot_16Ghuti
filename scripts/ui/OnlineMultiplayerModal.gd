class_name OnlineMultiplayerModal
extends CanvasLayer

## OnlineMultiplayerModal
## Premium mobile UI for Online Matchmaking and Private Room codes.
## Handles server connection states gracefully with offline fallback.

signal closed

const MatchmakingManager = preload("res://scripts/backend/MatchmakingManager.gd")
const AuthManager = preload("res://scripts/backend/AuthManager.gd")

var _is_searching: bool = false
var _search_tween: Tween

@onready var status_label: Label = find_child("StatusLabel", true, false)
@onready var status_indicator: ColorRect = find_child("StatusIndicator", true, false)
@onready var find_match_btn: Button = find_child("FindMatchButton", true, false)
@onready var cancel_search_btn: Button = find_child("CancelSearchButton", true, false)
@onready var searching_container: VBoxContainer = find_child("SearchingContainer", true, false)
@onready var match_card: Control = find_child("QuickMatchCard", true, false)
@onready var create_room_btn: Button = find_child("CreateRoomButton", true, false)
@onready var join_room_btn: Button = find_child("JoinRoomButton", true, false)
@onready var room_code_input: LineEdit = find_child("RoomCodeInput", true, false)
@onready var room_code_display: Label = find_child("RoomCodeDisplay", true, false)
@onready var room_code_container: VBoxContainer = find_child("RoomCodeContainer", true, false)
@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var toast_label: Label = find_child("ToastLabel", true, false)

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	var dim = get_node_or_null("DimOverlay") as Control
	if dim:
		dim.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				_on_close_pressed()
		)
	if find_match_btn:
		find_match_btn.pressed.connect(_on_find_match_pressed)
	if cancel_search_btn:
		cancel_search_btn.pressed.connect(_on_cancel_search_pressed)
	if create_room_btn:
		create_room_btn.pressed.connect(_on_create_room_pressed)
	if join_room_btn:
		join_room_btn.pressed.connect(_on_join_room_pressed)
		
	# Hook Backend signals
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		bm.connection_status_changed.connect(_on_backend_status_changed)
		bm.ping_updated.connect(_on_ping_updated)
		_update_status_ui(bm.is_connected, bm.last_ping_ms)
	else:
		_update_status_ui(false, -1)
		
	# Safe area
	var safe = SafeAreaHelper.get_safe_margins()
	var safe_area = find_child("SafeArea", true, false) as MarginContainer
	if safe_area:
		safe_area.add_theme_constant_override("margin_top", int(max(safe["top"], 36.0)))
		safe_area.add_theme_constant_override("margin_bottom", int(max(safe["bottom"], 24.0)))

func _update_status_ui(connected: bool, ping_ms: int) -> void:
	if not status_label or not status_indicator:
		return
	if connected:
		status_indicator.color = Color(0.2, 0.85, 0.4) # Green
		if ping_ms >= 0:
			status_label.text = "Server Connected (Ping: %d ms)" % ping_ms
		else:
			status_label.text = "Server Connected"
		if find_match_btn: find_match_btn.disabled = false
		if create_room_btn: create_room_btn.disabled = false
		if join_room_btn: join_room_btn.disabled = false
	else:
		status_indicator.color = Color(0.9, 0.3, 0.3) # Red
		status_label.text = "Server Offline (Tap to Retry)"
		if find_match_btn: find_match_btn.disabled = false
		if create_room_btn: create_room_btn.disabled = false
		if join_room_btn: join_room_btn.disabled = false

func _on_backend_status_changed(connected: bool) -> void:
	var bm = get_node_or_null("/root/BackendManager")
	_update_status_ui(connected, bm.last_ping_ms if bm else -1)

func _on_ping_updated(ping_ms: int) -> void:
	var bm = get_node_or_null("/root/BackendManager")
	_update_status_ui(bm.is_connected if bm else false, ping_ms)

func _on_find_match_pressed() -> void:
	AudioManager.play_sfx("click")
	HapticManager.vibrate_selection()
	
	var bm = get_node_or_null("/root/BackendManager")
	if not bm or not bm.is_connected:
		_show_toast("Connecting to server...")
		if bm:
			await AuthManager.authenticate_device(bm)
		if not bm or not bm.is_connected:
			_show_toast("Online services are temporarily unavailable.\nOffline modes work anytime!")
			return
			
	_start_searching_ui()
	
	var res = await MatchmakingManager.find_match(bm)
	if res.get("success", false):
		var match_id = res.get("match_id", "")
		_show_toast("Opponent Found! Starting Match...")
		await get_tree().create_timer(1.0).timeout
		_start_online_game(match_id)
	else:
		_stop_searching_ui()
		_show_toast(res.get("error", "Matchmaking search failed."))

func _on_cancel_search_pressed() -> void:
	AudioManager.play_sfx("click")
	_stop_searching_ui()

func _on_create_room_pressed() -> void:
	AudioManager.play_sfx("click")
	HapticManager.vibrate_selection()
	
	var bm = get_node_or_null("/root/BackendManager")
	if not bm or not bm.is_connected:
		_show_toast("Online services are temporarily unavailable.")
		return
		
	var res = await MatchmakingManager.create_room(bm)
	if res.get("success", false):
		var code = res.get("room_code", "")
		var match_id = res.get("match_id", "")
		if room_code_display:
			room_code_display.text = code
		if room_code_container:
			room_code_container.visible = true
		_show_toast("Room %s created! Share this code with your friend." % code)
		
		# Join the match socket as host
		var om = get_node_or_null("/root/OnlineMatchManager")
		if om:
			om.join_match(match_id)
			om.match_started.connect(func(_idx, _opp):
				_start_online_game(match_id)
			, CONNECT_ONE_SHOT)
	else:
		_show_toast(res.get("error", "Failed to create room."))

func _on_join_room_pressed() -> void:
	AudioManager.play_sfx("click")
	HapticManager.vibrate_selection()
	
	var bm = get_node_or_null("/root/BackendManager")
	if not bm or not bm.is_connected:
		_show_toast("Online services are temporarily unavailable.")
		return
		
	var code = room_code_input.text.strip_edges().to_upper() if room_code_input else ""
	if code.length() < 4:
		_show_toast("Please enter a valid 6-character room code.")
		return
		
	_show_toast("Joining room %s..." % code)
	var res = await MatchmakingManager.join_room(bm, code)
	if res.get("success", false):
		var match_id = res.get("match_id", "")
		_show_toast("Room joined! Starting game...")
		_start_online_game(match_id)
	else:
		_show_toast(res.get("error", "Room not found."))

func _start_online_game(match_id: String) -> void:
	var om = get_node_or_null("/root/OnlineMatchManager")
	if om:
		om.join_match(match_id)
	GameManager.start_match(GameManager.GameMode.ONLINE_MULTIPLAYER)
	closed.emit()
	queue_free()

func _start_searching_ui() -> void:
	_is_searching = true
	if searching_container: searching_container.visible = true
	if find_match_btn: find_match_btn.visible = false
	
	var spinner = find_child("SearchSpinner", true, false)
	if spinner:
		_search_tween = create_tween().set_loops()
		_search_tween.tween_property(spinner, "rotation", TAU, 1.2).from(0.0)

func _stop_searching_ui() -> void:
	_is_searching = false
	if searching_container: searching_container.visible = false
	if find_match_btn: find_match_btn.visible = true
	if _search_tween:
		_search_tween.kill()

func _show_toast(msg: String) -> void:
	if toast_label:
		toast_label.text = msg
		toast_label.visible = true
		var t = create_tween()
		toast_label.modulate.a = 1.0
		t.tween_interval(2.5)
		t.tween_property(toast_label, "modulate:a", 0.0, 0.4)
		t.tween_callback(func(): toast_label.visible = false)

func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	_stop_searching_ui()
	closed.emit()
	queue_free()
