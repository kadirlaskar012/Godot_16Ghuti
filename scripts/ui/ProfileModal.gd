class_name ProfileModal
extends CanvasLayer

## Full-screen Luxurious Player Profile & Gaming Identity Screen
## Features 8 Original Game Avatars, Hero Section, Level/XP Card, Wallet,
## Hierarchical Stats with Circular Win Rate Ring, Large Cosmetic Cards,
## Achievements, and Recent Matches.

signal closed

const EDIT_PROFILE_SCENE = preload("res://scenes/modals/EditProfileModal.tscn")

const AVATAR_TEXTURES = [
	preload("res://assets/textures/avatar_warrior.png"),
	preload("res://assets/textures/avatar_king.png"),
	preload("res://assets/textures/avatar_queen.png"),
	preload("res://assets/textures/avatar_samurai.png"),
	preload("res://assets/textures/avatar_knight.png"),
	preload("res://assets/textures/avatar_prince.png"),
	preload("res://assets/textures/avatar_princess.png"),
	preload("res://assets/textures/avatar_mystic.png")
]

# Fixed Top Bar
@onready var back_btn: Button = find_child("BackButton", true, false)

# Profile Hero
@onready var avatar_btn: Button = find_child("AvatarButton", true, false)
@onready var avatar_img: TextureRect = find_child("AvatarImage", true, false)
@onready var name_label: Label = find_child("PlayerNameLabel", true, false)
@onready var edit_name_btn: Button = find_child("EditNameButton", true, false)
@onready var player_id_label: Label = find_child("PlayerIdLabel", true, false)
@onready var hero_level_subtitle: Label = find_child("HeroLevelSubtitle", true, false)

# Level Card
@onready var level_label: Label = find_child("LevelLabel", true, false)
@onready var xp_label: Label = find_child("XpLabel", true, false)
@onready var xp_bar: ProgressBar = find_child("XpProgressBar", true, false)
@onready var xp_to_next_label: Label = find_child("XpToNextLabel", true, false)

# Wallet
@onready var coins_label: Label = find_child("CoinsLabel", true, false)
@onready var shop_btn: Button = find_child("ShopButton", true, false)

# Key Statistics (Dominant)
@onready var games_played_label: Label = find_child("GamesPlayedLabel", true, false)
@onready var wins_label: Label = find_child("WinsLabel", true, false)
@onready var circular_win_rate: CircularProgress = find_child("CircularWinRate", true, false)
@onready var win_rate_percent_label: Label = find_child("WinRatePercentLabel", true, false)

# Secondary Statistics
@onready var losses_label: Label = find_child("LossesLabel", true, false)
@onready var draws_label: Label = find_child("DrawsLabel", true, false)
@onready var captures_label: Label = find_child("CapturesLabel", true, false)
@onready var streak_label: Label = find_child("BestStreakLabel", true, false)
@onready var play_time_label: Label = find_child("PlayTimeLabel", true, false)

# My Style
@onready var style_guti_label: Label = find_child("StyleGutiLabel", true, false)
@onready var style_board_label: Label = find_child("StyleBoardLabel", true, false)
@onready var style_victory_label: Label = find_child("StyleVictoryLabel", true, false)

# Lists
@onready var achievements_container: VBoxContainer = find_child("AchievementsContainer", true, false)
@onready var recent_matches_container: VBoxContainer = find_child("RecentMatchesContainer", true, false)

@onready var main_panel: PanelContainer = find_child("MainPanel", true, false)

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		_setup_btn(back_btn)
	if avatar_btn:
		avatar_btn.pressed.connect(_on_avatar_tapped)
		_setup_btn(avatar_btn)
	if edit_name_btn:
		edit_name_btn.pressed.connect(_on_avatar_tapped)
		_setup_btn(edit_name_btn)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_pressed)
		_setup_btn(shop_btn)
		
	var safe = SafeAreaHelper.get_safe_margins()
	var mm = find_child("MainMargin", true, false) as MarginContainer
	if mm:
		mm.add_theme_constant_override("margin_top", int(max(safe["top"], 40.0)))
		mm.add_theme_constant_override("margin_bottom", int(max(safe["bottom"], 24.0)))
		
	_populate_all_data()
	_animate_entrance()

func _setup_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _animate_entrance() -> void:
	if main_panel:
		main_panel.position.y += 35.0
		main_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(main_panel, "position:y", main_panel.position.y - 35.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(main_panel, "modulate:a", 1.0, 0.20)
		
	if avatar_img:
		avatar_img.scale = Vector2(0.85, 0.85)
		avatar_img.pivot_offset = avatar_img.custom_minimum_size / 2.0
		var tw_av = create_tween()
		tw_av.tween_property(avatar_img, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _populate_all_data() -> void:
	var p = SaveManager.player_data
	
	# 1. Profile Hero Section
	if name_label:
		name_label.text = p.player_name
	if player_id_label:
		player_id_label.text = "PLAYER ID: %s" % p.player_id
	if avatar_img:
		var a_idx = clampi(p.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
		avatar_img.texture = AVATAR_TEXTURES[a_idx]
		
	# 2. Level & XP Info
	var lvl_info = PlayerData.get_level_info(p.xp)
	if hero_level_subtitle:
		hero_level_subtitle.text = "LEVEL %d • %d XP" % [lvl_info["level"], p.xp]
		
	if level_label:
		level_label.text = "LEVEL %d" % lvl_info["level"]
	if xp_label:
		xp_label.text = "%d / %d XP" % [lvl_info["current_xp"], lvl_info["max_xp"]]
	if xp_to_next_label:
		xp_to_next_label.text = "%d XP TO LEVEL %d" % [lvl_info["xp_to_next"], lvl_info["level"] + 1]
	if xp_bar:
		xp_bar.max_value = lvl_info["max_xp"]
		var tw_xp = create_tween()
		tw_xp.tween_property(xp_bar, "value", float(lvl_info["current_xp"]), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# 3. Coins / Wallet
	if coins_label:
		coins_label.text = "%d" % p.coins
		
	# 4. Key Dominant Statistics
	if games_played_label:
		games_played_label.text = str(p.games_played)
	if wins_label:
		wins_label.text = str(p.games_won)
		
	# 5. Circular Win Rate
	var win_rate = p.get_win_rate()
	if win_rate_percent_label:
		win_rate_percent_label.text = "%.1f%%" % win_rate
	if circular_win_rate:
		var tw_c = create_tween()
		tw_c.tween_property(circular_win_rate, "value", win_rate, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# 6. Secondary Statistics
	if losses_label:
		losses_label.text = str(p.games_lost)
	if draws_label:
		draws_label.text = str(p.games_draw)
	if captures_label:
		captures_label.text = str(p.total_captures)
	if streak_label:
		streak_label.text = str(p.best_win_streak)
	if play_time_label:
		var hrs = int(p.total_play_time_seconds) / 3600
		var mins = (int(p.total_play_time_seconds) % 3600) / 60
		if hrs > 0:
			play_time_label.text = "%dh %dm" % [hrs, mins]
		else:
			play_time_label.text = "%dm" % mins
		
	# 7. My Style / Customization
	if style_guti_label:
		style_guti_label.text = p.equipped_guti
	if style_board_label:
		var b_theme = SaveManager.settings.board_theme
		var b_name = "Classic Dark Walnut"
		if b_theme == "royal_mahogany":
			b_name = "Royal Mahogany"
		elif b_theme == "ivory_maple":
			b_name = "Ivory Maple (Light Mode)"
		style_board_label.text = b_name
	if style_victory_label:
		style_victory_label.text = p.equipped_victory
		
	# 8. Achievements List
	_populate_achievements(p)
	
	# 9. Recent Matches List
	_populate_recent_matches(p)

func _populate_achievements(p: PlayerData) -> void:
	if not achievements_container:
		return
	for c in achievements_container.get_children():
		c.queue_free()
		
	var defs = [
		{"id": "FIRST_WIN", "title": "First Victory", "desc": "Win your first match", "current": p.games_won, "target": 1},
		{"id": "TEN_WINS", "title": "Rising Champion", "desc": "Win 10 matches", "current": p.games_won, "target": 10},
		{"id": "MASTER_CAPTURE", "title": "Master Capture", "desc": "Capture 50 pieces", "current": p.total_captures, "target": 50},
		{"id": "WIN_STREAK", "title": "Unstoppable", "desc": "Win 5 matches consecutively", "current": p.best_win_streak, "target": 5},
		{"id": "VETERAN", "title": "16 Guti Veteran", "desc": "Play 100 matches", "current": p.games_played, "target": 100},
	]
	
	for ach in defs:
		var is_unlocked = ach["current"] >= ach["target"]
		var card = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(16)
		if is_unlocked:
			sb.bg_color = Color(0.20, 0.14, 0.06, 0.92)
			sb.border_color = Color(0.95, 0.82, 0.38, 0.95)
			sb.set_border_width_all(2)
			sb.shadow_size = 6
			sb.shadow_color = Color(0.9, 0.7, 0.2, 0.25)
		else:
			sb.bg_color = Color(0.12, 0.08, 0.04, 0.85)
			sb.border_color = Color(0.55, 0.42, 0.25, 0.4)
			sb.set_border_width_all(1)
		card.add_theme_stylebox_override("panel", sb)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 18)
		margin.add_child(hbox)
		
		# Star Icon
		var icon_lbl = Label.new()
		icon_lbl.text = "★" if is_unlocked else "☆"
		icon_lbl.add_theme_font_size_override("font_size", 32)
		icon_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35) if is_unlocked else Color(0.55, 0.45, 0.35))
		hbox.add_child(icon_lbl)
		
		# Details VBox
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)
		
		var title_lbl = Label.new()
		title_lbl.text = ach["title"]
		title_lbl.add_theme_font_size_override("font_size", 26)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65) if is_unlocked else Color(0.78, 0.70, 0.60))
		vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = ach["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 22)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.68) if is_unlocked else Color(0.55, 0.50, 0.42))
		vbox.add_child(desc_lbl)
		
		# Status badge or progress
		var status_panel = PanelContainer.new()
		var status_sb = StyleBoxFlat.new()
		status_sb.set_corner_radius_all(10)
		status_sb.content_margin_left = 16
		status_sb.content_margin_right = 16
		status_sb.content_margin_top = 6
		status_sb.content_margin_bottom = 6
		
		var status_lbl = Label.new()
		status_lbl.add_theme_font_size_override("font_size", 22)
		
		if is_unlocked:
			status_sb.bg_color = Color(0.35, 0.25, 0.08, 0.95)
			status_sb.border_color = Color(1.0, 0.88, 0.40, 0.9)
			status_sb.set_border_width_all(1)
			status_lbl.text = "UNLOCKED"
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		else:
			status_sb.bg_color = Color(0.18, 0.12, 0.07, 0.85)
			status_sb.border_color = Color(0.60, 0.45, 0.25, 0.5)
			status_sb.set_border_width_all(1)
			status_lbl.text = "%d / %d" % [mini(ach["current"], ach["target"]), ach["target"]]
			status_lbl.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
			
		status_panel.add_theme_stylebox_override("panel", status_sb)
		status_panel.add_child(status_lbl)
		hbox.add_child(status_panel)
		
		achievements_container.add_child(card)

func _populate_recent_matches(p: PlayerData) -> void:
	if not recent_matches_container:
		return
	for c in recent_matches_container.get_children():
		c.queue_free()
		
	if p.recent_matches.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "NO MATCHES YET"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 26)
		empty_lbl.add_theme_color_override("font_color", Color(0.70, 0.62, 0.52, 0.8))
		recent_matches_container.add_child(empty_lbl)
		return
		
	for m in p.recent_matches:
		var row = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		sb.bg_color = Color(0.13, 0.085, 0.045, 0.90)
		sb.border_color = Color(0.65, 0.50, 0.28, 0.5)
		sb.set_border_width_all(1)
		row.add_theme_stylebox_override("panel", sb)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 18)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		row.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		margin.add_child(hbox)
		
		# Left: Opponent & Mode
		var left_vbox = VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(left_vbox)
		
		var opp_lbl = Label.new()
		opp_lbl.text = m.get("opponent", "Opponent")
		opp_lbl.add_theme_font_size_override("font_size", 26)
		opp_lbl.add_theme_color_override("font_color", Color(0.96, 0.90, 0.80))
		left_vbox.add_child(opp_lbl)
		
		var mode_lbl = Label.new()
		mode_lbl.text = "%s • %s" % [m.get("mode", "Match"), m.get("date", "Today")]
		mode_lbl.add_theme_font_size_override("font_size", 22)
		mode_lbl.add_theme_color_override("font_color", Color(0.70, 0.62, 0.52))
		left_vbox.add_child(mode_lbl)
		
		# Duration
		var dur_lbl = Label.new()
		dur_lbl.text = m.get("duration", "00:00")
		dur_lbl.add_theme_font_size_override("font_size", 22)
		dur_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
		dur_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(dur_lbl)
		
		# Result Badge
		var res_str = m.get("result", "WIN")
		var badge = PanelContainer.new()
		var badge_sb = StyleBoxFlat.new()
		badge_sb.set_corner_radius_all(10)
		badge_sb.content_margin_left = 18
		badge_sb.content_margin_right = 18
		badge_sb.content_margin_top = 6
		badge_sb.content_margin_bottom = 6
		
		var badge_lbl = Label.new()
		badge_lbl.text = res_str
		badge_lbl.add_theme_font_size_override("font_size", 22)
		
		if res_str == "WIN":
			badge_sb.bg_color = Color(0.18, 0.42, 0.18, 0.9)
			badge_sb.border_color = Color(0.5, 0.9, 0.45, 0.9)
			badge_sb.set_border_width_all(1)
			badge_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.8))
		elif res_str == "LOSS":
			badge_sb.bg_color = Color(0.45, 0.15, 0.12, 0.9)
			badge_sb.border_color = Color(0.9, 0.4, 0.35, 0.9)
			badge_sb.set_border_width_all(1)
			badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.8))
		else: # DRAW
			badge_sb.bg_color = Color(0.35, 0.28, 0.15, 0.9)
			badge_sb.border_color = Color(0.85, 0.75, 0.45, 0.9)
			badge_sb.set_border_width_all(1)
			badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
			
		badge.add_theme_stylebox_override("panel", badge_sb)
		badge.add_child(badge_lbl)
		hbox.add_child(badge)
		
		recent_matches_container.add_child(row)

func _on_avatar_tapped() -> void:
	AudioManager.play_sfx("click")
	var modal = EDIT_PROFILE_SCENE.instantiate()
	modal.saved.connect(func():
		_populate_all_data()
	)
	add_child(modal)

func _on_shop_pressed() -> void:
	AudioManager.play_sfx("click")
	_show_toast("Shop system will open with new skins and boards in the next update!")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.save_data()
	closed.emit()
	
	if main_panel:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(main_panel, "position:y", main_panel.position.y + 35.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(main_panel, "modulate:a", 0.0, 0.14)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()

func _show_toast(message: String) -> void:
	for c in get_children():
		if c.name == "ProfileToast":
			c.queue_free()
			
	var toast = Label.new()
	toast.text = message
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 22)
	toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	
	var panel = PanelContainer.new()
	panel.name = "ProfileToast"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.04, 0.95)
	sb.border_color = Color(0.85, 0.70, 0.35, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_child(toast)
	
	add_child(panel)
	panel.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.18)
	t.tween_interval(2.0)
	t.tween_property(panel, "modulate:a", 0.0, 0.30)
	t.tween_callback(panel.queue_free)
