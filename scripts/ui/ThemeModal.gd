class_name ThemeModal
extends CanvasLayer

## ThemeModal provides a dedicated, luxurious theme selection interface
## featuring live background preview, 3 distinct luxury themes,
## cross button (cancel/revert), and permanent Save & Apply.

signal closed
signal theme_previewed(theme_id: String)

@onready var cross_btn: Button = find_child("CrossButton", true, false)
@onready var save_btn: Button = find_child("SaveButton", true, false)
@onready var dim_overlay: ColorRect = find_child("DimOverlay", true, false)

@onready var classic_card: Button = find_child("ClassicCard", true, false)
@onready var mahogany_card: Button = find_child("MahoganyCard", true, false)
@onready var maple_card: Button = find_child("MapleCard", true, false)

var _orig_theme: String = "classic_wood"
var _selected_theme: String = "classic_wood"

var _cards: Dictionary = {}

func _ready() -> void:
	_orig_theme = SaveManager.settings.board_theme
	_selected_theme = _orig_theme
	
	_cards = {
		"classic_wood": classic_card,
		"royal_mahogany": mahogany_card,
		"ivory_maple": maple_card
	}
	
	if classic_card:
		classic_card.pressed.connect(func(): _select_theme("classic_wood"))
		_setup_btn(classic_card)
	if mahogany_card:
		mahogany_card.pressed.connect(func(): _select_theme("royal_mahogany"))
		_setup_btn(mahogany_card)
	if maple_card:
		maple_card.pressed.connect(func(): _select_theme("ivory_maple"))
		_setup_btn(maple_card)
		
	if cross_btn:
		cross_btn.pressed.connect(_on_cancel_pressed)
		_setup_btn(cross_btn)
		
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
		_setup_btn(save_btn)
		
	if dim_overlay:
		dim_overlay.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				_on_cancel_pressed()
		)
		
	_refresh_cards()

func _setup_btn(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.08).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx("click")
		HapticManager.vibrate_selection()
	)
	btn.button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _select_theme(theme_id: String) -> void:
	_selected_theme = theme_id
	_refresh_cards()
	theme_previewed.emit(theme_id)

func _refresh_cards() -> void:
	for t_id in _cards.keys():
		var btn = _cards[t_id] as Button
		if not btn:
			continue
		var is_sel = (t_id == _selected_theme)
		var badge = btn.find_child("SelectedBadge", true, false)
		if badge:
			badge.visible = is_sel
			
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(18)
		if is_sel:
			sb.bg_color = Color(0.24, 0.16, 0.08, 0.95)
			sb.border_color = Color(1.0, 0.85, 0.35, 1.0)
			sb.set_border_width_all(3)
			sb.shadow_size = 14
			sb.shadow_color = Color(1.0, 0.8, 0.2, 0.45)
		else:
			sb.bg_color = Color(0.12, 0.08, 0.04, 0.85)
			sb.border_color = Color(0.45, 0.35, 0.22, 0.7)
			sb.set_border_width_all(2)
			sb.shadow_size = 0
			
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

## Cancel button (✕) or tap outside: Discard preview and revert to original saved theme
func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("click")
	theme_previewed.emit(_orig_theme)
	closed.emit()
	queue_free()

## Save & Apply button: Permanently save theme to settings
func _on_save_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.settings.board_theme = _selected_theme
	SaveManager.save_data()
	theme_previewed.emit(_selected_theme)
	closed.emit()
	queue_free()
