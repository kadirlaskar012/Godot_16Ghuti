extends Node

func _ready() -> void:
	print("Capturing Game layout...")
	GameManager.current_mode = GameManager.GameMode.PLAYER_VS_AI
	GameManager.is_game_active = true
	var game_scene = load("res://scenes/Game.tscn")
	var game = game_scene.instantiate()
	add_child(game)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var vp = game.get_viewport_rect().size
	var hud = game.get_node("GameHUD")
	var board = game.get_node("Board")
	var p2 = hud.find_child("P2Card", true, false)
	var p1 = hud.find_child("P1Card", true, false)
	var bb = hud.find_child("BottomBar", true, false)
	
	print("VP size: ", vp)
	print("Board pos: ", board.position, " scale: ", board.scale)
	print("P2Card pos: ", p2.position, " size: ", p2.size)
	print("P1Card pos: ", p1.position, " size: ", p1.size)
	print("BottomBar pos: ", bb.position, " size: ", bb.size)
	
	await get_tree().create_timer(0.3).timeout
	
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("test_game_layout_current.png")
		print("Saved test_game_layout_current.png")
		
	get_tree().quit(0)
