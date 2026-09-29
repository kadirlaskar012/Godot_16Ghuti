class_name GameResultModal
extends CanvasLayer

## GameResultModal displays the post-game summary (Screens 7 & 8)
## Screen 7: YOU WIN! banner, praise, match stats, and action buttons.
## Screen 8: YOU LOSE! banner, encouragement, stats, and action buttons.
## Quick access to Screen 9: GameOverOptionsModal.

signal rematch_pressed
signal main_menu_pressed

const GAME_OVER_OPTIONS_SCENE = preload("res://scenes/modals/GameOverOptionsModal.tscn")
const CONFETTI_SCENE = preload("res://scenes/effects/VictoryConfetti.tscn")

const WIN_BANNER_TEX = preload("res://assets/textures/banner_win.jpg")
const LOSE_BANNER_TEX = preload("res://assets/textures/banner_lose.jpg")

@onready var banner_rect: TextureRect = find_child("BannerTexture", true, false)
@onready var title_label: Label = find_child("TitleLabel", true, false)
@onready var winner_label: Label = find_child("WinnerLabel", true, false)
@onready var reason_label: Label = find_child("ReasonLabel", true, false)

@onready var time_stat_label: Label = find_child("TimeStat", true, false)
@onready var moves_stat_label: Label = find_child("MovesStat", true, false)
@onready var pieces_stat_label: Label = find_child("PiecesStat", true, false)
@onready var reward_stat_label: Label = find_child("RewardStat", true, false)

@onready var rematch_btn: Button = find_child("RematchButton", true, false)
@onready var menu_btn: Button = find_child("MenuButton", true, false)
@onready var options_btn: Button = find_child("OptionsButton", true, false)
@onready var panel: PanelContainer = find_child("Panel", true, false)

var _winner: int = BoardData.Player.NONE
var _reason: String = ""
var _duration: float = 0.0
var _remaining_pieces: int = 0
var _captures: int = 0
var _moves: int = 0
var _is_time_up: bool = false
var _data_initialized: bool = false

func _ready() -> void:
	if rematch_btn:
		rematch_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			rematch_pressed.emit()
			queue_free()
		)
		_setup_btn(rematch_btn)
		
	if menu_btn:
		menu_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			main_menu_pressed.emit()
			queue_free()
		)
		_setup_btn(menu_btn)
		
	if options_btn:
		options_btn.pressed.connect(_on_options_pressed)
		_setup_btn(options_btn)
	
	if panel:
		panel.pivot_offset = panel.custom_minimum_size / 2.0
		panel.scale = Vector2(0.85, 0.85)
		panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	
	if _data_initialized:
		_apply_data()

func _setup_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD)
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
	)

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
	var is_human_winner = false
	
	if mode == GameManager.GameMode.PLAYER_VS_AI:
		is_human_winner = (_winner == GameManager.player_ghuti_color)
	else:
		is_human_winner = (_winner == BoardData.Player.PLAYER_1)
		
	if banner_rect:
		if is_human_winner:
			banner_rect.texture = WIN_BANNER_TEX
		else:
			banner_rect.texture = LOSE_BANNER_TEX
			
	if is_human_winner:
		title_label.text = "🏆 YOU WIN!"
		title_label.modulate = Color(1.0, 0.88, 0.35)
		winner_label.text = "Incredible Victory!"
		winner_label.modulate = Color(1.0, 0.95, 0.9)
		AudioManager.play_sfx("victory")
		HapticManager.vibrate_victory()
		_spawn_confetti()
		if reward_stat_label: reward_stat_label.text = "💰 +100 Coins"
	else:
		if _winner == BoardData.Player.NONE:
			title_label.text = "🤝 DRAW MATCH"
			title_label.modulate = Color(0.9, 0.85, 0.7)
			winner_label.text = "Both players fought valiantly!"
			if reward_stat_label: reward_stat_label.text = "💰 +40 Coins"
		else:
			title_label.text = "👑 YOU LOSE"
			title_label.modulate = Color(0.7, 0.85, 1.0)
			winner_label.text = "Better luck next time!"
			AudioManager.play_sfx("defeat")
			if reward_stat_label: reward_stat_label.text = "💰 +25 Coins"
			
	if reason_label:
		reason_label.text = _reason
		
	var mins = int(_duration) / 60
	var secs = int(_duration) % 60
	
	if time_stat_label:
		time_stat_label.text = "⏱️ Time: %02d:%02d" % [mins, secs]
	if moves_stat_label:
		moves_stat_label.text = "🎯 Moves: %d" % _moves
	if pieces_stat_label:
		pieces_stat_label.text = "🔴 Pieces: %d Ghuti" % _remaining_pieces

func _on_options_pressed() -> void:
	AudioManager.play_sfx("click")
	var opt_modal = GAME_OVER_OPTIONS_SCENE.instantiate()
	opt_modal.play_again_pressed.connect(func():
		rematch_pressed.emit()
		queue_free()
	)
	opt_modal.back_to_home_pressed.connect(func():
		main_menu_pressed.emit()
		queue_free()
	)
	opt_modal.change_difficulty_pressed.connect(func(_d: int):
		rematch_pressed.emit()
		queue_free()
	)
	opt_modal.change_theme_pressed.connect(func(_t: String):
		rematch_pressed.emit()
		queue_free()
	)
	opt_modal.change_ghuti_color_pressed.connect(func(_c: int):
		rematch_pressed.emit()
		queue_free()
	)
	add_child(opt_modal)

func _spawn_confetti() -> void:
	var c = CONFETTI_SCENE.instantiate()
	add_child(c)
	c.position = Vector2(540, 250)
	c.emitting = true
