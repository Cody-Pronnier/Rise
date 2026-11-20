class_name UiStyle
extends RefCounted
## Palette et fabriques de StyleBox partagées par toute l'interface de combat.

const GOLD := Color(1.0, 0.78, 0.3)
const CYAN := Color(0.4, 0.9, 1.0)
const PANEL_DARK := Color(0.11, 0.1, 0.15)
const PANEL_LIGHT := Color(0.18, 0.17, 0.25)
const TEXT_DIM := Color(0.68, 0.66, 0.78)
const SHADOW := Color(0.0, 0.0, 0.0, 0.5)

const PRIMARY_BUTTON := Color(0.55, 0.38, 0.1)
const SECONDARY_BORDER := Color(0.42, 0.4, 0.52)
const DISABLED_BUTTON := Color(0.16, 0.15, 0.2)
const DISABLED_BORDER := Color(0.3, 0.28, 0.36)
const BUTTON_TEXT := Color(1.0, 0.95, 0.85)

const HERO_HEALTH := Color(0.35, 0.8, 0.4)
const MONSTER_HEALTH := Color(0.85, 0.25, 0.25)

const STATUS_COLORS: Dictionary[int, Color] = {
	StatusData.Category.BUFF: Color(0.2, 0.5, 0.3),
	StatusData.Category.DEBUFF: Color(0.6, 0.2, 0.2),
	StatusData.Category.CONTROL: Color(0.45, 0.28, 0.65),
}


static func box(bg: Color, radius: int = 8, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.anti_aliasing = true
	return style


static func with_shadow(style: StyleBoxFlat, color: Color, shadow_size: int, offset: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	style.shadow_color = color
	style.shadow_size = shadow_size
	style.shadow_offset = offset
	return style


static func with_margins(style: StyleBoxFlat, horizontal: float, vertical: float) -> StyleBoxFlat:
	style.content_margin_left = horizontal
	style.content_margin_right = horizontal
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style


## Habille un bouton : principal (doré) ou secondaire (sombre).
static func style_button(button: Button, primary: bool) -> void:
	var bg: Color = PRIMARY_BUTTON if primary else PANEL_DARK
	var border: Color = GOLD if primary else SECONDARY_BORDER
	button.add_theme_stylebox_override("normal", _button_box(bg, border, 0))
	button.add_theme_stylebox_override("hover", _button_box(bg.lightened(0.15), border.lightened(0.25), 12))
	button.add_theme_stylebox_override("pressed", _button_box(bg.darkened(0.2), border, 4))
	button.add_theme_stylebox_override("disabled", _button_box(DISABLED_BUTTON, DISABLED_BORDER, 0))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", TEXT_DIM.darkened(0.3))
	button.add_theme_font_size_override("font_size", 20)


## Champ de saisie sombre, bordure dorée quand il a le focus.
static func style_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_stylebox_override("normal", with_margins(box(Color(0.05, 0.04, 0.08, 0.9), 8, SECONDARY_BORDER, 1), 12.0, 8.0))
	line_edit.add_theme_stylebox_override("focus", with_margins(box(Color(0.05, 0.04, 0.08, 0.9), 8, GOLD, 2), 12.0, 8.0))
	line_edit.add_theme_color_override("font_placeholder_color", TEXT_DIM.darkened(0.2))
	line_edit.add_theme_color_override("caret_color", GOLD)
	line_edit.add_theme_font_size_override("font_size", 18)


## Grand panneau central des écrans de menu.
static func menu_panel() -> StyleBoxFlat:
	var style: StyleBoxFlat = box(Color(PANEL_DARK, 0.94), 16, Color(GOLD, 0.5), 2)
	return with_margins(with_shadow(style, SHADOW, 16), 32.0, 24.0)


static func _button_box(bg: Color, border: Color, glow: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = with_shadow(box(bg, 10, border, 2), Color(border, 0.4), glow)
	return with_margins(style, 28.0, 10.0)


static func bar_background() -> StyleBoxFlat:
	return box(Color(0.05, 0.05, 0.08, 0.9), 6, Color(0, 0, 0, 0.8), 2)


static func bar_fill(color: Color) -> StyleBoxFlat:
	return box(color, 6)


static func status_chip(category: int) -> StyleBoxFlat:
	return with_margins(box(STATUS_COLORS.get(category, PANEL_LIGHT), 6), 6.0, 1.0)
