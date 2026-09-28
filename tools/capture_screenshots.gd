extends SceneTree

func _init() -> void:
	print("Capturing screenshots...")
	# Change root to Game scene
	var game_scene = load("res://scenes/Game.tscn")
	var game = game_scene.instantiate()
	root.add_child(game)
	
	# Wait for rendering
	create_timer(0.2).timeout.connect(func():
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		if img:
			img.save_png("res://screenshot_gameplay.png")
			print("Saved screenshot_gameplay.png")
			
		# Now switch to main menu
		game.queue_free()
		var menu_scene = load("res://scenes/MainMenu.tscn")
		var menu = menu_scene.instantiate()
		root.add_child(menu)
		
		create_timer(0.2).timeout.connect(func():
			var img2 = root.get_viewport().get_texture().get_image()
			if img2:
				img2.save_png("res://screenshot_mainmenu.png")
				print("Saved screenshot_mainmenu.png")
			quit(0)
		)
	)
