extends Node

## Capture9ScreensFlow takes screenshots of all 1 to 9 screens for visual verification:
## screen1_main_menu.png
## screen2_select_difficulty.png
## screen3_choose_ghuti.png
## screen4_select_theme.png
## screen5_vs_screen.png
## screen6_game_hud.png
## screen7_win_screen.png
## screen8_lose_screen.png
## screen9_match_options.png

func _ready() -> void:
	print("--- Starting 9-Screen Flow Screenshot Capture ---")
	_capture_flow()

func _capture_flow() -> void:
	# Screen 1: Main Menu
	print("Capturing Screen 1: Main Menu...")
	var menu_scene = load("res://scenes/MainMenu.tscn").instantiate()
	add_child(menu_scene)
	await get_tree().create_timer(0.4).timeout
	_save_viewport_png("screen1_main_menu.png")
	menu_scene.queue_free()
	await get_tree().process_frame
	
	# Wizard (Screens 2, 3, 4, 5)
	var wiz_scene = load("res://scenes/modals/PlayVsAIWizardModal.tscn").instantiate()
	add_child(wiz_scene)
	
	# Screen 2: Select Difficulty
	print("Capturing Screen 2: Select Difficulty...")
	wiz_scene._go_to_step(1)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen2_select_difficulty.png")
	
	# Screen 3: Choose Your Ghuti
	print("Capturing Screen 3: Choose Your Ghuti...")
	wiz_scene._go_to_step(2)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen3_choose_ghuti.png")
	
	# Screen 4: Select Board Theme
	print("Capturing Screen 4: Select Board Theme...")
	wiz_scene._go_to_step(3)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen4_select_theme.png")
	
	# Screen 5: VS Screen
	print("Capturing Screen 5: Game Start / VS Screen...")
	wiz_scene._go_to_step(4)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen5_vs_screen.png")
	
	wiz_scene.queue_free()
	await get_tree().process_frame
	
	# Screen 6: Game Board HUD
	print("Capturing Screen 6: Game Board HUD...")
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.current_difficulty = AIManager.Difficulty.MEDIUM
	GameManager.is_game_active = true
	GameManager.match_state = GameManager.MatchState.PLAYING
	
	var game_scene = load("res://scenes/Game.tscn").instantiate()
	add_child(game_scene)
	await get_tree().create_timer(0.4).timeout
	_save_viewport_png("screen6_game_hud.png")
	game_scene.queue_free()
	await get_tree().process_frame
	
	# Screen 7: Win Screen (YOU WIN!)
	print("Capturing Screen 7: Win Screen...")
	var win_modal = load("res://scenes/modals/GameResultModal.tscn").instantiate()
	add_child(win_modal)
	win_modal.setup(BoardData.Player.PLAYER_1, "All opponent pieces captured.", 165.0, 12, 16, 24, false)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen7_win_screen.png")
	win_modal.queue_free()
	await get_tree().process_frame
	
	# Screen 8: Lose Screen (YOU LOSE!)
	print("Capturing Screen 8: Lose Screen...")
	var lose_modal = load("res://scenes/modals/GameResultModal.tscn").instantiate()
	add_child(lose_modal)
	lose_modal.setup(BoardData.Player.PLAYER_2, "All your pieces were captured.", 192.0, 8, 9, 28, false)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen8_lose_screen.png")
	lose_modal.queue_free()
	await get_tree().process_frame
	
	# Screen 9: Match Options Modal
	print("Capturing Screen 9: Match Options Modal...")
	var opt_modal = load("res://scenes/modals/GameOverOptionsModal.tscn").instantiate()
	add_child(opt_modal)
	await get_tree().create_timer(0.3).timeout
	_save_viewport_png("screen9_match_options.png")
	opt_modal.queue_free()
	await get_tree().process_frame
	
	print("🎉 ALL 9 SCREENS CAPTURED SUCCESSFULLY!")
	get_tree().quit(0)

func _save_viewport_png(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(filename)
		print("Saved %s" % filename)
