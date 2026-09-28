class_name AuthManager
extends RefCounted

## AuthManager
## Handles Guest/Device authentication, persistent session management,
## session token refresh, and future account linking.

const BackendConfig = preload("res://scripts/backend/BackendConfig.gd")
const SESSION_FILE_PATH = "user://nakama_session.json"

static func authenticate_device(backend: Node) -> Dictionary:
	# 1. Check local cached session first
	var cached = _load_cached_session()
	if not cached.is_empty():
		var token = cached.get("token", "")
		var refresh = cached.get("refresh_token", "")
		var u_id = cached.get("user_id", "")
		var u_name = cached.get("username", "")
		
		# Test session validity with version check RPC
		backend.session_token = token
		backend.refresh_token = refresh
		backend.user_id = u_id
		backend.username = u_name
		
		var test_res = await backend.call_rpc("rpc_check_version", {"client_version": BackendConfig.CLIENT_VERSION})
		if test_res.get("success", false):
			backend.session_ready.emit(u_id)
			return {"success": true, "user_id": u_id, "username": u_name, "is_new": false}
			
		# If token expired, attempt session refresh
		if not refresh.is_empty():
			var refresh_res = await _refresh_session(backend, refresh)
			if refresh_res.get("success", false):
				return refresh_res

	# 2. Perform Device Authentication via Nakama REST API
	var device_id = OS.get_unique_id()
	if device_id.is_empty():
		device_id = "dev_%d_%d" % [Time.get_unix_time_from_system(), randi()]
		
	var endpoint = "/v2/account/authenticate/device?create=true"
	var payload = {
		"id": device_id,
		"vars": {
			"client_version": BackendConfig.CLIENT_VERSION,
			"platform": OS.get_name()
		}
	}
	
	var res = await backend.request_http(endpoint, HTTPClient.METHOD_POST, payload, false)
	if res.get("success", false):
		var data = res.get("data", {})
		var token = data.get("token", "")
		var refresh_token = data.get("refresh_token", "")
		
		# Decode payload to extract user_id
		var u_id = _extract_user_id_from_jwt(token)
		var is_created = bool(data.get("created", false))
		
		backend.session_token = token
		backend.refresh_token = refresh_token
		backend.user_id = u_id
		backend.username = "Guest_%s" % u_id.substr(0, 6)
		
		_save_session(token, refresh_token, u_id, backend.username)
		backend.session_ready.emit(u_id)
		return {"success": true, "user_id": u_id, "username": backend.username, "is_new": is_created}
	else:
		return {"success": false, "error": res.get("error", "Authentication failed")}

static func _refresh_session(backend: Node, refresh_token: String) -> Dictionary:
	var endpoint = "/v2/account/session/refresh"
	var payload = {"token": refresh_token}
	var res = await backend.request_http(endpoint, HTTPClient.METHOD_POST, payload, false)
	if res.get("success", false):
		var data = res.get("data", {})
		var token = data.get("token", "")
		var new_refresh = data.get("refresh_token", refresh_token)
		var u_id = _extract_user_id_from_jwt(token)
		
		backend.session_token = token
		backend.refresh_token = new_refresh
		backend.user_id = u_id
		_save_session(token, new_refresh, u_id, backend.username)
		backend.session_ready.emit(u_id)
		return {"success": true, "user_id": u_id}
	return {"success": false, "error": "Session refresh failed"}

static func logout(backend: Node) -> void:
	backend.session_token = ""
	backend.refresh_token = ""
	backend.user_id = ""
	backend.username = ""
	backend._set_connected(false)
	if FileAccess.file_exists(SESSION_FILE_PATH):
		DirAccess.remove_absolute(SESSION_FILE_PATH)

static func _save_session(token: String, refresh: String, user_id: String, username: String) -> void:
	var f = FileAccess.open(SESSION_FILE_PATH, FileAccess.WRITE)
	if f:
		var d = {
			"token": token,
			"refresh_token": refresh,
			"user_id": user_id,
			"username": username,
			"saved_at": Time.get_unix_time_from_system()
		}
		f.store_string(JSON.stringify(d))
		f.close()

static func _load_cached_session() -> Dictionary:
	if not FileAccess.file_exists(SESSION_FILE_PATH):
		return {}
	var f = FileAccess.open(SESSION_FILE_PATH, FileAccess.READ)
	if f:
		var text = f.get_as_text()
		f.close()
		var json = JSON.new()
		if json.parse(text) == OK and json.data is Dictionary:
			return json.data
	return {}

## Helper to extract user_id (uid claim) from JWT token without external crypto library
static func _extract_user_id_from_jwt(jwt_token: String) -> String:
	var parts = jwt_token.split(".")
	if parts.size() >= 2:
		var payload_b64 = parts[1]
		# Add padding if needed
		while payload_b64.length() % 4 != 0:
			payload_b64 += "="
		payload_b64 = payload_b64.replace("-", "+").replace("_", "/")
		var decoded_str = Marshalls.base64_to_utf8(payload_b64)
		var json = JSON.new()
		if json.parse(decoded_str) == OK and json.data is Dictionary:
			return json.data.get("uid", "")
	return ""
