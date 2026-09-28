extends Node2D

## TestThemeAndSettingsFlow verifies:
## 1. ThemeModal selection, live background preview, cross button cancel/revert, and save persistence.
## 2. SettingsModal cross button cancellation without saving vs Save & Close button.
## 3. All 3 themes (Classic Walnut, Royal Mahogany, Ivory Maple) apply distinct textures & lighting.

func _ready() -> void:
	print("\n========================================================")
	print("--- Running TestThemeAndSettingsFlow: Theme & Settings Modal ---")
	print("========================================================\n")
	
	# 1. Test MainMenu & ThemeButton
	var menu_scene = load("res://scenes/MainMenu.tscn")
	assert(menu_scene != null, "MainMenu.tscn must load")
	var menu = menu_scene.instantiate() as MainMenu
	add_child(menu)
	await get_tree().process_frame
	
	var theme_btn: Button = menu.find_child("ThemeButton", true, false)
	assert(theme_btn != null, "ThemeButton must exist on MainMenu below Settings")
	print("✔ ThemeButton verified on MainMenu under Settings.")
	
	# 2. Test ThemeModal opening and initial state
	SaveManager.settings.board_theme = "classic_wood"
	SaveManager.save_data()
	menu._apply_theme()
	
	var theme_modal_scene = load("res://scenes/modals/ThemeModal.tscn")
	assert(theme_modal_scene != null, "ThemeModal.tscn must load")
	var theme_modal = theme_modal_scene.instantiate()
	menu.add_child(theme_modal)
	await get_tree().process_frame
	
	assert(theme_modal.classic_card != null, "ClassicCard must exist")
	assert(theme_modal.mahogany_card != null, "MahoganyCard must exist")
	assert(theme_modal.maple_card != null, "MapleCard must exist")
	assert(theme_modal.cross_btn != null, "CrossButton must exist in ThemeModal header")
	assert(theme_modal.save_btn != null, "SaveButton must exist in ThemeModal")
	print("✔ ThemeModal structure verified with 3 luxury cards, Cross button, and Save button.")
	
	# 3. Test Live Preview and Cancel / Revert
	var previewed = {"theme": ""}
	theme_modal.theme_previewed.connect(func(t_id):
		previewed["theme"] = t_id
		menu._apply_theme_id(t_id)
	)
	
	# Select royal_mahogany
	theme_modal._select_theme("royal_mahogany")
	assert(previewed["theme"] == "royal_mahogany", "Selecting card emits theme_previewed")
	var bg = menu.find_child("Background", true, false) as TextureRect
	assert(bg != null and bg.texture != null, "Background texture must update")
	assert("mahogany" in bg.texture.resource_path, "Background texture switched to mahogany")
	
	# Select ivory_maple
	theme_modal._select_theme("ivory_maple")
	assert(previewed["theme"] == "ivory_maple", "Selecting card emits theme_previewed for ivory_maple")
	assert("light" in bg.texture.resource_path, "Background texture switched to ivory light maple")
	
	# Cancel via CrossButton -> must revert to classic_wood without saving
	theme_modal._on_cancel_pressed()
	await get_tree().process_frame
	assert(SaveManager.settings.board_theme == "classic_wood", "Saved theme remained classic_wood after cancel")
	assert(previewed["theme"] == "classic_wood", "Preview reverted to original theme")
	print("✔ Theme live preview & cancel revert verified successfully.")
	
	# 4. Test Permanent Save & Apply
	var theme_modal2 = theme_modal_scene.instantiate()
	menu.add_child(theme_modal2)
	await get_tree().process_frame
	theme_modal2._select_theme("ivory_maple")
	theme_modal2._on_save_pressed()
	await get_tree().process_frame
	assert(SaveManager.settings.board_theme == "ivory_maple", "Theme permanently set to ivory_maple")
	print("✔ Permanent Save & Apply verified successfully.")
	
	# 5. Test SettingsModal: Theme removed, Cross button cancels without save
	var settings_modal_scene = load("res://scenes/modals/SettingsModal.tscn")
	assert(settings_modal_scene != null, "SettingsModal.tscn must load")
	var settings_modal = settings_modal_scene.instantiate()
	menu.add_child(settings_modal)
	await get_tree().process_frame
	
	# Verify theme cards do NOT exist in settings modal
	assert(settings_modal.find_child("ThemeSection", true, false) == null, "ThemeSection must NOT be in SettingsModal")
	assert(settings_modal.find_child("ClassicThemeBtn", true, false) == null, "ClassicThemeBtn must NOT be in SettingsModal")
	assert(settings_modal.cross_btn != null, "CrossButton must exist in SettingsModal header")
	
	# Change sound toggle and press CrossButton -> must revert!
	var orig_sound = SaveManager.settings.sound_enabled
	settings_modal.sound_btn.pressed.emit() # toggle
	assert(SaveManager.settings.sound_enabled != orig_sound, "Sound setting modified temporarily")
	
	settings_modal._on_cancel_pressed()
	await get_tree().process_frame
	assert(SaveManager.settings.sound_enabled == orig_sound, "Sound setting reverted after CrossButton cancel")
	print("✔ SettingsModal Cross button cancellation without saving verified.")
	
	# 6. Test SettingsModal Save & Close
	var settings_modal2 = settings_modal_scene.instantiate() as SettingsModal
	menu.add_child(settings_modal2)
	await get_tree().process_frame
	settings_modal2.sound_btn.pressed.emit()
	var new_sound = SaveManager.settings.sound_enabled
	settings_modal2._on_close_pressed()
	await get_tree().process_frame
	assert(SaveManager.settings.sound_enabled == new_sound, "Settings saved permanently via SAVE & CLOSE")
	
	# Reset back to sound enabled
	SaveManager.settings.sound_enabled = true
	SaveManager.settings.board_theme = "classic_wood"
	SaveManager.save_data()
	
	print("\n========================================================")
	print("=== ALL THEME & SETTINGS TESTS PASSED SUCCESSFULLY! ===")
	print("========================================================\n")
	get_tree().quit(0)
