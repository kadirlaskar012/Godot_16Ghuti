extends Node

func _ready() -> void:
	print("--- Capturing Profile Screenshots ---")
	
	# Ensure realistic mock data for preview presentation
	var p = SaveManager.player_data
	p.player_name = "Player 1"
	p.coins = 500
	p.xp = 320
	p.games_played = 24
	p.games_won = 15
	p.games_lost = 7
	p.games_draw = 2
	p.total_captures = 128
	p.best_win_streak = 5
	p.total_play_time_seconds = 8520.0 # ~2h 22m
	p.equipped_guti = "Classic Red"
	p.equipped_board = "Classic Wood"
	p.equipped_victory = "Classic Sparkle"
	
	p.recent_matches.clear()
	p.recent_matches.append({
		"opponent": "AI Bot (Medium)",
		"mode": "VS AI",
		"result": "WIN",
		"duration": "04:32",
		"date": "Today"
	})
	p.recent_matches.append({
		"opponent": "Player 2",
		"mode": "Pass & Play",
		"result": "LOSS",
		"duration": "03:18",
		"date": "Yesterday"
	})
	p.recent_matches.append({
		"opponent": "AI Bot (Hard)",
		"mode": "VS AI",
		"result": "WIN",
		"duration": "06:12",
		"date": "2 days ago"
	})
	p.recent_matches.append({
		"opponent": "Player 2",
		"mode": "Pass & Play",
		"result": "DRAW",
		"duration": "05:00",
		"date": "3 days ago"
	})
	
	# 1. MainMenu with Profile Modal open (Top View)
	var menu_scene = load("res://scenes/MainMenu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	
	var prof_scene = load("res://scenes/modals/ProfileModal.tscn")
	var profile = prof_scene.instantiate()
	add_child(profile)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	
	var img1 = get_viewport().get_texture().get_image()
	if img1:
		img1.save_png("screenshot_profile_modal.png")
		print("✔ Saved screenshot_profile_modal.png")
		
	# 2. Scrolled down view showing Achievements & Recent Matches
	var scroll = profile.find_child("ScrollContainer", true, false) as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 650
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	var img_scroll = get_viewport().get_texture().get_image()
	if img_scroll:
		img_scroll.save_png("screenshot_profile_modal_scroll.png")
		print("✔ Saved screenshot_profile_modal_scroll.png")
		
	# 3. Open Edit Profile Modal
	if scroll:
		scroll.scroll_vertical = 0
	var edit_scene = load("res://scenes/modals/EditProfileModal.tscn")
	var edit_modal = edit_scene.instantiate()
	profile.add_child(edit_modal)
	
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	
	var img2 = get_viewport().get_texture().get_image()
	if img2:
		img2.save_png("screenshot_edit_profile_modal.png")
		print("✔ Saved screenshot_edit_profile_modal.png")
		
	print("Profile screenshots capture completed!")
	get_tree().quit(0)
