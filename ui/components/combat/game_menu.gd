class_name GameMenu
extends Control
## Menu ouvert avec Échap pendant une partie. La partie continue derrière (elle est en ligne) :
## reprendre, régler les options (volumes, affichage), ou quitter la partie après confirmation.
## Construit en code ; l'écran réagit à leave_confirmed.

signal leave_confirmed

const PANEL_WIDTH: float = 360.0
const OPTIONS_WIDTH: float = 520.0

var _panel := PanelContainer.new()
var _title := Label.new()
var _hint := Label.new()
var _main_buttons := VBoxContainer.new()
var _confirm_buttons := VBoxContainer.new()
var _options_page := VBoxContainer.new()
var _settings_form := SettingsForm.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_build_dim())
	add_child(_build_center())
	hide()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	_show_main()
	show()


func close() -> void:
	if _options_page.visible:
		_settings_form.save()
	hide()


# --- Construction -----------------------------------------------------------

func _build_dim() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	return dim


func _build_center() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size.x = PANEL_WIDTH
	_panel.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", UiStyle.GOLD)
	column.add_child(_title)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	column.add_child(_hint)
	_fill_main_buttons()
	_fill_confirm_buttons()
	_fill_options_page()
	column.add_child(_main_buttons)
	column.add_child(_confirm_buttons)
	column.add_child(_options_page)
	_panel.add_child(column)
	center.add_child(_panel)
	return center


func _fill_main_buttons() -> void:
	_main_buttons.add_theme_constant_override("separation", 10)
	_main_buttons.add_child(_create_button("Reprendre", true, close))
	_main_buttons.add_child(_create_button("Options", false, _show_options))
	_main_buttons.add_child(_create_button("Quitter la partie", false, _show_confirmation))


func _fill_confirm_buttons() -> void:
	_confirm_buttons.add_theme_constant_override("separation", 10)
	_confirm_buttons.add_child(_create_button("Oui, quitter", true, leave_confirmed.emit))
	_confirm_buttons.add_child(_create_button("Non, rester", false, _show_main))


func _fill_options_page() -> void:
	_options_page.add_theme_constant_override("separation", 16)
	_options_page.add_child(_settings_form)
	_options_page.add_child(_create_button("Retour", true, _leave_options))


func _create_button(text: String, primary: bool, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 48.0
	UiStyle.style_button(button, primary)
	button.pressed.connect(action)
	return button


# --- Affichage --------------------------------------------------------------

func _show_main() -> void:
	_show_page(_main_buttons, "Menu", "La partie continue pendant que ce menu est ouvert.", PANEL_WIDTH)


func _show_confirmation() -> void:
	_show_page(_confirm_buttons, "Quitter la partie ?", "Tu retourneras au menu principal et tu ne pourras pas revenir dans cette partie.", PANEL_WIDTH)


func _show_options() -> void:
	_show_page(_options_page, "Options", "", OPTIONS_WIDTH)


func _show_page(page: Control, title: String, hint: String, width: float) -> void:
	for other: Control in [_main_buttons, _confirm_buttons, _options_page]:
		other.visible = other == page
	_title.text = title
	_hint.text = hint
	_hint.visible = not hint.is_empty()
	_panel.custom_minimum_size.x = width
	_panel.reset_size()


# --- Réactions --------------------------------------------------------------

func _leave_options() -> void:
	_settings_form.save()
	_show_main()


## Un clic à côté de la fenêtre la ferme.
func _on_dim_input(event: InputEvent) -> void:
	if UiInput.is_left_click(event):
		close()
