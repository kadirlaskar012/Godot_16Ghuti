class_name GameResultModal
extends CanvasLayer

## GameResultModal displays the post-game summary, stats, rematch, and menu buttons.
## Supports both normal elimination game over and time-out (TIME UP) results.

signal rematch_pressed
signal main_menu_pressed

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var winner_label: Label = $CenterContainer/Panel/VBox/WinnerLabel
@onready var reason_label: Label = $CenterContainer/Panel/VBox/ReasonLabel
@onready var stats_label: Label = $CenterContainer/Panel/VBox/StatsLabel
@onready var rematch_btn: Button = $CenterContainer/Panel/VBox/HBox/RematchButton
@onready var menu_btn: Button = $CenterContainer/Panel/VBox/HBox/MenuButton
@onready var panel: PanelContainer = $CenterContainer/Panel

const CONFETTI_SCENE = preload("res://scenes/effects/VictoryConfetti.tscn")

var _winner: int = BoardData.Player.NONE
var _reason: String = ""
var _duration: float = 0.0
var _remaining_pieces: int = 0
var _captures: int = 0
var _moves: int = 0
var _is_time_up: bool = false
var _data_initialized: bool = false

func _ready() -> void:
	rematch_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		rematch_pressed.emit()
		queue_free()
	)
	menu_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		main_menu_pressed.emit()
		queue_free()
	)
	
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	
	if _data_initialized:
		_apply_data()

func setup(winner: int, reason: String, duration: float, remaining_pieces: int, captures: int, moves: int = 0, is_time_up: bool = false) -> void:
	_winner = winner
	_reason = reason
	_duration = duration
	_remaining_pieces = remaining_pieces
	_captures = captures
	_moves = moves
	_is_time_up = is_time_up
	_data_initialized = true
	
	if is_inside_tree() and title_label != null:
		_apply_data()

func _apply_data() -> void:
	if title_label == null:
		return
		
	var mode = GameManager.current_mode
	
	if _is_time_up:
		title_label.text = "TIME UP"
		title_label.modulate = Color(1.0, 0.85, 0.35)
		
		if _winner == BoardData.Player.PLAYER_1:
			winner_label.text = "PLAYER 1 WINS"
			winner_label.modulate = Color(1.0, 0.45, 0.4)
			AudioManager.play_sfx("victory")
			HapticManager.vibrate_victory()
			_spawn_confetti()
		elif _winner == BoardData.Player.PLAYER_2:
			winner_label.text = "PLAYER 2 WINS"
			winner_label.modulate = Color(0.95, 0.92, 0.82)
			if mode == GameManager.GameMode.PLAYER_VS_AI:
				AudioManager.play_sfx("defeat")
			else:
				AudioManager.play_sfx("victory")
				HapticManager.vibrate_victory()
				_spawn_confetti()
		else:
			winner_label.text = "DRAW"
			winner_label.modulate = Color(1.0, 0.9, 0.7)
			AudioManager.play_sfx("turn")
	else:
		if mode == GameManager.GameMode.PLAYER_VS_AI:
			if _winner == BoardData.Player.PLAYER_1:
				title_label.text = "🏆 VICTORY!"
				title_label.modulate = Color(1.0, 0.85, 0.3)
				winner_label.text = "You defeated the AI!"
				winner_label.modulate = Color(1.0, 0.95, 0.9)
				AudioManager.play_sfx("victory")
				HapticManager.vibrate_victory()
				_spawn_confetti()
			elif _winner == BoardData.Player.PLAYER_2:
				title_label.text = "DEFEAT"
				title_label.modulate = Color(0.9, 0.4, 0.4)
				winner_label.text = "AI claimed victory this round."
				winner_label.modulate = Color(0.9, 0.85, 0.8)
				AudioManager.play_sfx("defeat")
			else:
				title_label.text = "STALEMATE"
				title_label.modulate = Color(0.9, 0.85, 0.7)
				winner_label.text = "Match ended in a draw."
		else: # Local 2P
			if _winner == BoardData.Player.PLAYER_1:
				title_label.text = "🔴 PLAYER 1 WINS!"
				title_label.modulate = Color(1.0, 0.35, 0.35)
				winner_label.text = "Player 1 takes the match!"
				winner_label.modulate = Color(1.0, 0.95, 0.9)
				AudioManager.play_sfx("victory")
				HapticManager.vibrate_victory()
				_spawn_confetti()
			elif _winner == BoardData.Player.PLAYER_2:
				title_label.text = "⚪ PLAYER 2 WINS!"
				title_label.modulate = Color(0.95, 0.95, 0.85)
				winner_label.text = "Player 2 takes the match!"
				winner_label.modulate = Color(1.0, 0.95, 0.9)
				AudioManager.play_sfx("victory")
				HapticManager.vibrate_victory()
				_spawn_confetti()
			else:
				title_label.text = "DRAW"
				title_label.modulate = Color(0.9, 0.85, 0.7)
				winner_label.text = "Match ended in a draw."
				
	reason_label.text = _reason
	
	var mins = int(_duration) / 60
	var secs = int(_duration) % 60
	stats_label.text = "Remaining: %d Guti   •   Captures: %d   •   Moves: %d\nMatch Time: %02d:%02d" % [_remaining_pieces, _captures, _moves, mins, secs]

func _spawn_confetti() -> void:
	var c = CONFETTI_SCENE.instantiate()
	add_child(c)
	c.position = Vector2(540, 250)
	c.emitting = true
