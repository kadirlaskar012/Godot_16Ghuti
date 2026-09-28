extends Node

func _ready() -> void:
	print("--- Capturing HUD Timer & Perimeter Bar Screenshot ---")
	
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.current_state = GameState.new()
	GameManager.current_state.reset_to_start()
	GameManager.match_state = GameManager.MatchState.PLAYING
	GameManager.is_game_active = true
	
	var game_scene = load("res://scenes/Game.tscn")
	var game = game_scene.instantiate()
	add_child(game)
	
	var hud: GameHUD = game.hud
	
	# Scenario 1: Normal 10s turn timer with watch icon
	hud.current_turn_remaining = 8.5
	hud.current_is_extra_time = false
	hud.active_turn_player = BoardData.Player.PLAYER_1
	hud.p1_extra_time_remaining = 290.0 # 4:50 remaining on perimeter ring
	hud.p2_extra_time_remaining = 300.0 # 5:00 full perimeter ring
	hud._update_turn_timer_display()
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("screenshot_hud_turn_watch.png")
		print("✔ Saved screenshot_hud_turn_watch.png")
		
	# Scenario 2: Active Extra Time (<= 60s danger zone with coral warning perimeter ring)
	hud.current_turn_remaining = 0.0
	hud.current_is_extra_time = true
	hud.active_turn_player = BoardData.Player.PLAYER_1
	hud.p1_extra_time_remaining = 45.0 # 45s left (warning state!)
	hud._update_turn_timer_display()
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	var img2 = get_viewport().get_texture().get_image()
	if img2:
		img2.save_png("screenshot_hud_extra_time_ring.png")
		print("✔ Saved screenshot_hud_extra_time_ring.png")
		
	get_tree().quit(0)
