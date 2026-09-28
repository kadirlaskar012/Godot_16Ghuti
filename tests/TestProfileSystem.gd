extends Node

func _ready() -> void:
	print("--- TEST PROFILE SYSTEM START ---")
	
	# 1. Test PlayerData
	var p = SaveManager.player_data
	assert(p != null, "player_data should not be null")
	print("Initial Player ID:", p.player_id)
	assert(not p.player_id.is_empty(), "player_id must not be empty")
	assert(p.player_id.begins_with("#G"), "player_id must begin with #G")
	
	# Level calculation test
	var l1 = PlayerData.get_level_info(0)
	assert(l1["level"] == 1, "0 XP should be level 1")
	assert(l1["current_xp"] == 0, "0 XP current_xp should be 0")
	assert(l1["max_xp"] == 500, "Level 1 max_xp should be 500")
	
	var l2 = PlayerData.get_level_info(600)
	assert(l2["level"] == 2, "600 XP should be level 2")
	assert(l2["current_xp"] == 100, "600 XP current_xp should be 100")
	assert(l2["max_xp"] == 750, "Level 2 max_xp should be 750")
	
	# Win rate test
	p.games_played = 10
	p.games_won = 6
	p.games_lost = 3
	p.games_draw = 1
	var wr = p.get_win_rate()
	assert(is_equal_approx(wr, 60.0), "Win rate for 6/10 should be 60.0%")
	
	# 2. Test Instantiating ProfileModal
	var profile_scene = load("res://scenes/modals/ProfileModal.tscn")
	assert(profile_scene != null, "ProfileModal.tscn should load successfully")
	var profile = profile_scene.instantiate()
	add_child(profile)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check nodes
	var name_lbl = profile.find_child("PlayerNameLabel", true, false)
	assert(name_lbl != null, "PlayerNameLabel must exist")
	print("Profile displayed name:", name_lbl.text)
	
	var id_lbl = profile.find_child("PlayerIdLabel", true, false)
	assert(id_lbl != null, "PlayerIdLabel must exist")
	print("Profile displayed ID:", id_lbl.text)
	assert(id_lbl.text.contains(p.player_id), "PlayerIdLabel must show player_id")
	
	var lvl_lbl = profile.find_child("LevelLabel", true, false)
	assert(lvl_lbl != null, "LevelLabel must exist")
	
	var coins_lbl = profile.find_child("CoinsLabel", true, false)
	assert(coins_lbl != null, "CoinsLabel must exist")
	assert(coins_lbl.text.contains(str(p.coins)), "CoinsLabel must display current coins")
	
	var style_guti = profile.find_child("StyleGutiLabel", true, false)
	assert(style_guti != null, "StyleGutiLabel must exist")
	assert(style_guti.text == p.equipped_guti, "StyleGutiLabel must show equipped guti")
	
	# 3. Test EditProfileModal
	var edit_scene = load("res://scenes/modals/EditProfileModal.tscn")
	assert(edit_scene != null, "EditProfileModal.tscn should load successfully")
	var edit_modal = edit_scene.instantiate()
	add_child(edit_modal)
	await get_tree().process_frame
	
	var line_edit = edit_modal.find_child("NameInput", true, false)
	assert(line_edit != null, "NameInput must exist")
	
	# Test name saving
	var original_name = p.player_name
	line_edit.text = "   ProGamer16   "
	var save_btn = edit_modal.find_child("SaveButton", true, false)
	assert(save_btn != null, "SaveButton must exist")
	save_btn.emit_signal("pressed")
	await get_tree().process_frame
	
	assert(p.player_name == "ProGamer16", "Player name should be trimmed to ProGamer16")
	print("Updated name:", p.player_name)
	
	# Test empty name rejected
	var edit_modal2 = edit_scene.instantiate()
	add_child(edit_modal2)
	await get_tree().process_frame
	var line_edit2 = edit_modal2.find_child("NameInput", true, false)
	line_edit2.text = "    "
	var save_btn2 = edit_modal2.find_child("SaveButton", true, false)
	save_btn2.emit_signal("pressed")
	await get_tree().process_frame
	assert(p.player_name == "ProGamer16", "Empty name must not overwrite existing name")
	
	# Clean up edit modals
	if is_instance_valid(edit_modal):
		edit_modal.queue_free()
	if is_instance_valid(edit_modal2):
		edit_modal2.queue_free()
		
	# Populate sample match history
	p.recent_matches.clear()
	p.recent_matches.append({"opponent": "AI Bot (Medium)", "mode": "VS AI", "result": "WIN", "duration": "04:32", "date": "Today"})
	p.recent_matches.append({"opponent": "Player 2", "mode": "Pass & Play", "result": "LOSS", "duration": "03:15", "date": "Yesterday"})
	p.recent_matches.append({"opponent": "AI Bot (Hard)", "mode": "VS AI", "result": "DRAW", "duration": "05:00", "date": "2 days ago"})
	profile._populate_all_data()
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Capture screenshot if rendering server is active
	await get_tree().create_timer(0.4).timeout
	var vp_tex = get_viewport().get_texture()
	if vp_tex != null:
		var image = vp_tex.get_image()
		if image != null:
			var err = image.save_png("res://screenshot_profile_modal.png")
			if err == OK:
				print("Screenshot saved to screenshot_profile_modal.png")
		
	print("--- ALL PROFILE SYSTEM TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
