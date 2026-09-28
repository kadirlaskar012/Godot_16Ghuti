class_name HowToPlayModal
extends CanvasLayer

signal closed

@onready var close_btn: Button = $CenterContainer/Panel/VBox/CloseButton

func _ready() -> void:
	close_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		closed.emit()
		queue_free()
	)
	var dim = get_node_or_null("DimOverlay") as Control
	if dim:
		dim.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				AudioManager.play_sfx("click")
				closed.emit()
				queue_free()
		)
