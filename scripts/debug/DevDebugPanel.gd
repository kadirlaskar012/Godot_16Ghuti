class_name DevDebugPanel
extends CanvasLayer

## DevDebugPanel
## Development-only inspection and testing dashboard.
## Completely stripped from production release builds.

const BackendConfig = preload("res://scripts/backend/BackendConfig.gd")
const AuthManager = preload("res://scripts/backend/AuthManager.gd")
const CloudSaveManager = preload("res://scripts/backend/CloudSaveManager.gd")
const WalletManager = preload("res://scripts/backend/WalletManager.gd")
const MatchmakingManager = preload("res://scripts/backend/MatchmakingManager.gd")

@onready var panel_container: Control = $Panel
@onready var toggle_btn: Button = $ToggleButton

@onready var env_label: Label = find_child("EnvLabel", true, false)
@onready var status_label: Label = find_child("StatusLabel", true, false)
@onready var user_label: Label = find_child("UserLabel", true, false)
@onready var ping_label: Label = find_child("PingLabel", true, false)
@onready var rpc_label: Label = find_child("RpcLabel", true, false)
@onready var match_label: Label = find_child("MatchLabel", true, false)
@onready var version_label: Label = find_child("VersionLabel", true, false)

@onready var reconnect_btn: Button = find_child("ReconnectBtn", true, false)
@onready var refresh_profile_btn: Button = find_child("RefreshProfileBtn", true, false)
@onready var refresh_wallet_btn: Button = find_child("RefreshWalletBtn", true, false)
@onready var test_rpc_btn: Button = find_child("TestRpcBtn", true, false)
@onready var test_matchmaking_btn: Button = find_child("TestMatchmakingBtn", true, false)
@onready var clear_session_btn: Button = find_child("ClearSessionBtn", true, false)

var is_expanded: bool = false

func _ready() -> void:
	# Strip panel completely in production release builds
	if not OS.is_debug_build():
		queue_free()
		return
		
	layer = 100
	panel_container.visible = false
	
	if toggle_btn:
		toggle_btn.pressed.connect(_toggle_panel)
	if reconnect_btn:
		reconnect_btn.pressed.connect(_on_reconnect_pressed)
	if refresh_profile_btn:
		refresh_profile_btn.pressed.connect(_on_refresh_profile_pressed)
	if refresh_wallet_btn:
		refresh_wallet_btn.pressed.connect(_on_refresh_wallet_pressed)
	if test_rpc_btn:
		test_rpc_btn.pressed.connect(_on_test_rpc_pressed)
	if test_matchmaking_btn:
		test_matchmaking_btn.pressed.connect(_on_test_matchmaking_pressed)
	if clear_session_btn:
		clear_session_btn.pressed.connect(_on_clear_session_pressed)
		
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		bm.ping_updated.connect(_on_ping_updated)
		bm.connection_status_changed.connect(func(_c): _update_metrics())
		
	_update_metrics()

func _toggle_panel() -> void:
	is_expanded = !is_expanded
	panel_container.visible = is_expanded
	toggle_btn.text = "▲ DEV" if is_expanded else "▼ DEV"
	if is_expanded:
		_update_metrics()

func _update_metrics() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	var om = get_node_or_null("/root/OnlineMatchManager")
	
	if env_label:
		env_label.text = "ENV: %s" % BackendConfig.get_env_name()
	if version_label:
		version_label.text = "CLIENT VER: %s (Min: %s)" % [BackendConfig.CLIENT_VERSION, BackendConfig.MIN_SUPPORTED_VERSION]
	if status_label:
		var st_text = "CONNECTED" if (bm and bm.is_connected) else "OFFLINE / UNREACHABLE"
		status_label.text = "STATUS: %s" % st_text
	if user_label:
		var uid = bm.user_id if bm else "None"
		user_label.text = "USER ID: %s" % uid
	if ping_label:
		var p = bm.last_ping_ms if bm else -1
		ping_label.text = "PING: %d ms" % p if p >= 0 else "PING: -- ms"
	if match_label:
		var mid = om.current_match_id if om else ""
		match_label.text = "MATCH: %s" % (mid if not mid.is_empty() else "None (Offline Mode)")

func _on_ping_updated(ping_ms: int) -> void:
	if ping_label:
		ping_label.text = "PING: %d ms" % ping_ms

func _on_reconnect_pressed() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		rpc_label.text = "RPC: Reconnecting..."
		var res = await AuthManager.authenticate_device(bm)
		rpc_label.text = "RPC Auth: %s" % ("OK" if res.get("success", false) else res.get("error", "FAIL"))
		_update_metrics()

func _on_refresh_profile_pressed() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		rpc_label.text = "RPC: Loading Cloud Profile..."
		var res = await CloudSaveManager.load_player_profile(bm)
		rpc_label.text = "RPC Profile: %s" % ("Synced" if res.get("success", false) else "Error")
		_update_metrics()

func _on_refresh_wallet_pressed() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		rpc_label.text = "RPC: Refreshing Wallet..."
		var res = await WalletManager.fetch_wallet_balance(bm)
		rpc_label.text = "RPC Wallet: Balance %s" % str(res.get("balance", "Error"))
		_update_metrics()

func _on_test_rpc_pressed() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		rpc_label.text = "RPC: Sending ping RPC..."
		var t0 = Time.get_ticks_msec()
		var res = await bm.call_rpc("rpc_ping", {"echo": "test"})
		var dur = Time.get_ticks_msec() - t0
		rpc_label.text = "RPC Ping: %d ms (Res: %s)" % [dur, "OK" if res.get("success", false) else "ERR"]
		_update_metrics()

func _on_test_matchmaking_pressed() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		rpc_label.text = "RPC: Finding 1v1 match..."
		var res = await MatchmakingManager.find_match(bm)
		rpc_label.text = "RPC Match: ID %s" % res.get("match_id", res.get("error", "FAIL"))
		_update_metrics()

func _on_clear_session_pressed() -> void:
	var bm = get_node_or_null("/root/BackendManager")
	if bm:
		AuthManager.logout(bm)
		rpc_label.text = "Local session cleared."
		_update_metrics()
