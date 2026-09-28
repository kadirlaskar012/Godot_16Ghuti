class_name WalletManager
extends RefCounted

## WalletManager
## Server-authoritative wallet coordinator.
## Client can only request actions; server maintains the balance and ledger.

signal balance_changed(new_balance: int)

static func fetch_wallet_balance(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_get_wallet", {})
	if res.get("success", false):
		var data = res.get("data", {})
		var balance = int(data.get("balance", 0))
		var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
		if sm and sm.player_data:
			sm.player_data.coins = balance
			sm.save_data()
		return {"success": true, "balance": balance}
	return {"success": false, "error": "Unable to fetch wallet balance"}

static func update_local_balance_from_server(new_balance: int) -> void:
	var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
	if sm and sm.player_data:
		sm.player_data.coins = new_balance
		sm.save_data()
