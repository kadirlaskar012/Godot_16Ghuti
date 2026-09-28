extends Node

func _ready() -> void:
	print("--- Capturing Theme & Settings UI Screenshots ---")
	
	# 1. MainMenu with new Theme button under Settings
	var menu_scene = load("res://scenes/MainMenu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	_capture("preview_main_menu.png")
	
	# 2. Open ThemeModal
	var thm_scene = load("res://scenes/modals/ThemeModal.tscn")
	var thm = thm_scene.instantiate()
	add_child(thm)
	await get_tree().process_frame
	await get_tree().process_frame
	_capture("preview_theme_modal.png")
	
	# 3. Preview Ivory Maple
	thm._select_theme("ivory_maple")
	menu._apply_theme_id("ivory_maple")
	await get_tree().process_frame
	await get_tree().process_frame
	_capture("preview_ivory_maple.png")
	
	# 4. Preview Royal Mahogany
	thm._select_theme("royal_mahogany")
	menu._apply_theme_id("royal_mahogany")
	await get_tree().process_frame
	await get_tree().process_frame
	_capture("preview_royal_mahogany.png")
	
	thm.queue_free()
	await get_tree().process_frame
	
	# 5. Open SettingsModal with Cross button & no theme
	var set_scene = load("res://scenes/modals/SettingsModal.tscn")
	var sm = set_scene.instantiate()
	add_child(sm)
	await get_tree().process_frame
	await get_tree().process_frame
	_capture("preview_settings_modal.png")
	
	print("✔ All screenshots captured successfully!")
	get_tree().quit(0)

func _capture(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	img.save_png(filename)
	print("Saved screenshot: %s" % filename)
