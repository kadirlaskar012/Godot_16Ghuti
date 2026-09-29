class_name MainMenu
extends Control

## MainMenu provides a luxurious landing experience (Screen 1):
## Top Header: Avatar, Level, Coins ("3,450 +"), Gems ("120 +"), Settings.
## Royal 16 GHUTI — SHOLO GHUTI — crown plaque with breathing animation.
## 3 Game Mode cards: Play vs AI (leads to Screens 2-5 Wizard), Local 2P, Online Multiplayer.
## 5 Quick Actions: Shop, Themes, Skins, Profile, Stats.
## Season 1 Pass progress banner.

const PLAY_AI_WIZARD_SCENE = preload("res://scenes/modals/PlayVsAIWizardModal.tscn")
const SETTINGS_MODAL_SCENE = preload("res://scenes/modals/SettingsModal.tscn")
const PROFILE_MODAL_SCENE = preload("res://scenes/modals/ProfileModal.tscn")
const HOW_TO_PLAY_SCENE = preload("res://scenes/modals/HowToPlayModal.tscn")
const ONLINE_MODAL_SCENE = preload("res://scenes/modals/OnlineMultiplayerModal.tscn")
const LOCAL_PLAYER_SETUP_SCENE = preload("res://scenes/modals/LocalPlayerSetupModal.tscn")
const DEV_DEBUG_PANEL_SCENE = preload("res://scenes/debug/DevDebugPanel.tscn")
const THEME_MODAL_SCENE = preload("res://scenes/modals/ThemeModal.tscn")

const AVATAR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/avatar_warrior.png"),
	preload("res://assets/textures/avatar_king.png"),
	preload("res://assets/textures/avatar_queen.png"),
	preload("res://assets/textures/avatar_samurai.png"),
	preload("res://assets/textures/avatar_knight.png"),
	preload("res://assets/textures/avatar_prince.png"),
	preload("res://assets/textures/avatar_princess.png"),
	preload("res://assets/textures/avatar_mystic.png"),
]

# Mode Cards
@onready var play_ai_btn: Button = find_child("PlayAIButton", true, false)
@onready var play_local_btn: Button = find_child("PlayLocalButton", true, false)
@onready var play_online_btn: Button = find_child("PlayOnlineButton", true, false)

# Top Bar
@onready var profile_btn: Button = find_child("ProfileButton", true, false)
@onready var coins_btn: Button = find_child("CoinsButton", true, false)
@onready var gems_btn: Button = find_child("GemsButton", true, false)
@onready var settings_btn: Button = find_child("SettingsButton", true, false)
@onready var player_name_label: Label = find_child("NameLabel", true, false)
@onready var coins_label: Label = find_child("CoinsLabel", true, false)
@onready var avatar_rect: TextureRect = find_child("Avatar", true, false)

# Quick Action Row
@onready var shop_btn: Button = find_child("ShopButton", true, false)
@onready var theme_btn: Button = find_child("ThemeButton", true, false)
@onready var skins_btn: Button = find_child("SkinsButton", true, false)
@onready var profile_quick_btn: Button = find_child("ProfileQuickButton", true, false)
@onready var stats_btn: Button = find_child("StatsButton", true, false)

@onready var logo: TextureRect = find_child("Logo", true, false)

var _logo_idle_tween: Tween
var _play_ai_idle_tween: Tween

func _ready() -> void:
	_apply_theme()
	_update_header()
	
	var safe = SafeAreaHelper.get_safe_margins()
	var safe_area = find_child("SafeArea", true, false) as MarginContainer
	if safe_area:
		safe_area.add_theme_constant_override("margin_top", int(max(safe["top"], 48.0)))
		
	# Dev Debug Panel in debug builds
	if OS.is_debug_build():
		var dev = DEV_DEBUG_PANEL_SCENE.instantiate()
		add_child(dev)
	
	# Play vs AI (Screen 1 -> triggers Screens 2-5 Wizard)
	if play_ai_btn:
		play_ai_btn.pressed.connect(_on_play_ai_pressed)
		_setup_primary_btn(play_ai_btn)
		
	if play_local_btn:
		play_local_btn.pressed.connect(_on_play_local_pressed)
		_setup_btn(play_local_btn)
		
	if play_online_btn:
		play_online_btn.pressed.connect(_on_play_online_pressed)
		_setup_btn(play_online_btn)
		
	if profile_btn:
		profile_btn.pressed.connect(_on_profile_pressed)
		_setup_btn(profile_btn)
		
	if coins_btn:
		coins_btn.pressed.connect(_on_shop_pressed)
		_setup_btn(coins_btn)
		
	if gems_btn:
		gems_btn.pressed.connect(_on_shop_pressed)
		_setup_btn(gems_btn)
		
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
		_setup_btn(settings_btn)
		
	# Quick actions
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_pressed)
		_setup_btn(shop_btn)
		
	if theme_btn:
		theme_btn.pressed.connect(_on_theme_pressed)
		_setup_btn(theme_btn)
		
	if skins_btn:
		skins_btn.pressed.connect(_on_skins_pressed)
		_setup_btn(skins_btn)
		
	if profile_quick_btn:
		profile_quick_btn.pressed.connect(_on_profile_pressed)
		_setup_btn(profile_quick_btn)
		
	if stats_btn:
		stats_btn.pressed.connect(_on_stats_pressed)
		_setup_btn(stats_btn)
		
	# Subtle floating idle animation for royal 16 Ghuti logo
	if logo:
		var orig_y = logo.position.y
		_logo_idle_tween = create_tween().set_loops()
		_logo_idle_tween.tween_property(logo, "position:y", orig_y - 8.0, 2.2).set_trans(Tween.TRANS_SINE)
		_logo_idle_tween.tween_property(logo, "position:y", orig_y + 8.0, 2.2).set_trans(Tween.TRANS_SINE)

func _setup_primary_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	_play_ai_idle_tween = create_tween().set_loops()
	_play_ai_idle_tween.tween_property(btn, "scale", Vector2(1.025, 1.025), 1.6).set_trans(Tween.TRANS_SINE)
	_play_ai_idle_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 1.6).set_trans(Tween.TRANS_SINE)
	
	btn.button_down.connect(func():
		if _play_ai_idle_tween:
			_play_ai_idle_tween.pause()
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			if _play_ai_idle_tween:
				_play_ai_idle_tween.play()
		)
	)

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
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _update_header() -> void:
	if player_name_label and SaveManager.player_data:
		player_name_label.text = SaveManager.player_data.player_name
	if coins_label and SaveManager.player_data:
		coins_label.text = "%d +" % SaveManager.player_data.coins
	if avatar_rect and SaveManager.player_data:
		var a_idx = clampi(SaveManager.player_data.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
		avatar_rect.texture = AVATAR_TEXTURES[a_idx]

func _on_play_ai_pressed() -> void:
	AudioManager.play_sfx("click")
	# Open the 4-step Play vs AI wizard (Screens 2 -> 3 -> 4 -> 5)
	var wizard = PLAY_AI_WIZARD_SCENE.instantiate()
	add_child(wizard)

func _on_play_local_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = LOCAL_PLAYER_SETUP_SCENE.instantiate()
	add_child(modal)

func _on_play_online_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = ONLINE_MODAL_SCENE.instantiate()
	add_child(modal)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = SETTINGS_MODAL_SCENE.instantiate()
	modal.closed.connect(func():
		_update_header()
	)
	add_child(modal)

func _on_profile_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = PROFILE_MODAL_SCENE.instantiate()
	modal.profile_updated.connect(func():
		_update_header()
	)
	add_child(modal)

func _on_theme_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = THEME_MODAL_SCENE.instantiate()
	modal.theme_previewed.connect(func(theme_id: String):
		_apply_theme_id(theme_id)
	)
	modal.closed.connect(func():
		_apply_theme()
	)
	add_child(modal)

func _on_shop_pressed() -> void:
	AudioManager.play_sfx("click")
	_show_toast("Shop & Rewards Coming Soon in v1.1.0!", 1.8)

func _on_skins_pressed() -> void:
	AudioManager.play_sfx("click")
	_show_toast("Default Royal Red & Pearl White Active!", 1.8)

func _show_toast(msg: String, duration: float = 1.8) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.94)
	style.border_color = Color(1.0, 0.8, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	panel.add_child(lbl)
	
	panel.anchors_preset = Control.PRESET_CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = 180
	panel.offset_bottom = 240
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(panel)
	
	var tw = create_tween()
	tw.tween_interval(duration)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(panel.queue_free)

func _on_stats_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = PROFILE_MODAL_SCENE.instantiate()
	add_child(modal)

func _apply_theme() -> void:
	_apply_theme_id(SaveManager.settings.board_theme)

func _apply_theme_id(theme_id: String) -> void:
	var path = "res://assets/textures/tabletop_classic.jpg"
	match theme_id:
		"royal_mahogany":
			path = "res://assets/textures/tabletop_mahogany.jpg"
		"ivory_maple":
			path = "res://assets/textures/tabletop_light.jpg"
		_:
			path = "res://assets/textures/tabletop_classic.jpg"
			
	var tex = load(path)
	var bg = find_child("Background", true, false) as TextureRect
	if tex and bg:
		bg.texture = tex
