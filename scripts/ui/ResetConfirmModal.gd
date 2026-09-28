class_name ResetConfirmModal
extends CanvasLayer

signal confirmed
signal cancelled

@onready var confirm_btn: Button = $CenterContainer/Panel/VBox/HBox/ConfirmButton
@onready var cancel_btn: Button = $CenterContainer/Panel/VBox/HBox/CancelButton

func _ready() -> void:
	confirm_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		confirmed.emit()
		queue_free()
	)
	cancel_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		cancelled.emit()
		queue_free()
	)
