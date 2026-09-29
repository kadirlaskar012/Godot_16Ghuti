class_name PlayVsAIWizardModal
extends CanvasLayer

## PlayVsAIWizardModal manages the complete 4-step pre-game wizard:
## Screen 2: Select Difficulty (Easy, Medium, Hard, Expert + 3D Robot Mascot)
## Screen 3: Choose Your Ghuti (Red vs White with 3D stacked piece trays)
## Screen 4: Select Board Theme (Classic Wood + Royal Marble, Dark Mystic, Golden Palace, Green Forest)
## Screen 5: VS Matchup Start Screen (Player vs Robot AI, pulsing VS emblem, countdown)

signal wizard_completed
signal wizard_cancelled

@onready var step1_container: Control = find_child("Step1_Difficulty", true, false)
@onready var step2_container: Control = find_child("Step2_GhutiColor", true, false)
@onready var step3_container: Control = find_child("Step3_BoardTheme", true, false)
@onready var step4_container: Control = find_child("Step4_VSScreen", true, false)

@onready var back_button: Button = find_child("WizardBackButton", true, false)
@onready var step_title_label: Label = find_child("StepTitleLabel", true, false)

# Step 1 Nodes
@onready var diff_easy_btn: Button = find_child("DiffEasyBtn", true, false)
@onready var diff_med_btn: Button = find_child("DiffMedBtn", true, false)
@onready var diff_hard_btn: Button = find_child("DiffHardBtn", true, false)
@onready var diff_expert_btn: Button = find_child("DiffExpertBtn", true, false)
@onready var step1_next_btn: Button = find_child("Step1NextBtn", true, false)

# Step 2 Nodes
@onready var ghuti_red_btn: Button = find_child("GhutiRedBtn", true, false)
@onready var ghuti_white_btn: Button = find_child("GhutiWhiteBtn", true, false)
@onready var step2_next_btn: Button = find_child("Step2NextBtn", true, false)

# Step 3 Nodes
@onready var theme_classic_btn: Button = find_child("ThemeClassicBtn", true, false)
@onready var theme_marble_btn: Button = find_child("ThemeMarbleBtn", true, false)
@onready var theme_mystic_btn: Button = find_child("ThemeMysticBtn", true, false)
@onready var theme_palace_btn: Button = find_child("ThemePalaceBtn", true, false)
@onready var theme_forest_btn: Button = find_child("ThemeForestBtn", true, false)
@onready var step3_next_btn: Button = find_child("Step3NextBtn", true, false)

# Step 4 Nodes
@onready var vs_player_name: Label = find_child("VSPlayerName", true, false)
@onready var vs_player_avatar: TextureRect = find_child("VSPlayerAvatar", true, false)
@onready var vs_player_ghuti_dot: ColorRect = find_child("VSPlayerGhutiDot", true, false)
@onready var vs_ai_diff_label: Label = find_child("VSAIDiffLabel", true, false)
@onready var vs_ai_ghuti_dot: ColorRect = find_child("VSAIGhutiDot", true, false)
@onready var vs_emblem: Label = find_child("VSEmblem", true, false)
@onready var vs_countdown_label: Label = find_child("VSCountdownLabel", true, false)
@onready var vs_start_now_btn: Button = find_child("VSStartNowBtn", true, false)

var current_step: int = 1 # 1: Difficulty, 2: Ghuti Color, 3: Theme, 4: VS Screen

var selected_difficulty: int = AIManager.Difficulty.MEDIUM
var selected_ghuti_color: int = BoardData.Player.PLAYER_1 # PLAYER_1 = Red, PLAYER_2 = White
var selected_theme: String = "classic_wood"

var _vs_countdown_tween: Tween

func _ready() -> void:
	# Initialize defaults from SaveManager if present
	if SaveManager.settings:
		selected_difficulty = clampi(SaveManager.settings.ai_difficulty, 0, 3)
		selected_theme = SaveManager.settings.board_theme
		if selected_theme.is_empty():
			selected_theme = "classic_wood"
			
	_setup_buttons()
	_refresh_step_display()
	_update_diff_selection_visuals()
	_update_ghuti_selection_visuals()
	_update_theme_selection_visuals()

func _setup_buttons() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		_add_btn_fx(back_button)
		
	# Step 1
	if diff_easy_btn:
		diff_easy_btn.pressed.connect(func(): _select_difficulty(AIManager.Difficulty.EASY))
		_add_btn_fx(diff_easy_btn)
	if diff_med_btn:
		diff_med_btn.pressed.connect(func(): _select_difficulty(AIManager.Difficulty.MEDIUM))
		_add_btn_fx(diff_med_btn)
	if diff_hard_btn:
		diff_hard_btn.pressed.connect(func(): _select_difficulty(AIManager.Difficulty.HARD))
		_add_btn_fx(diff_hard_btn)
	if diff_expert_btn:
		diff_expert_btn.pressed.connect(func(): _select_difficulty(AIManager.Difficulty.EXPERT))
		_add_btn_fx(diff_expert_btn)
	if step1_next_btn:
		step1_next_btn.pressed.connect(func(): _go_to_step(2))
		_add_btn_fx(step1_next_btn)
		
	# Step 2
	if ghuti_red_btn:
		ghuti_red_btn.pressed.connect(func(): _select_ghuti_color(BoardData.Player.PLAYER_1))
		_add_btn_fx(ghuti_red_btn)
	if ghuti_white_btn:
		ghuti_white_btn.pressed.connect(func(): _select_ghuti_color(BoardData.Player.PLAYER_2))
		_add_btn_fx(ghuti_white_btn)
	if step2_next_btn:
		step2_next_btn.pressed.connect(func(): _go_to_step(3))
		_add_btn_fx(step2_next_btn)
		
	# Step 3
	if theme_classic_btn:
		theme_classic_btn.pressed.connect(func(): _select_theme("classic_wood"))
		_add_btn_fx(theme_classic_btn)
	if theme_marble_btn:
		theme_marble_btn.pressed.connect(func(): _select_theme("royal_marble"))
		_add_btn_fx(theme_marble_btn)
	if theme_mystic_btn:
		theme_mystic_btn.pressed.connect(func(): _select_theme("dark_mystic"))
		_add_btn_fx(theme_mystic_btn)
	if theme_palace_btn:
		theme_palace_btn.pressed.connect(func(): _select_theme("golden_palace"))
		_add_btn_fx(theme_palace_btn)
	if theme_forest_btn:
		theme_forest_btn.pressed.connect(func(): _select_theme("green_forest"))
		_add_btn_fx(theme_forest_btn)
	if step3_next_btn:
		step3_next_btn.pressed.connect(func(): _go_to_step(4))
		_add_btn_fx(step3_next_btn)
		
	# Step 4
	if vs_start_now_btn:
		vs_start_now_btn.pressed.connect(_launch_match_now)
		_add_btn_fx(vs_start_now_btn)

func _add_btn_fx(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
	)

func _on_back_pressed() -> void:
	if current_step > 1:
		_go_to_step(current_step - 1)
	else:
		wizard_cancelled.emit()
		queue_free()

func _go_to_step(step: int) -> void:
	current_step = step
	_refresh_step_display()
	if current_step == 4:
		_init_vs_screen()

func _refresh_step_display() -> void:
	if step1_container: step1_container.visible = (current_step == 1)
	if step2_container: step2_container.visible = (current_step == 2)
	if step3_container: step3_container.visible = (current_step == 3)
	if step4_container: step4_container.visible = (current_step == 4)
	
	if step_title_label:
		match current_step:
			1: step_title_label.text = "SELECT DIFFICULTY"
			2: step_title_label.text = "CHOOSE YOUR GHUTI"
			3: step_title_label.text = "SELECT BOARD THEME"
			4: step_title_label.text = "PLAYING VS AI"

func _select_difficulty(diff: int) -> void:
	selected_difficulty = diff
	SaveManager.settings.ai_difficulty = diff
	SaveManager.save_settings()
	_update_diff_selection_visuals()

func _update_diff_selection_visuals() -> void:
	var btns = [diff_easy_btn, diff_med_btn, diff_hard_btn, diff_expert_btn]
	for i in range(btns.size()):
		var b = btns[i]
		if b:
			var is_sel = (i == selected_difficulty)
			b.modulate = Color(1.15, 1.1, 0.9) if is_sel else Color(0.8, 0.8, 0.8)
			var badge = b.find_child("SelectedBadge", true, false)
			if badge:
				badge.visible = is_sel

func _select_ghuti_color(col: int) -> void:
	selected_ghuti_color = col
	_update_ghuti_selection_visuals()

func _update_ghuti_selection_visuals() -> void:
	if ghuti_red_btn:
		var is_red = (selected_ghuti_color == BoardData.Player.PLAYER_1)
		ghuti_red_btn.modulate = Color(1.2, 1.15, 1.0) if is_red else Color(0.75, 0.75, 0.75)
		var badge_red = ghuti_red_btn.find_child("SelectedBadge", true, false)
		if badge_red: badge_red.visible = is_red
		
	if ghuti_white_btn:
		var is_white = (selected_ghuti_color == BoardData.Player.PLAYER_2)
		ghuti_white_btn.modulate = Color(1.2, 1.15, 1.0) if is_white else Color(0.75, 0.75, 0.75)
		var badge_white = ghuti_white_btn.find_child("SelectedBadge", true, false)
		if badge_white: badge_white.visible = is_white

func _select_theme(theme_id: String) -> void:
	selected_theme = theme_id
	SaveManager.settings.board_theme = theme_id
	SaveManager.save_settings()
	_update_theme_selection_visuals()

func _update_theme_selection_visuals() -> void:
	var theme_map = {
		"classic_wood": theme_classic_btn,
		"royal_marble": theme_marble_btn,
		"dark_mystic": theme_mystic_btn,
		"golden_palace": theme_palace_btn,
		"green_forest": theme_forest_btn
	}
	for tid in theme_map.keys():
		var btn = theme_map[tid]
		if btn:
			var is_sel = (tid == selected_theme)
			btn.modulate = Color(1.15, 1.1, 0.95) if is_sel else Color(0.75, 0.75, 0.75)
			var badge = btn.find_child("SelectedBadge", true, false)
			if badge: badge.visible = is_sel

func _init_vs_screen() -> void:
	if vs_player_name and SaveManager.player_data:
		vs_player_name.text = SaveManager.player_data.player_name
		
	if vs_player_avatar and SaveManager.player_data:
		var a_idx = clampi(SaveManager.player_data.avatar_index, 0, MainMenu.AVATAR_TEXTURES.size() - 1)
		vs_player_avatar.texture = MainMenu.AVATAR_TEXTURES[a_idx]
		
	var is_p1_red = (selected_ghuti_color == BoardData.Player.PLAYER_1)
	if vs_player_ghuti_dot:
		vs_player_ghuti_dot.color = Color(0.95, 0.25, 0.25) if is_p1_red else Color(0.96, 0.94, 0.88)
	if vs_ai_ghuti_dot:
		vs_ai_ghuti_dot.color = Color(0.96, 0.94, 0.88) if is_p1_red else Color(0.95, 0.25, 0.25)
		
	if vs_ai_diff_label:
		var diff_str = "EASY"
		if selected_difficulty == AIManager.Difficulty.MEDIUM:
			diff_str = "MEDIUM"
		elif selected_difficulty == AIManager.Difficulty.HARD:
			diff_str = "HARD"
		elif selected_difficulty == AIManager.Difficulty.EXPERT:
			diff_str = "EXPERT"
		vs_ai_diff_label.text = "DIFFICULTY: %s" % diff_str
		
	# Pulsing VS animation
	if vs_emblem:
		vs_emblem.pivot_offset = vs_emblem.size / 2.0
		var tw = create_tween().set_loops()
		tw.tween_property(vs_emblem, "scale", Vector2(1.18, 1.18), 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(vs_emblem, "scale", Vector2(1.0, 1.0), 0.7).set_trans(Tween.TRANS_SINE)
		
	# 3-second animated countdown
	_start_countdown()

func _start_countdown() -> void:
	if _vs_countdown_tween:
		_vs_countdown_tween.kill()
		
	_vs_countdown_tween = create_tween()
	if vs_countdown_label:
		vs_countdown_label.text = "Game starting in 3..."
	
	_vs_countdown_tween.tween_interval(1.0)
	_vs_countdown_tween.tween_callback(func():
		if vs_countdown_label: vs_countdown_label.text = "Game starting in 2..."
		AudioManager.play_sfx("click")
	)
	_vs_countdown_tween.tween_interval(1.0)
	_vs_countdown_tween.tween_callback(func():
		if vs_countdown_label: vs_countdown_label.text = "Game starting in 1..."
		AudioManager.play_sfx("click")
	)
	_vs_countdown_tween.tween_interval(0.8)
	_vs_countdown_tween.tween_callback(func():
		_launch_match_now()
	)

func _launch_match_now() -> void:
	if _vs_countdown_tween:
		_vs_countdown_tween.kill()
	wizard_completed.emit()
	queue_free()
	GameManager.start_match(GameManager.GameMode.PLAYER_VS_AI, selected_difficulty, selected_theme, selected_ghuti_color)
