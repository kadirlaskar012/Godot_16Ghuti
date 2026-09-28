extends Node

## Comprehensive Multi-Resolution Test for 16 Guti Responsive Board
## Validates board scaling, margins, centering, aspect ratio, and zero overlap
## across all required test resolutions: 360x800, 390x844, 412x915, 1080x1920, 1440x2560.

func _ready() -> void:
	print("\n=======================================================")
	print("=== RUNNING TEST: Multi-Resolution Board Layout Suite ===")
	print("=======================================================\n")
	
	var test_resolutions = [
		{"name": "360x800 (Compact Mobile 20:9)", "w": 360.0, "h": 800.0},
		{"name": "390x844 (Modern iPhone 19.5:9)", "w": 390.0, "h": 844.0},
		{"name": "412x915 (Modern Android 20:9)", "w": 412.0, "h": 915.0},
		{"name": "1080x1920 (Standard FHD 16:9)", "w": 1080.0, "h": 1920.0},
		{"name": "1440x2560 (QHD Flagship 16:9)", "w": 1440.0, "h": 2560.0}
	]
	
	var game_scene = load("res://scenes/Game.tscn")
	var game: GameController = game_scene.instantiate()
	add_child(game)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var hud: GameHUD = game.get_node("GameHUD")
	var board: BoardManager = game.get_node("Board")
	var p2 = hud.find_child("P2Card", true, false)
	var p1 = hud.find_child("P1Card", true, false)
	var bb = hud.find_child("BottomBar", true, false)
	
	const BASE_W: float = 998.4
	const BASE_H: float = 1348.48
	const BASE_ASPECT: float = BASE_W / BASE_H
	
	print("\n--- Part A: Testing Android Native Expansion Scaling ---")
	# In Godot (canvas_items + expand), canvas width is 1080, and height scales proportionally with device aspect ratio
	for res in test_resolutions:
		var aspect_ratio = res["w"] / res["h"]
		var canvas_w = 1080.0
		var canvas_h = 1080.0 / aspect_ratio
		var test_vp = Vector2(canvas_w, canvas_h)
		
		get_viewport().size = Vector2i(int(canvas_w), int(canvas_h))
		await get_tree().process_frame
		game._update_responsive_layout()
		await get_tree().process_frame
		
		var b_scale = board.scale.x
		var b_scale_y = board.scale.y
		var b_w = BASE_W * b_scale
		var b_h = BASE_H * b_scale_y
		var b_center_x = board.position.x + 540.0 * b_scale
		var b_center_y = board.position.y + 960.0 * b_scale_y
		var b_top = b_center_y - (b_h / 2.0)
		var b_bot = b_center_y + (b_h / 2.0)
		var b_left = b_center_x - (b_w / 2.0)
		var b_right = b_center_x + (b_w / 2.0)
		
		var left_margin = b_left
		var right_margin = test_vp.x - b_right
		var width_ratio = b_w / test_vp.x
		
		var p2_bottom = p2.position.y + p2.size.y
		var gap_p2_board = b_top - p2_bottom
		var gap_board_p1 = p1.position.y - b_bot
		var dist_screen_bot = test_vp.y - (bb.position.y + bb.size.y)
		
		print("\nDevice: %s [Canvas: %dx%d]" % [res["name"], int(canvas_w), int(canvas_h)])
		print("  Board Size: %.1f x %.1f (Scale: %.4f)" % [b_w, b_h, b_scale])
		print("  Width Ratio: %.1f%% of screen width" % [width_ratio * 100.0])
		print("  Margins: Left=%.1f px, Right=%.1f px (Equal: %s)" % [left_margin, right_margin, abs(left_margin - right_margin) < 1.0])
		print("  Gap P2 to Board: %.1f px (No overlap: %s)" % [gap_p2_board, gap_p2_board > 0])
		print("  Gap Board to P1: %.1f px (No overlap: %s)" % [gap_board_p1, gap_board_p1 > 0])
		print("  Bottom distance to screen: %.1f px" % [dist_screen_bot])
		
		# Assertions
		assert(abs(b_scale - b_scale_y) < 0.001, "Aspect ratio must be preserved exactly!")
		assert(width_ratio >= 0.94 and width_ratio <= 0.96, "Board width must be 94-96% of safe screen width!")
		assert(abs(left_margin - right_margin) < 1.0, "Board must be horizontally centered with equal margins!")
		assert(b_left >= 0.0 and b_right <= test_vp.x, "Board must fit inside horizontal screen boundaries!")
		assert(gap_p2_board >= 14.0, "Board must NOT overlap top player HUD!")
		assert(gap_board_p1 >= 14.0, "Board must NOT overlap bottom player HUD!")
		assert(dist_screen_bot >= 15.0, "BottomBar must fit inside screen without clipping!")
		print("  ✔ Passed all constraints for %s" % res["name"])
		
	print("\n--- Part B: Testing Standalone SubViewport Raw Pixel Scaling ---")
	game.queue_free()
	await get_tree().process_frame
	
	for res in test_resolutions:
		var raw_w = res["w"]
		var raw_h = res["h"]
		var raw_vp = Vector2(raw_w, raw_h)
		
		var sub_vp = SubViewport.new()
		sub_vp.size = Vector2i(int(raw_w), int(raw_h))
		add_child(sub_vp)
		
		var sub_game: GameController = game_scene.instantiate()
		sub_vp.add_child(sub_game)
		
		await get_tree().process_frame
		await get_tree().process_frame
		
		var sub_hud: GameHUD = sub_game.get_node("GameHUD")
		var sub_board: BoardManager = sub_game.get_node("Board")
		var sub_p2 = sub_hud.find_child("P2Card", true, false)
		var sub_p1 = sub_hud.find_child("P1Card", true, false)
		var sub_bb = sub_hud.find_child("BottomBar", true, false)
		
		var b_scale = sub_board.scale.x
		var b_scale_y = sub_board.scale.y
		var b_w = BASE_W * b_scale
		var b_h = BASE_H * b_scale_y
		var b_center_x = sub_board.position.x + 540.0 * b_scale
		var b_center_y = sub_board.position.y + 960.0 * b_scale_y
		var b_top = b_center_y - (b_h / 2.0)
		var b_bot = b_center_y + (b_h / 2.0)
		var b_left = b_center_x - (b_w / 2.0)
		var b_right = b_center_x + (b_w / 2.0)
		
		var left_margin = b_left
		var right_margin = raw_vp.x - b_right
		var width_ratio = b_w / raw_vp.x
		
		var p2_bottom = sub_p2.position.y + sub_p2.size.y
		var gap_p2_board = b_top - p2_bottom
		var gap_board_p1 = sub_p1.position.y - b_bot
		
		print("\nSubViewport: %s [%dx%d]" % [res["name"], int(raw_w), int(raw_h)])
		print("  Board Size: %.1f x %.1f (Scale: %.4f)" % [b_w, b_h, b_scale])
		print("  Width Ratio: %.1f%% of screen width" % [width_ratio * 100.0])
		print("  Margins: Left=%.1f px, Right=%.1f px" % [left_margin, right_margin])
		print("  Gap P2 to Board: %.1f px, Gap Board to P1: %.1f px" % [gap_p2_board, gap_board_p1])
		
		assert(abs(b_scale - b_scale_y) < 0.001, "Aspect ratio must be preserved exactly!")
		assert(b_left >= 0.0 and b_right <= raw_vp.x + 1.0, "Board must fit inside horizontal screen boundaries!")
		assert(abs(left_margin - right_margin) < 1.0, "Board must be horizontally centered with equal margins!")
		assert(gap_p2_board >= -1.0, "Board must NOT overlap top player HUD!")
		assert(gap_board_p1 >= -1.0, "Board must NOT overlap bottom player HUD!")
		print("  ✔ Passed all constraints for %s" % res["name"])
		
		sub_vp.queue_free()
		await get_tree().process_frame
		
	print("\n=======================================================")
	print("ALL MULTI-RESOLUTION BOARD TESTS PASSED (100%)!")
	print("=======================================================\n")
	get_tree().quit(0)
