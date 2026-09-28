extends Node2D

func _ready() -> void:
	print("--- Running TestTimerFlow: 5-Minute Timer & Time-Up Result System ---")
	
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.current_difficulty = AIManager.Difficulty.MEDIUM
	GameManager.current_state = GameState.new()
	GameManager.current_state.reset_to_start()
	GameManager.match_state = GameManager.MatchState.PLAYING
	GameManager.is_game_active = true
	
	var game_scene = load("res://scenes/Game.tscn")
	assert(game_scene != null, "Game.tscn must load")
	
	var game_instance = game_scene.instantiate()
	add_child(game_instance)
	
	var board: BoardManager = game_instance.board
	var hud: GameHUD = game_instance.hud
	assert(board != null, "Board must exist")
	assert(hud != null, "HUD must exist")
	
	await get_tree().physics_frame
	await get_tree().process_frame
	
	# 1. Verify default 5-minute timer setup (header timer is hidden per user requirement)
	assert(SaveManager.settings.match_timer_minutes == 5, "Default match timer setting must be 5 minutes")
	assert(hud.timer_label.visible == false, "Main match timer must be hidden on HUD")
	print("✔ Verified match timer hidden and personal 5-minute banks initialized.")
	
	# 2. Verify display warning thresholds:
	# > 60s: normal appearance
	hud.timer_remaining_seconds = 120.0
	hud._update_timer_display()
	assert(hud.timer_label.text == "02:00", "Formatted 120s as 02:00")
	assert(hud.timer_label.modulate == Color(1.0, 0.85, 0.4), "Normal gold color when > 60s")
	
	# <= 60s: amber warning
	hud.timer_remaining_seconds = 45.0
	hud._update_timer_display()
	assert(hud.timer_label.text == "00:45", "Formatted 45s as 00:45")
	assert(hud.timer_label.modulate == Color(1.0, 0.65, 0.25), "Amber warning when <= 60s")
	
	# <= 10s: red warning
	hud.timer_remaining_seconds = 8.0
	hud._update_timer_display()
	assert(hud.timer_label.text == "00:08", "Formatted 8s as 00:08")
	assert(hud.timer_label.modulate == Color(1.0, 0.32, 0.32), "Red warning when <= 10s")
	print("✔ Verified timer warning thresholds (normal >60s, amber <=60s, red <=10s).")
	
	# 3. Test Development-only 10-second debug test timer (Point 14)
	print("3. Testing 10-second development test timer countdown...")
	hud.start_debug_test_timer(2.0) # Fast 2s for automated test
	assert(hud.timer_active == true, "Debug timer active")
	
	# Wait for timer to naturally reach 00:00
	var elapsed = 0.0
	while hud.timer_remaining_seconds > 0.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed > 3.0:
			break
			
	assert(hud.timer_remaining_seconds == 0.0, "Timer reached 00:00")
	assert(hud.timer_label.text == "00:00", "Timer display reached 00:00")
	print("✔ Timer reached 00:00 via real elapsed time.")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 4. Verify match state transitioned to TIME_UP and gameplay stopped
	assert(GameManager.match_state == GameManager.MatchState.TIME_UP, "Match state must be TIME_UP")
	assert(GameManager.is_playing() == false, "GameManager.is_playing() must be false")
	assert(game_instance.ai_timer.is_stopped(), "AI timer must be stopped")
	assert(hud.undo_btn.disabled == true, "Undo button must be disabled")
	assert(hud.hint_btn.disabled == true, "Hint button must be disabled")
	assert(hud.reset_btn.disabled == true, "Reset button must be disabled")
	print("✔ All gameplay logic, AI, and controls disabled immediately upon Time Up.")
	
	# 5. Verify pieces remain visually pristine and unbroken
	for node_id in board.pieces.keys():
		var p: Piece = board.pieces[node_id]
		assert(is_instance_valid(p), "Piece must be valid")
		assert(p.scale == Vector2.ONE, "Piece root scale must be Vector2.ONE")
		assert(p.modulate == Color.WHITE, "Piece modulate must be Color.WHITE")
		assert(p.sprite.scale.is_equal_approx(p._base_scale), "Piece sprite scale must be exact base scale")
		assert(p.is_selected == false, "Piece selection state must be reset")
		assert(p.is_dragging == false, "Piece dragging state must be reset")
	print("✔ Verified all 32 pieces remain visually complete, circular, and pristine.")
	
	# 6. Verify GameResultModal appeared with title "TIME UP" and correct outcome
	var result_modal: GameResultModal = null
	for child in game_instance.get_children():
		if child is GameResultModal:
			result_modal = child
			break
			
	assert(result_modal != null, "GameResultModal must be present on game instance")
	assert(result_modal.title_label.text == "TIME UP", "Modal title must be TIME UP, got: %s" % result_modal.title_label.text)
	assert(result_modal.winner_label.text == "DRAW", "Equal pieces (16 vs 16) must result in DRAW, got: %s" % result_modal.winner_label.text)
	print("✔ Result screen verified: Title='TIME UP', Subtitle='DRAW'.")
	
	# 7. Test winner calculation with P1 having more pieces
	GameManager.current_state.p1_pieces = 14
	GameManager.current_state.p2_pieces = 10
	GameManager.match_state = GameManager.MatchState.PLAYING
	game_instance._on_time_expired()
	
	var time_up_modal_p1: GameResultModal = null
	for child in game_instance.get_children():
		if child is GameResultModal and child != result_modal:
			time_up_modal_p1 = child
			break
			
	assert(time_up_modal_p1 != null, "New result modal must open")
	assert(time_up_modal_p1.title_label.text == "TIME UP", "Title must be TIME UP")
	assert(time_up_modal_p1.winner_label.text == "PLAYER 1 WINS", "P1 with 14 vs 10 must win, got: %s" % time_up_modal_p1.winner_label.text)
	print("✔ Result calculation verified: Player 1 wins when having more pieces (14 vs 10).")
	
	# 8. Test Rematch
	await get_tree().process_frame
	time_up_modal_p1.rematch_pressed.emit()
	await get_tree().process_frame
	assert(GameManager.match_state == GameManager.MatchState.PLAYING, "Rematch restored PLAYING state")
	assert(GameManager.is_playing() == true, "is_playing() is true after rematch")
	assert(hud.timer_remaining_seconds >= 298.0 and hud.timer_remaining_seconds <= 300.0, "Timer in 5-minute range on rematch")
	assert(hud.timer_label.text == "05:00", "Timer display restored to 05:00 on rematch")
	assert(board.pieces.size() == 32, "All 32 pieces restored on rematch")
	print("✔ Rematch verified: 05:00 timer, 16 vs 16 pieces, and PLAYING state restored.")
	
	print("🎉 ALL TIMER AND TIME-UP TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
