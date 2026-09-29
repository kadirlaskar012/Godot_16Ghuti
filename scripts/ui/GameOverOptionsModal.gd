class_name GameOverOptionsModal
extends CanvasLayer

## GameOverOptionsModal provides the 5 quick-access game over / pause options:
## 1. Play Again (Instant Rematch)
## 2. Change Difficulty (Easy, Medium, Hard, Expert)
## 3. Change Board Theme (Wood, Marble, Mystic, Palace, Forest)
## 4. Change Ghuti Color (Red <-> White)
## 5. Back to Home

signal play_again_pressed
signal change_difficulty_pressed(diff: int)
signal change_theme_pressed(theme_id: String)
signal change_ghuti_color_pressed(color: int)
signal back_to_home_pressed
signal closed

@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var play_again_btn: Button = find_child("PlayAgainBtn", true, false)
@onready var diff_btn: Button = find_child("DiffBtn", true, false)
@onready var theme_btn: Button = find_child("ThemeBtn", true, false)
@onready var ghuti_btn: Button = find_child("GhutiBtn", true, false)
@onready var home_btn: Button = find_child("HomeBtn", true, false)

@onready var diff_subpanel: Control = find_child("DiffSubpanel", true, false)
@onready var theme_subpanel: Control = find_child("ThemeSubpanel", true, false)

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func():
			closed.emit()
			queue_free()
		)
		_setup_btn(close_btn)
		
	if play_again_btn:
		play_again_btn.pressed.connect(func():
			play_again_pressed.emit()
			queue_free()
		)
		_setup_btn(play_again_btn)
		
	if diff_btn:
		diff_btn.pressed.connect(_toggle_diff_subpanel)
		_setup_btn(diff_btn)
		
	if theme_btn:
		theme_btn.pressed.connect(_toggle_theme_subpanel)
		_setup_btn(theme_btn)
		
	if ghuti_btn:
		ghuti_btn.pressed.connect(_on_ghuti_toggle_pressed)
		_setup_btn(ghuti_btn)
		
	if home_btn:
		home_btn.pressed.connect(func():
			back_to_home_pressed.emit()
			queue_free()
		)
		_setup_btn(home_btn)
		
	_setup_subpanel_buttons()
	_update_labels()

func _setup_btn(btn: Button) -> void:
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

func _update_labels() -> void:
	if diff_btn:
		var d_str = "Medium"
		if GameManager.current_difficulty == AIManager.Difficulty.EASY: d_str = "Easy"
		elif GameManager.current_difficulty == AIManager.Difficulty.HARD: d_str = "Hard"
		elif GameManager.current_difficulty == AIManager.Difficulty.EXPERT: d_str = "Expert"
		diff_btn.text = "⚡ DIFFICULTY: %s ❯" % d_str
		
	if theme_btn:
		var t_str = GameManager.current_theme.replace("_", " ").capitalize()
		theme_btn.text = "🎨 THEME: %s ❯" % t_str
		
	if ghuti_btn:
		var c_str = "RED" if GameManager.player_ghuti_color == BoardData.Player.PLAYER_1 else "WHITE"
		ghuti_btn.text = "⚪ GHUTI COLOR: %s (Tap to switch)" % c_str

func _toggle_diff_subpanel() -> void:
	if diff_subpanel:
		diff_subpanel.visible = not diff_subpanel.visible
		if theme_subpanel: theme_subpanel.visible = false

func _toggle_theme_subpanel() -> void:
	if theme_subpanel:
		theme_subpanel.visible = not theme_subpanel.visible
		if diff_subpanel: diff_subpanel.visible = false

func _on_ghuti_toggle_pressed() -> void:
	var new_color = BoardData.Player.PLAYER_2 if GameManager.player_ghuti_color == BoardData.Player.PLAYER_1 else BoardData.Player.PLAYER_1
	GameManager.player_ghuti_color = new_color
	_update_labels()
	change_ghuti_color_pressed.emit(new_color)

func _setup_subpanel_buttons() -> void:
	var sub_easy = find_child("SubDiffEasy", true, false) as Button
	var sub_med = find_child("SubDiffMed", true, false) as Button
	var sub_hard = find_child("SubDiffHard", true, false) as Button
	var sub_exp = find_child("SubDiffExpert", true, false) as Button
	
	if sub_easy:
		sub_easy.pressed.connect(func(): _set_difficulty(AIManager.Difficulty.EASY))
		_setup_btn(sub_easy)
	if sub_med:
		sub_med.pressed.connect(func(): _set_difficulty(AIManager.Difficulty.MEDIUM))
		_setup_btn(sub_med)
	if sub_hard:
		sub_hard.pressed.connect(func(): _set_difficulty(AIManager.Difficulty.HARD))
		_setup_btn(sub_hard)
	if sub_exp:
		sub_exp.pressed.connect(func(): _set_difficulty(AIManager.Difficulty.EXPERT))
		_setup_btn(sub_exp)
		
	var sub_wood = find_child("SubThemeWood", true, false) as Button
	var sub_marble = find_child("SubThemeMarble", true, false) as Button
	var sub_mystic = find_child("SubThemeMystic", true, false) as Button
	var sub_palace = find_child("SubThemePalace", true, false) as Button
	var sub_forest = find_child("SubThemeForest", true, false) as Button
	
	if sub_wood:
		sub_wood.pressed.connect(func(): _set_theme("classic_wood"))
		_setup_btn(sub_wood)
	if sub_marble:
		sub_marble.pressed.connect(func(): _set_theme("royal_marble"))
		_setup_btn(sub_marble)
	if sub_mystic:
		sub_mystic.pressed.connect(func(): _set_theme("dark_mystic"))
		_setup_btn(sub_mystic)
	if sub_palace:
		sub_palace.pressed.connect(func(): _set_theme("golden_palace"))
		_setup_btn(sub_palace)
	if sub_forest:
		sub_forest.pressed.connect(func(): _set_theme("green_forest"))
		_setup_btn(sub_forest)

func _set_difficulty(d: int) -> void:
	GameManager.current_difficulty = d
	SaveManager.settings.ai_difficulty = d
	SaveManager.save_settings()
	if diff_subpanel: diff_subpanel.visible = false
	_update_labels()
	change_difficulty_pressed.emit(d)

func _set_theme(t: String) -> void:
	GameManager.current_theme = t
	SaveManager.settings.board_theme = t
	SaveManager.save_settings()
	if theme_subpanel: theme_subpanel.visible = false
	_update_labels()
	change_theme_pressed.emit(t)
