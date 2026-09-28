class_name DailyRewardManager
extends RefCounted

## DailyRewardManager
## Manages server-time authoritative 7-day reward cycle.
## Protected against client system clock and device date tampering.

const WalletManager = preload("res://scripts/backend/WalletManager.gd")

static func get_reward_status(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_get_daily_reward_status", {})
	if res.get("success", false):
		return {"success": true, "status": res.get("data", {})}
	return {"success": false, "error": "Unable to check daily reward status"}

static func claim_reward(backend: Node) -> Dictionary:
	var res = await backend.call_rpc("rpc_claim_daily_reward", {})
	if res.get("success", false):
		var data = res.get("data", {})
		if data.get("success", false):
			var new_bal = int(data.get("newBalance", 0))
			WalletManager.update_local_balance_from_server(new_bal)
			return {
				"success": true,
				"new_balance": new_bal,
				"streak": int(data.get("streak", 1)),
				"coins_awarded": int(data.get("coinsAwarded", 50))
			}
		else:
			return {"success": false, "error": data.get("error", "Reward not available")}
	return {"success": false, "error": res.get("error", "Failed to claim daily reward")}
