class_name ClassAbilityPanel
extends PanelContainer
## Bandeau compact (en haut au centre de l'arène) de la mécanique de classe du joueur local :
## état (or, invocations…) et, si la classe en a une, le bouton de sa capacité (ex : recruter).
## Se cache pour les classes sans mécanique. Lecture seule : le bouton passe par MatchService.

const REFRESH_INTERVAL: float = 0.25
const READY_COLOR := Color(1.0, 0.85, 0.4)

var _passive: ClassPassive
var _status_label := Label.new()
var _ability_button := Button.new()
var _refresh_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.85), 10, Color(UiStyle.GOLD, 0.4), 1), UiStyle.SHADOW, 8), 12.0, 6.0))
	add_child(_build_content())
	_ability_button.pressed.connect(MatchService.use_class_ability)
	hide()


func setup(passive: ClassPassive) -> void:
	_passive = passive
	_ability_button.visible = passive.has_ability()
	_ability_button.text = passive.ability_label()
	visible = passive.has_ability() or not passive.status_text().is_empty()
	passive.changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0 and _passive and visible:
		_refresh()


func _build_content() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", UiStyle.BUTTON_TEXT)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_status_label)
	_ability_button.focus_mode = Control.FOCUS_NONE
	UiStyle.style_button(_ability_button, true)
	_ability_button.add_theme_font_size_override("font_size", 13)
	_ability_button.add_theme_stylebox_override("normal", _compact(_ability_button.get_theme_stylebox("normal")))
	_ability_button.add_theme_stylebox_override("hover", _compact(_ability_button.get_theme_stylebox("hover")))
	_ability_button.add_theme_stylebox_override("pressed", _compact(_ability_button.get_theme_stylebox("pressed")))
	_ability_button.add_theme_stylebox_override("disabled", _compact(_ability_button.get_theme_stylebox("disabled")))
	row.add_child(_ability_button)
	return row


## Bouton plus petit que les boutons de menu : marges intérieures réduites.
func _compact(style: StyleBox) -> StyleBox:
	var copy: StyleBox = style.duplicate()
	copy.content_margin_left = 14.0
	copy.content_margin_right = 14.0
	copy.content_margin_top = 4.0
	copy.content_margin_bottom = 4.0
	return copy


func _refresh() -> void:
	_refresh_left = REFRESH_INTERVAL
	_status_label.text = _passive.status_text()
	if not _passive.has_ability():
		return
	var error: String = _passive.get_ability_error()
	_ability_button.disabled = not error.is_empty()
	_ability_button.tooltip_text = error
	_status_label.add_theme_color_override("font_color", READY_COLOR if error.is_empty() else UiStyle.BUTTON_TEXT)
