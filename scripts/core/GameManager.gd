extends Node

## GameManager Singleton
## Manages global game mode, session state, navigation, and match lifecycle.

enum GameMode {
	PLAYER_VS_AI = 0,
	LOCAL_2P = 1,
	ONLINE_MULTIPLAYER = 2
}

enum MatchState {
	READY = 0,
	PLAYING = 1,
	PAUSED = 2,
	TIME_UP = 3,
	GAME_OVER = 4
}

var current_mode: int = GameMode.PLAYER_VS_AI
var current_difficulty: int = AIManager.Difficulty.MEDIUM
var current_theme: String = "classic_wood"
var player_ghuti_color: int = BoardData.Player.PLAYER_1
var current_state: GameState
var match_state: int = MatchState.READY

# Match tracking
var match_start_time: float = 0.0
var match_duration: float = 0.0
var p1_match_captures: int = 0
var p2_match_captures: int = 0
var is_game_active: bool = false

# Player Custom Profiles for Local 2P
var p1_custom_name: String = ""
var p1_custom_avatar_idx: int = -1
var p2_custom_name: String = ""
var p2_custom_avatar_idx: int = -1

func set_local_players(p1_name: String, p1_av: int, p2_name: String, p2_av: int) -> void:
	p1_custom_name = p1_name.strip_edges()
	p1_custom_avatar_idx = p1_av
	p2_custom_name = p2_name.strip_edges()
	p2_custom_avatar_idx = p2_av

signal match_started(mode)
signal match_ended(winner, reason)
signal state_changed

func _ready() -> void:
	current_state = GameState.new()

func is_playing() -> bool:
	if is_game_active and match_state == MatchState.READY:
		match_state = MatchState.PLAYING
	return is_game_active and match_state == MatchState.PLAYING

func pause_match() -> void:
	if match_state == MatchState.PLAYING:
		match_state = MatchState.PAUSED
		state_changed.emit()

func resume_match() -> void:
	if match_state == MatchState.PAUSED:
		match_state = MatchState.PLAYING
		state_changed.emit()

func start_match(mode: int = GameMode.PLAYER_VS_AI, difficulty: int = AIManager.Difficulty.MEDIUM, theme: String = "", player_color: int = BoardData.Player.PLAYER_1) -> void:
	current_mode = mode
	current_difficulty = difficulty
	player_ghuti_color = player_color
	if theme != "":
		current_theme = theme
		var sm_inst = get_node_or_null("/root/SaveManager")
		if sm_inst and sm_inst.settings:
			sm_inst.settings.board_theme = theme
			sm_inst.save_settings()
	current_state.reset_to_start()
	
	match_start_time = Time.get_ticks_msec() / 1000.0
	match_duration = 0.0
	p1_match_captures = 0
	p2_match_captures = 0
	is_game_active = true
	match_state = MatchState.PLAYING
	
	match_started.emit(current_mode)
	state_changed.emit()
	
	get_tree().change_scene_to_file.call_deferred("res://scenes/Game.tscn")

func restart_current_match() -> void:
	current_state.reset_to_start()
	match_start_time = Time.get_ticks_msec() / 1000.0
	match_duration = 0.0
	p1_match_captures = 0
	p2_match_captures = 0
	is_game_active = true
	match_state = MatchState.PLAYING
	
	match_started.emit(current_mode)
	state_changed.emit()

func end_match(winner: int, reason: String, is_time_out: bool = false) -> void:
	if not is_game_active and match_state != MatchState.PLAYING and match_state != MatchState.PAUSED:
		return
	is_game_active = false
	match_state = MatchState.TIME_UP if is_time_out else MatchState.GAME_OVER
	match_duration = (Time.get_ticks_msec() / 1000.0) - match_start_time
	
	# Update lifetime statistics
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.player_data:
		var p_data = sm.player_data
		if current_mode == GameMode.PLAYER_VS_AI:
			var diff_str = "Easy"
			if current_difficulty == AIManager.Difficulty.MEDIUM:
				diff_str = "Medium"
			elif current_difficulty == AIManager.Difficulty.HARD:
				diff_str = "Hard"
			elif current_difficulty == AIManager.Difficulty.EXPERT:
				diff_str = "Expert"
			var diff_name = "AI Bot (%s)" % diff_str
			if winner == BoardData.Player.PLAYER_1:
				p_data.record_win(current_difficulty, p1_match_captures, match_duration, diff_name, "VS AI")
			elif winner == BoardData.Player.PLAYER_2:
				p_data.record_loss(p1_match_captures, match_duration, diff_name, "VS AI")
			else:
				p_data.record_draw(p1_match_captures, match_duration, diff_name, "VS AI")
		else: # Local 2P
			if winner == BoardData.Player.PLAYER_1:
				p_data.record_win(-1, p1_match_captures, match_duration, "Player 2", "LOCAL 2P")
			elif winner == BoardData.Player.PLAYER_2:
				p_data.record_loss(p1_match_captures, match_duration, "Player 2", "LOCAL 2P")
			else:
				p_data.record_draw(p1_match_captures, match_duration, "Player 2", "LOCAL 2P")
		sm.save_data()
		
	# Trigger victory haptics and audio
	var hm = get_node_or_null("/root/HapticManager")
	var am = get_node_or_null("/root/AudioManager")
	if winner == BoardData.Player.PLAYER_1:
		if am: am.play_sfx("victory")
		if hm: hm.vibrate_victory()
	elif winner == BoardData.Player.PLAYER_2:
		if current_mode == GameMode.PLAYER_VS_AI:
			if am: am.play_sfx("defeat")
		else:
			if am: am.play_sfx("victory")
			if hm: hm.vibrate_victory()
			
	match_ended.emit(winner, reason)
	state_changed.emit()
	
	# Show post-game interstitial ad cleanly at natural break
	var ads = get_node_or_null("/root/AdsManager")
	if ads:
		ads.show_interstitial()

func go_to_main_menu() -> void:
	is_game_active = false
	match_state = MatchState.READY
	state_changed.emit()
	get_tree().change_scene_to_file.call_deferred("res://scenes/MainMenu.tscn")
