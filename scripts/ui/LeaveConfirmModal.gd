class_name LeaveConfirmModal
extends CanvasLayer

## Confirmation modal when user taps Menu/Back to pause or leave an active game.

signal continue_pressed
signal restart_pressed
signal leave_pressed

@onready var continue_btn: Button = $CenterContainer/Panel/VBox/Buttons/ContinueButton
@onready var restart_btn: Button = $CenterContainer/Panel/VBox/Buttons/RestartButton
@onready var leave_btn: Button = $CenterContainer/Panel/VBox/Buttons/LeaveButton
@onready var panel: PanelContainer = $CenterContainer/Panel

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	restart_btn.pressed.connect(_on_restart)
	leave_btn.pressed.connect(_on_leave)
	
	_setup_button_anim(continue_btn)
	_setup_button_anim(restart_btn)
	_setup_button_anim(leave_btn)
	
	# Entry animation
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16)

func _setup_button_anim(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _on_continue() -> void:
	continue_pressed.emit()
	_animate_close(func():
		queue_free()
	)

func _on_restart() -> void:
	restart_pressed.emit()
	_animate_close(func():
		queue_free()
	)

func _on_leave() -> void:
	leave_pressed.emit()
	_animate_close(func():
		queue_free()
	)

func _animate_close(on_done: Callable) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.88, 0.88), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(on_done)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_continue()
