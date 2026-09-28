class_name SafeAreaHelper
extends RefCounted

## Utility to calculate responsive safe area margins across any Android / iOS device.
## Ensures notches, punch-hole cameras, status bars, and navigation pills never obscure game UI.

static func get_safe_margins(viewport_width: float = 1080.0) -> Dictionary:
	var top = 56.0 # Base design safe fallback for modern notched mobile screens
	var bottom = 32.0
	var left = 0.0
	var right = 0.0
	
	var safe_rect = DisplayServer.get_display_safe_area()
	var screen_size = DisplayServer.screen_get_size()
	
	if screen_size.x > 0 and screen_size.y > 0:
		var scale_x = viewport_width / float(screen_size.x)
		var calc_top = float(safe_rect.position.y) * scale_x
		var calc_bottom = float(screen_size.y - (safe_rect.position.y + safe_rect.size.y)) * scale_x
		var calc_left = float(safe_rect.position.x) * scale_x
		var calc_right = float(screen_size.x - (safe_rect.position.x + safe_rect.size.x)) * scale_x
		if calc_top > 20.0:
			top = maxf(calc_top, 56.0)
		if calc_bottom > 15.0:
			bottom = maxf(calc_bottom, 32.0)
		if calc_left > 0.0:
			left = calc_left
		if calc_right > 0.0:
			right = calc_right
			
	return {"top": top, "bottom": bottom, "left": left, "right": right}
