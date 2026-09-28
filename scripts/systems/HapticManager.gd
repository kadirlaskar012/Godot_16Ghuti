extends Node

## HapticManager Singleton
## Manages Android handheld vibrations and tactile feedback patterns

func vibrate_selection() -> void:
	if not _is_haptics_enabled():
		return
	# Light vibration: 25ms
	Input.vibrate_handheld(25)

func vibrate_move() -> void:
	if not _is_haptics_enabled():
		return
	# Light vibration: 35ms
	Input.vibrate_handheld(35)

func vibrate_capture() -> void:
	if not _is_haptics_enabled():
		return
	# Medium crisp vibration: 50ms
	Input.vibrate_handheld(50)

func vibrate_combo(level: int = 1) -> void:
	if not _is_haptics_enabled():
		return
	if level <= 1:
		Input.vibrate_handheld(50)
	elif level == 2:
		# Double crisp pulse
		Input.vibrate_handheld(65)
	else:
		# Triple/intense combo vibration
		Input.vibrate_handheld(85)
		var tree = get_tree()
		if tree:
			tree.create_timer(0.08).timeout.connect(func():
				Input.vibrate_handheld(50)
			)

func vibrate_invalid() -> void:
	if not _is_haptics_enabled():
		return
	# Double short buzz
	Input.vibrate_handheld(30)

func vibrate_victory() -> void:
	if not _is_haptics_enabled():
		return
	# Celebratory pattern: buzz - pause - buzz - pause - long buzz
	Input.vibrate_handheld(50)
	var tree = get_tree()
	if tree:
		tree.create_timer(0.1).timeout.connect(func():
			Input.vibrate_handheld(70)
			tree.create_timer(0.12).timeout.connect(func():
				Input.vibrate_handheld(120)
			)
		)

func _is_haptics_enabled() -> bool:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.settings:
		return sm.settings.haptics_enabled
	return true
