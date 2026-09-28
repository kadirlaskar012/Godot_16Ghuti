class_name MainMenu
extends Control

## MainMenu provides a luxurious landing experience with animated logo plaque,
## prominent Play VS AI button, consistent secondary modes, and compact header.

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

@onready var play_ai_btn: Button = find_child("PlayAIButton", true, false)
@onready var play_local_btn: Button = find_child("PlayLocalButton", true, false)
@onready var play_online_btn: Button = find_child("PlayOnlineButton", true, false)
@onready var rules_btn: Button = find_child("RulesButton", true, false)
@onready var settings_btn: Button = find_child("SettingsButton", true, false)
@onready var theme_btn: Button = find_child("ThemeButton", true, false)
@onready var profile_btn: Button = find_child("ProfileButton", true, false)
@onready var coins_btn: Button = find_child("CoinsButton", true, false)
@onready var player_name_label: Label = find_child("NameLabel", true, false)
@onready var coins_label: Label = find_child("CoinsLabel", true, false)
@onready var avatar_rect: TextureRect = find_child("Avatar", true, false)
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
	# Add Dev Debug Panel in debug builds
	if OS.is_debug_build():
		var dev = DEV_DEBUG_PANEL_SCENE.instantiate()
		add_child(dev)
	
	if play_ai_btn:
		play_ai_btn.pressed.connect(_on_play_ai_pressed)
		_setup_primary_btn(play_ai_btn)
		
	if play_local_btn:
		play_local_btn.pressed.connect(_on_play_local_pressed)
		_setup_btn(play_local_btn)
		
	if play_online_btn:
		play_online_btn.pressed.connect(_on_play_online_pressed)
		_setup_btn(play_online_btn)
		
	if rules_btn:
		rules_btn.pressed.connect(_on_rules_pressed)
		_setup_btn(rules_btn)
		
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
		_setup_btn(settings_btn)
		
	if theme_btn:
		theme_btn.pressed.connect(_on_theme_pressed)
		_setup_btn(theme_btn)
		
	if profile_btn:
		profile_btn.pressed.connect(_on_profile_pressed)
		_setup_btn(profile_btn)
		
	if coins_btn:
		coins_btn.pressed.connect(_on_coins_pressed)
		_setup_btn(coins_btn)
	
	# Idle logo floating breathing effect
	if logo:
		var orig_y = logo.position.y
		_logo_idle_tween = create_tween().set_loops()
		_logo_idle_tween.tween_property(logo, "position:y", orig_y - 8.0, 2.2).set_trans(Tween.TRANS_SINE)
		_logo_idle_tween.tween_property(logo, "position:y", orig_y + 8.0, 2.2).set_trans(Tween.TRANS_SINE)

func _setup_primary_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	# Gentle idle breathing pulse
	_play_ai_idle_tween = create_tween().set_loops()
	_play_ai_idle_tween.tween_property(btn, "scale", Vector2(1.02, 1.02), 1.6).set_trans(Tween.TRANS_SINE)
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
	if player_name_label:
		player_name_label.text = SaveManager.player_data.player_name
	if coins_label:
		coins_label.text = "%d" % SaveManager.player_data.coins
	if avatar_rect:
		var a_idx = clampi(SaveManager.player_data.avatar_index, 0, AVATAR_TEXTURES.size() - 1)
		avatar_rect.texture = AVATAR_TEXTURES[a_idx]

func _on_play_ai_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.start_match(GameManager.GameMode.PLAYER_VS_AI, SaveManager.settings.ai_difficulty)

func _on_play_local_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = LOCAL_PLAYER_SETUP_SCENE.instantiate()
	add_child(modal)

func _on_play_online_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = ONLINE_MODAL_SCENE.instantiate()
	add_child(modal)

func _on_rules_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = HOW_TO_PLAY_SCENE.instantiate()
	add_child(modal)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = SETTINGS_MODAL_SCENE.instantiate()
	modal.closed.connect(func():
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
		
	var spot = find_child("WarmSpotlight", true, false) as TextureRect
	var vig = find_child("Vignette", true, false) as TextureRect
	if theme_id == "ivory_maple":
		if spot: spot.modulate = Color(1.0, 0.96, 0.90, 0.15)
		if vig: vig.modulate.a = 0.18
	elif theme_id == "royal_mahogany":
		if spot: spot.modulate = Color(1.0, 0.65, 0.50, 0.40)
		if vig: vig.modulate = Color(0.25, 0.03, 0.03, 0.50)
	else:
		if spot: spot.modulate = Color(1.0, 0.85, 0.6, 0.35)
		if vig: vig.modulate = Color(0, 0, 0, 0.55)

func _on_profile_pressed() -> void:
	AudioManager.play_sfx("click")
	var modal = PROFILE_MODAL_SCENE.instantiate()
	modal.closed.connect(_update_header)
	add_child(modal)

func _on_coins_pressed() -> void:
	AudioManager.play_sfx("click")
	_show_toast("Total Coins: %d\nWin matches to earn more coins!" % SaveManager.player_data.coins)

func _show_toast(message: String) -> void:
	for c in get_children():
		if c.name == "MenuToast":
			c.queue_free()
			
	var toast = Label.new()
	toast.name = "MenuToast"
	toast.text = message
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(PRESET_CENTER)
	toast.add_theme_font_size_override("font_size", 28)
	toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	
	# Add subtle backing panel
	var panel = PanelContainer.new()
	panel.name = "MenuToastPanel"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.04, 0.94)
	sb.border_color = Color(0.85, 0.70, 0.35, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.add_child(toast)
	
	add_child(panel)
	panel.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.18)
	t.tween_interval(2.2)
	t.tween_property(panel, "modulate:a", 0.0, 0.32)
	t.tween_callback(panel.queue_free)
