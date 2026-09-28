class_name StatsManager
extends RefCounted

## StatsManager
## Fetches and presents server-verified player lifetime stats and achievements.

static func get_achievements(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_get_achievements", {})
	if res.get("success", false):
		var data = res.get("data", {})
		return {"success": true, "achievements": data.get("achievements", [])}
	return {"success": false, "error": "Unable to fetch achievements"}
