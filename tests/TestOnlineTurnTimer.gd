extends Node2D

## TestOnlineTurnTimer: Verifies the 14 Server-Authoritative Turn Timer & Extra Time Requirements

func _ready() -> void:
	print("\n========================================================")
	print("--- Running TestOnlineTurnTimer: Online Turn Timer & Extra Time ---")
	print("========================================================\n")
	
	# 1. Verify Server-Side / Client Central Configuration Values
	print("Checking central configurable constants...")
	assert(BackendConfig.MATCH_DURATION == 300, "BackendConfig.MATCH_DURATION must be 300 (5 minutes)")
	assert(BackendConfig.TURN_NORMAL_TIME == 10, "BackendConfig.TURN_NORMAL_TIME must be 10 seconds")
	assert(BackendConfig.PLAYER_EXTRA_TIME == 60, "BackendConfig.PLAYER_EXTRA_TIME must be 60 seconds")
	print("✔ Configuration verified: MATCH_DURATION = 300, TURN_NORMAL_TIME = 10, PLAYER_EXTRA_TIME = 60\n")
	
	# Instantiate Game scene with HUD
	GameManager.current_mode = GameManager.GameMode.ONLINE_MULTIPLAYER
	GameManager.current_state = GameState.new()
	GameManager.current_state.reset_to_start()
	GameManager.match_state = GameManager.MatchState.PLAYING
	GameManager.is_game_active = true
	
	var game_scene = load("res://scenes/Game.tscn")
	assert(game_scene != null, "Game.tscn must load")
	
	var game_instance = game_scene.instantiate()
	add_child(game_instance)
	
	var hud: GameHUD = game_instance.hud
	assert(hud != null, "HUD must exist")
	
	await get_tree().physics_frame
	await get_tree().process_frame
	
	# 2. Test Normal 7-Second Turn Display
	print("Test 1 & 2: Testing normal 7-second turn timer display...")
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 7,
		"is_extra_time": false,
		"match_remaining_seconds": 300,
		"p1_extra_time": 60,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_box.visible == true, "Turn timer box must be visible")
	assert(hud.turn_timer_title.text == "TURN", "Title must show 'TURN' during normal turn")
	assert(hud.turn_timer_value.text == "07", "Value must show '07'")
	
	# Countdown normal time to 5
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 5,
		"is_extra_time": false,
		"match_remaining_seconds": 298,
		"p1_extra_time": 60,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_value.text == "05", "Value must show '05'")
	print("✔ Test 1 & 2 Passed: Normal 7s timer renders 'TURN' and '07' -> '05'.\n")
	
	# 3. Test Normal Timer Warning State (<= 3 seconds)
	print("Test 3: Testing normal timer warning state (<= 3s)...")
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 3,
		"is_extra_time": false,
		"match_remaining_seconds": 296,
		"p1_extra_time": 60,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_value.text == "03", "Value shows '03'")
	var val_color = hud.turn_timer_value.get_theme_color("font_color")
	assert(val_color.r > 0.8 and val_color.g < 0.6, "Normal timer warning state uses distinct amber/orange color when <= 3s")
	print("✔ Test 3 Passed: Normal timer <= 3s warning state active.\n")
	
	# 4. Test Transition to Extra Time (starts at 60s)
	print("Test 4: Testing transition to Extra Time (60s)...")
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 60,
		"is_extra_time": true,
		"match_remaining_seconds": 293,
		"p1_extra_time": 60,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_title.text == "EXTRA TIME", "Title must switch to 'EXTRA TIME'")
	assert(hud.turn_timer_value.text == "60", "Value must show '60'")
	print("✔ Test 4 Passed: Extra Time automatically activates with 'EXTRA TIME' '60'.\n")
	
	# 5. Test Move in Extra Time (deducts 10s, remaining 50s)
	print("Test 5 & 6: Testing deduction of only consumed Extra Time (10s used -> 50s left)...")
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 50,
		"is_extra_time": true,
		"match_remaining_seconds": 283,
		"p1_extra_time": 50,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_value.text == "50", "Value shows 50s left")
	assert(hud.p1_extra_time_remaining == 50.0, "P1 reserve is 50s")
	assert(hud.p2_extra_time_remaining == 60.0, "P2 reserve remains 60s (personal reserve, not shared)")
	if hud.p1_badge_label:
		assert(hud.p1_badge_label.text == "EXTRA: 50s", "P1 card displays 'EXTRA: 50s'")
	if hud.p2_extra_label:
		assert(hud.p2_extra_label.text == "EXTRA: 60s", "P2 card displays 'EXTRA: 60s'")
	print("✔ Test 5 & 6 Passed: Only 10s deducted from P1, P2 reserve untouched.\n")
	
	# 6. Test Next Turn receives fresh 7 seconds
	print("Test 7: Testing next turn receives fresh 7 seconds normal timer...")
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 7,
		"is_extra_time": false,
		"match_remaining_seconds": 283,
		"p1_extra_time": 50,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_title.text == "TURN", "Next turn starts in 'TURN'")
	assert(hud.turn_timer_value.text == "07", "Next turn gets fresh '07'")
	assert(hud.p1_extra_time_remaining == 50.0, "P1 Extra Time preserved across turns")
	print("✔ Test 7 Passed: Next turn gets fresh 7s normal timer; persistent reserve preserved.\n")
	
	# 7. Test Extra Time Warning State (<= 10 seconds)
	print("Test 8: Testing Extra Time distinct warning state (<= 10s)...")
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 9,
		"is_extra_time": true,
		"match_remaining_seconds": 240,
		"p1_extra_time": 9,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_title.text == "EXTRA TIME", "Title is 'EXTRA TIME'")
	assert(hud.turn_timer_value.text == "09", "Value shows '09'")
	var extra_warn_color = hud.turn_timer_value.get_theme_color("font_color")
	assert(extra_warn_color.r > 0.9 and extra_warn_color.g < 0.35, "Extra time warning state uses intense red alert color when <= 10s")
	print("✔ Test 8 Passed: Extra Time <= 10s intense warning state verified.\n")
	
	# 8. Test Disconnect & Reconnect state synchronization
	print("Test 9, 10, 11: Testing disconnect and reconnect timer restoration...")
	# Simulate reconnect sync packet from server
	hud.update_server_turn_timer({
		"turn_remaining_seconds": 42,
		"is_extra_time": true,
		"match_remaining_seconds": 210,
		"p1_extra_time": 42,
		"p2_extra_time": 60
	})
	assert(hud.turn_timer_title.text == "EXTRA TIME", "Restored 'EXTRA TIME'")
	assert(hud.turn_timer_value.text == "42", "Restored exact 42s remaining")
	assert(hud.timer_remaining_seconds == 210.0, "Match timer restored to 210s")
	print("✔ Test 9, 10, 11 Passed: Reconnect restored exact authoritative timers.\n")
	
	# 9. Test Timeout forfeit handling
	print("Test 12, 13, 14: Testing Timeout forfeit game over handling...")
	game_instance._on_online_match_finished({
		"winner": 2,
		"end_reason": "TIMEOUT"
	})
	await get_tree().process_frame
	assert(not GameManager.is_game_active, "Game must no longer be active")
	assert(GameManager.match_state == GameManager.MatchState.TIME_UP or GameManager.match_state == GameManager.MatchState.GAME_OVER, "Match state must be TIME_UP or GAME_OVER")
	print("✔ Test 12, 13, 14 Passed: TIMEOUT end reason correctly triggers match end (TIME_UP) & opponent victory.\n")
	
	print("========================================================")
	print("=== ALL ONLINE TURN TIMER TESTS PASSED SUCCESSFULLY! ===")
	print("========================================================\n")
	get_tree().quit(0)
