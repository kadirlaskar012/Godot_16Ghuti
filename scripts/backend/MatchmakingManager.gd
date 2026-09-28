class_name MatchmakingManager
extends RefCounted

## MatchmakingManager
## Coordinates 1v1 matchmaking and private room code creation/joining with Nakama.

static func find_match(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_find_match", {})
	if res.get("success", false):
		var data = res.get("data", {})
		return {"success": true, "match_id": data.get("matchId", "")}
	return {"success": false, "error": res.get("error", "Matchmaking search failed")}

static func create_room(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_create_room", {})
	if res.get("success", false):
		var data = res.get("data", {})
		return {
			"success": true,
			"match_id": data.get("matchId", ""),
			"room_code": data.get("roomCode", "")
		}
	return {"success": false, "error": res.get("error", "Failed to create room")}

static func join_room(backend: Node, room_code: String) -> Dictionary:
	var payload = {"room_code": room_code.strip_edges().to_upper()}
	var res = await backend.call_rpc("rpc_join_room", payload)
	if res.get("success", false):
		var data = res.get("data", {})
		if data.has("matchId"):
			return {"success": true, "match_id": data.get("matchId", "")}
		else:
			return {"success": false, "error": data.get("error", "Room not found")}
	return {"success": false, "error": res.get("error", "Failed to join room")}
