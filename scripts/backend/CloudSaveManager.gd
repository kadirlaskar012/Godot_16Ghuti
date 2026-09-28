class_name CloudSaveManager
extends RefCounted

## CloudSaveManager
## Synchronizes player profile and cosmetics with server cloud save.
## Follows zero-client-trust rule: stats and currency are server-authoritative.

static func load_player_profile(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_get_profile", {})
	if res.get("success", false):
		var data = res.get("data", {})
		if data is Dictionary:
			var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
			if sm and sm.player_data:
				var p = sm.player_data
				p.player_name = data.get("display_name", p.player_name)
				p.avatar_index = int(data.get("avatar_id", p.avatar_index))
				p.coins = int(data.get("coins", p.coins))
				p.xp = int(data.get("xp", p.xp))
				
				# Equipped cosmetics
				var eq = data.get("equipped", {})
				if eq is Dictionary:
					p.equipped_guti = eq.get("guti_skin", p.equipped_guti)
					p.equipped_board = eq.get("board_theme", p.equipped_board)
					p.equipped_victory = eq.get("victory_effect", p.equipped_victory)
					
				# Unlocked inventory
				var inv = data.get("inventory", [])
				if inv is Array:
					for item in inv:
						var item_str = str(item)
						if not p.unlocked_themes.has(item_str) and item_str.ends_with("_wood") or item_str.ends_with("_maple") or item_str.ends_with("_mahogany"):
							p.unlocked_themes.append(item_str)
						if not p.unlocked_pieces.has(item_str) and (item_str.ends_with("_guti") or item_str.ends_with("_red")):
							p.unlocked_pieces.append(item_str)
							
				# Authoritative statistics
				var stats = data.get("statistics", {})
				if stats is Dictionary:
					p.games_played = int(stats.get("matches_played", p.games_played))
					p.games_won = int(stats.get("wins", p.games_won))
					p.games_lost = int(stats.get("losses", p.games_lost))
					p.games_draw = int(stats.get("draws", p.games_draw))
					p.total_captures = int(stats.get("captures", p.total_captures))
					p.win_streak = int(stats.get("win_streak", p.win_streak))
					p.best_win_streak = int(stats.get("best_streak", p.best_win_streak))
					p.total_play_time_seconds = float(stats.get("total_play_time", p.total_play_time_seconds))
					
				sm.save_data()
				return {"success": true, "profile": data}
	return {"success": false, "error": "Server profile unavailable. Using local save."}

static func update_player_name(backend: Node, new_name: String) -> Dictionary:
	var payload = {"display_name": new_name}
	var res = await backend.call_rpc("rpc_update_profile", payload)
	if res.get("success", false):
		var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
		if sm and sm.player_data:
			sm.player_data.player_name = new_name
			sm.save_data()
	return res

static func update_avatar(backend: Node, avatar_id: int) -> Dictionary:
	var payload = {"avatar_id": avatar_id}
	var res = await backend.call_rpc("rpc_update_profile", payload)
	if res.get("success", false):
		var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
		if sm and sm.player_data:
			sm.player_data.avatar_index = avatar_id
			sm.save_data()
	return res

static func update_settings(backend: Node, settings: Dictionary) -> Dictionary:
	var payload = {"settings": settings}
	return await backend.call_rpc("rpc_update_profile", payload)
