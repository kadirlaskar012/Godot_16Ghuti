extends Node

## BackendManager Singleton
## Centralized communication gateway for Nakama Game Server over HTTP and WebSocket.
## Provides authentication dispatch, session management, RPC invocation, and ping measurement.

const BackendConfig = preload("res://scripts/backend/BackendConfig.gd")
const AuthManager = preload("res://scripts/backend/AuthManager.gd")
const CloudSaveManager = preload("res://scripts/backend/CloudSaveManager.gd")
const WalletManager = preload("res://scripts/backend/WalletManager.gd")
## Centralized communication gateway for Nakama Game Server over HTTP and WebSocket.
## Provides authentication dispatch, session management, RPC invocation, and ping measurement.

signal connection_status_changed(is_connected: bool)
signal ping_updated(ping_ms: int)
signal session_ready(user_id: String)
signal server_error(message: String)

var is_connected: bool = false
var session_token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var username: String = ""
var last_ping_ms: int = -1

var _ping_timer: Timer

func _ready() -> void:
	# Initialize periodic ping for latency measurement
	_ping_timer = Timer.new()
	_ping_timer.wait_time = 5.0
	_ping_timer.autostart = false
	_ping_timer.timeout.connect(_measure_ping)
	add_child(_ping_timer)
	
	# Attempt asynchronous background connection & auth
	call_deferred("_try_auto_login")

func _try_auto_login() -> void:
	var auth_res = await AuthManager.authenticate_device(self)
	if auth_res.get("success", false):
		await CloudSaveManager.load_player_profile(self)
		await WalletManager.fetch_wallet_balance(self)
		_set_connected(true)
	else:
		_set_connected(false)

## Central HTTP Request dispatcher to Nakama REST API
func request_http(endpoint: String, method: HTTPClient.Method, payload: Dictionary = {}, use_auth: bool = true) -> Dictionary:
	var http = HTTPRequest.new()
	http.timeout = BackendConfig.get_timeout()
	add_child(http)
	
	var url = "%s%s" % [BackendConfig.get_http_base_url(), endpoint]
	var headers: PackedStringArray = ["Content-Type: application/json", "Accept: application/json"]
	
	if use_auth and not session_token.is_empty():
		headers.append("Authorization: Bearer %s" % session_token)
	else:
		# Use basic auth with server key for unauthenticated endpoints
		var auth_str = Marshalls.utf8_to_base64("%s:" % BackendConfig.get_server_key())
		headers.append("Authorization: Basic %s" % auth_str)
		
	var body_json = JSON.stringify(payload) if not payload.is_empty() else ""
	var err = http.request(url, headers, method, body_json)
	if err != OK:
		http.queue_free()
		_handle_network_failure("Failed to initiate request: %d" % err)
		return {"success": false, "error": "Network request failed"}
		
	var response = await http.request_completed
	http.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var response_body = response[3].get_string_from_utf8()
	
	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_network_failure("Server unreachable or request timed out.")
		return {"success": false, "error": "Server unreachable"}
		
	var parsed = {}
	if not response_body.is_empty():
		var json = JSON.new()
		if json.parse(response_body) == OK and json.data is Dictionary:
			parsed = json.data
			
	if response_code >= 200 and response_code < 300:
		_set_connected(true)
		return {"success": true, "code": response_code, "data": parsed}
	elif response_code == 401:
		_handle_network_failure("Session expired. Refreshing...")
		return {"success": false, "code": 401, "error": "Unauthorized"}
	else:
		var err_msg = parsed.get("message", "Server error %d" % response_code)
		return {"success": false, "code": response_code, "error": err_msg}

## Invokes a registered Nakama Server RPC
func call_rpc(rpc_id: String, payload: Dictionary = {}) -> Dictionary:
	var endpoint = "/v2/rpc/%s" % rpc_id
	var body = {"payload": JSON.stringify(payload)} if not payload.is_empty() else {}
	var res = await request_http(endpoint, HTTPClient.METHOD_POST, body, true)
	if res.get("success", false):
		var raw_payload = res.get("data", {}).get("payload", "")
		if raw_payload is String and not raw_payload.is_empty():
			var json = JSON.new()
			if json.parse(raw_payload) == OK:
				return {"success": true, "data": json.data}
		return {"success": true, "data": res.get("data", {})}
	return res

## Real Round-Trip-Time (RTT) Ping Measurement
func _measure_ping() -> void:
	if not is_connected or session_token.is_empty():
		return
	var t0 = Time.get_ticks_msec()
	var res = await call_rpc("rpc_ping", {"client_time_ms": t0})
	if res.get("success", false):
		var t1 = Time.get_ticks_msec()
		last_ping_ms = int(t1 - t0)
		ping_updated.emit(last_ping_ms)
	else:
		last_ping_ms = -1

func start_ping_loop() -> void:
	_measure_ping()
	_ping_timer.start()

func stop_ping_loop() -> void:
	_ping_timer.stop()

func _set_connected(connected: bool) -> void:
	if is_connected != connected:
		is_connected = connected
		connection_status_changed.emit(is_connected)
		if is_connected:
			start_ping_loop()
		else:
			stop_ping_loop()

func _handle_network_failure(msg: String) -> void:
	_set_connected(false)
	server_error.emit(msg)
