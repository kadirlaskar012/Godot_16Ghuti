class_name SplashScreen
extends Control

## SplashScreen introduces 16 GUTI with warm glow and smooth transition to MainMenu.

@onready var logo: TextureRect = $CenterContainer/VBox/Logo
@onready var label: Label = $CenterContainer/VBox/TitleLabel
@onready var sub_label: Label = $CenterContainer/VBox/SubLabel

func _ready() -> void:
	modulate.a = 0.0
	logo.scale = Vector2(0.85, 0.85)
	
	# Smooth fade in and zoom
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	AudioManager.play_sfx("turn")
	
	# Hold for 1.2s then fade to main menu
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		var fade_out = create_tween()
		fade_out.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		fade_out.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		)
	)
