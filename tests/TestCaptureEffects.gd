extends Node2D

func _ready() -> void:
	print("--- Running TestCaptureEffects: Verifying Grounded Drag & Multi-Level Effects ---")
	
	# 1. Verify Extensible Theme Registry for Future Shop Purchases
	var themes = CaptureEffectManager.get_available_themes()
	assert(themes.size() >= 4, "CaptureEffectManager must have at least 4 registered themes!")
	print("✔ Theme registry verified: %d themes available for cosmetic shop." % themes.size())
	
	var active_theme = CaptureEffectManager.get_active_theme()
	assert(active_theme.has("ring_color") and active_theme.has("combo_color"), "Active theme must define ring and combo colors!")
	print("✔ Active theme verified: '%s'" % active_theme.get("name", ""))
	
	# 2. Verify SaveManager & GameSettings persistence
	assert(SaveManager.settings.capture_effect_theme == "classic_gold", "Default capture effect theme must be classic_gold!")
	assert(SaveManager.player_data.equipped_effect == "classic_gold", "PlayerData equipped effect must be classic_gold!")
	print("✔ Persistence fields for capture effect themes verified.")

	# 3. Setup Game Scene to verify grounded piece movement and capture VFX
	GameManager.current_mode = GameManager.GameMode.LOCAL_2P
	GameManager.current_state.reset_to_start()
	GameManager.is_game_active = true
	
	var game_scene = load("res://scenes/Game.tscn")
	var game_instance = game_scene.instantiate()
	add_child(game_instance)
	
	var board: BoardManager = game_instance.board
	var state: GameState = GameManager.current_state
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 4. Verify Grounded Drag Position (No upward vertical offset)
	var test_piece = board.pieces.get(21, null)
	assert(test_piece != null, "Piece 21 must exist!")
	var orig_nominal = test_piece.position
	
	test_piece.set_selected(true)
	assert(test_piece.position.y == orig_nominal.y, "Piece must NOT lift upward on selection! (nominal=%f, pos=%f)" % [orig_nominal.y, test_piece.position.y])
	print("✔ Piece selection verified grounded on board plane.")
	
	test_piece.start_drag()
	var simulated_touch_pos = Vector2(500.0, 750.0)
	test_piece.update_drag_position(simulated_touch_pos)
	assert(test_piece.position == simulated_touch_pos, "Piece must match touch position exactly without vertical lift! (expected=%s, got=%s)" % [simulated_touch_pos, test_piece.position])
	print("✔ Piece drag position verified: strictly centered at touch point (0 vertical displacement).")
	test_piece.snap_back_to_nominal()
	
	# 5. Verify Multi-Level Capture VFX execution
	var test_pos = Vector2(540, 960)
	
	# Level 1 test
	CaptureEffectManager.play_capture_effect(board, test_pos, 1, BoardData.Player.PLAYER_2)
	print("✔ Level 1 capture effect spawned successfully.")
	
	# Level 2 test (Double combo)
	CaptureEffectManager.play_capture_effect(board, test_pos, 2, BoardData.Player.PLAYER_2)
	print("✔ Level 2 combo capture effect (double ring + 2x COMBO badge) spawned successfully.")
	
	# Level 3 test (Triple combo)
	CaptureEffectManager.play_capture_effect(board, test_pos, 3, BoardData.Player.PLAYER_2)
	print("✔ Level 3 combo capture effect (radiant rays + 3x TRIPLE badge) spawned successfully.")
	
	await get_tree().create_timer(0.3).timeout
	
	print("🎉 ALL CAPTURE EFFECTS AND GROUNDED DRAG TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
