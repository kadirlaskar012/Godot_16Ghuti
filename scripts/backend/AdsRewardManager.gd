class_name AdsRewardManager
extends RefCounted

## AdsRewardManager
## Validates rewarded ad completions with Nakama server.
## Server enforces daily claim limits (default 5) and ledger idempotency.

const WalletManager = preload("res://scripts/backend/WalletManager.gd")

static func claim_rewarded_ad(backend: Node) -> Dictionary:
	var ref_id = "ad_%d_%d" % [Time.get_unix_time_from_system(), randi() % 999999]
	var payload = {"reference_id": ref_id}
	
	var res = await backend.call_rpc("rpc_claim_ad_reward", payload)
	if res.get("success", false):
		var data = res.get("data", {})
		if data.get("success", false):
			var new_bal = int(data.get("newBalance", 0))
			WalletManager.update_local_balance_from_server(new_bal)
			return {
				"success": true,
				"new_balance": new_bal,
				"coins_awarded": int(data.get("coinsAwarded", 50)),
				"remaining_today": int(data.get("remainingToday", 0))
			}
		else:
			return {"success": false, "error": data.get("error", "Daily ad limit reached")}
	return {"success": false, "error": res.get("error", "Failed to validate ad reward with server")}
