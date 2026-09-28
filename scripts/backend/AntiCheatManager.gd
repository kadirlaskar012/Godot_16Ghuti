class_name AntiCheatManager
extends RefCounted

## AntiCheatManager
## Client-side anti-tampering coordinator and move sequence tracker.
## Core principle: SERVER IS AUTHORITATIVE. Client only validates sequences and versioning.

const BackendConfig = preload("res://scripts/backend/BackendConfig.gd")

static var current_sequence: int = 0

static func get_next_sequence() -> int:
	current_sequence += 1
	return current_sequence

static func reset_sequence() -> void:
	current_sequence = 0

static func verify_client_version(backend: Node) -> Dictionary:
	var payload = {
		"client_version": BackendConfig.CLIENT_VERSION,
		"platform": OS.get_name()
	}
	var res = await backend.call_rpc("rpc_check_version", payload)
	if res.get("success", false):
		var data = res.get("data", {})
		var allowed = bool(data.get("allowed", true))
		return {
			"allowed": allowed,
			"min_version": data.get("min_supported_version", "1.0.0"),
			"message": data.get("message", "OK")
		}
	return {"allowed": true, "message": "Offline fallback"}
