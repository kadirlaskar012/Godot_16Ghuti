class_name MatchHistoryManager
extends RefCounted

## MatchHistoryManager
## Loads server-recorded authoritative match history.

static func get_match_history(backend: Node, limit: int = 10, offset: int = 0) -> Dictionary:
	var payload = {
		"limit": limit,
		"offset": offset
	}
	var res = await backend.call_rpc("rpc_get_match_history", payload)
	if res.get("success", false):
		var data = res.get("data", {})
		return {"success": true, "matches": data.get("matches", [])}
	return {"success": false, "error": "Unable to fetch match history"}
