class_name ShopManager
extends RefCounted

## ShopManager
## Fetches shop catalog and handles server-validated purchases.

const WalletManager = preload("res://scripts/backend/WalletManager.gd")

static func get_shop_catalog(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_get_shop", {})
	if res.get("success", false):
		var data = res.get("data", {})
		return {"success": true, "items": data.get("items", [])}
	return {"success": false, "error": "Failed to load shop catalog"}

static func purchase_item(backend: Node, item_id: String) -> Dictionary:
	var payload = {"item_id": item_id}
	var res = await backend.call_rpc("rpc_purchase_item", payload)
	if res.get("success", false):
		var data = res.get("data", {})
		if data.get("success", false):
			var new_bal = int(data.get("newBalance", 0))
			WalletManager.update_local_balance_from_server(new_bal)
			return {"success": true, "new_balance": new_bal}
		else:
			return {"success": false, "error": data.get("error", "Purchase rejected")}
	return {"success": false, "error": res.get("error", "Network error during purchase")}
