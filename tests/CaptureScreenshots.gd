extends Node

func _ready() -> void:
	print("--- Starting Visual UI Screenshot Generation ---")
	SaveManager.load_data()
	_run_captures()

func _run_captures() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Screenshot 1: Main Menu
	var menu_scene = load("res://scenes/MainMenu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	await get_tree().create_timer(0.4).timeout
	await get_tree().process_frame
	_save_viewport_png("res://build/screenshot_main_menu.png")
	print("✔ Captured MainMenu screenshot")
	
	# Screenshot 2: Settings Modal with Live Theme Preview
	var settings_scene = load("res://scenes/modals/SettingsModal.tscn")
	var settings = settings_scene.instantiate()
	add_child(settings)
	await get_tree().create_timer(0.4).timeout
	await get_tree().process_frame
	_save_viewport_png("res://build/screenshot_settings_modal.png")
	print("✔ Captured SettingsModal screenshot")
	settings.queue_free()
	await get_tree().process_frame
	
	# Screenshot 3: Local 2 Player Setup Modal
	var setup_scene = load("res://scenes/modals/LocalPlayerSetupModal.tscn")
	var setup = setup_scene.instantiate()
	add_child(setup)
	await get_tree().create_timer(0.4).timeout
	await get_tree().process_frame
	_save_viewport_png("res://build/screenshot_local_setup_modal.png")
	print("✔ Captured LocalPlayerSetupModal screenshot")
	setup.queue_free()
	await get_tree().process_frame
	menu.queue_free()
	await get_tree().process_frame
	
	# Screenshot 4: In-Game Screen (Local 2P)
	GameManager.set_local_players("Alex (P1)", 0, "Elena (P2)", 2)
	GameManager.current_mode = GameManager.GameMode.LOCAL_2P
	GameManager.current_state = GameState.new()
	GameManager.current_state.reset_to_start()
	GameManager.match_state = GameManager.MatchState.PLAYING
	GameManager.is_game_active = true
	var game_scene = load("res://scenes/Game.tscn")
	var game_local = game_scene.instantiate()
	add_child(game_local)
	await get_tree().create_timer(0.6).timeout
	await get_tree().process_frame
	_save_viewport_png("res://build/screenshot_game_local2p.png")
	print("✔ Captured In-Game Local 2P screenshot")
	game_local.queue_free()
	await get_tree().process_frame
	
	# Screenshot 5: In-Game Screen (VS AI)
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.current_difficulty = AIManager.Difficulty.MEDIUM
	GameManager.current_state = GameState.new()
	GameManager.current_state.reset_to_start()
	GameManager.match_state = GameManager.MatchState.PLAYING
	GameManager.is_game_active = true
	var game_ai = game_scene.instantiate()
	add_child(game_ai)
	await get_tree().create_timer(0.6).timeout
	await get_tree().process_frame
	_save_viewport_png("res://build/screenshot_game_vs_ai.png")
	print("✔ Captured In-Game VS AI screenshot")
	game_ai.queue_free()
	await get_tree().process_frame
	
	print("🎉 ALL SCREENSHOTS GENERATED SUCCESSFULLY!")
	get_tree().quit(0)

func _save_viewport_png(path: String) -> void:
	var img = get_viewport().get_texture().get_image()
	img.save_png(path)
