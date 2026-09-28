class_name InventoryManager
extends RefCounted

## InventoryManager
## Server-validated inventory and cosmetic equipping.

static func get_inventory(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_get_inventory", {})
	if res.get("success", false):
		return {"success": true, "data": res.get("data", {})}
	return {"success": false, "error": "Failed to load inventory"}

static func equip_cosmetic(backend: Node, category: String, item_name: String) -> Dictionary:
	var payload = {
		"category": category,
		"item_name": item_name
	}
	var res = await backend.call_rpc("rpc_equip_item", payload)
	if res.get("success", false):
		var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
		if sm and sm.player_data:
			match category.to_upper():
				"GUTI_SKIN": sm.player_data.equipped_guti = item_name
				"BOARD_THEME": sm.player_data.equipped_board = item_name
				"VICTORY_EFFECT": sm.player_data.equipped_victory = item_name
			sm.save_data()
		return {"success": true}
	return {"success": false, "error": res.get("error", "Failed to equip cosmetic")}
