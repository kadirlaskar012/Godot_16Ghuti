class_name PurchaseManager
extends RefCounted

## PurchaseManager
## Server-verified real-money in-app purchase validation for Google Play Billing.
## Prevents duplicate redemptions and ensures currency is only credited by Nakama.

const WalletManager = preload("res://scripts/backend/WalletManager.gd")

static func verify_and_credit_purchase(
	backend: Node,
	order_id: String,
	purchase_token: String,
	product_id: String
) -> Dictionary:
	var payload = {
		"order_id": order_id,
		"purchase_token": purchase_token,
		"product_id": product_id
	}
	
	var res = await backend.call_rpc("rpc_verify_purchase", payload)
	if res.get("success", false):
		var data = res.get("data", {})
		if data.get("success", false):
			var new_bal = int(data.get("new_balance", 0))
			WalletManager.update_local_balance_from_server(new_bal)
			return {
				"success": true,
				"new_balance": new_bal,
				"coins_granted": int(data.get("coins_granted", 0))
			}
		else:
			return {"success": false, "error": data.get("error", "Purchase verification rejected")}
	return {"success": false, "error": res.get("error", "Network error during purchase verification")}
