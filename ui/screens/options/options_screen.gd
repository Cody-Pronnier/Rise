extends Screen
## Options : volumes, résolution, plein écran et V-Sync.
## Chaque changement est appliqué tout de suite ; l'enregistrement se fait en quittant l'écran.

const ROW_LABEL_WIDTH: float = 190.0
const ROW_VALUE_WIDTH: float = 56.0
const VOLUME_STEP: float = 0.01

@onready var _panel: PanelContainer = %Panel
@onready var _volume_list: VBoxContainer = %VolumeList
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_check: CheckButton = %VsyncCheck
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_apply_styles()
	_build_volume_rows()
	_fill_resolutions()
	_load_display_values()
	_connect_ui()


func _exit_tree() -> void:
	SettingsService.save()


# --- Mise en place ----------------------------------------------------------

func _apply_styles() -> void:
	var panel_style: StyleBoxFlat = UiStyle.box(Color(UiStyle.PANEL_DARK, 0.94), 16, Color(UiStyle.GOLD, 0.5), 2)
	_panel.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(panel_style, UiStyle.SHADOW, 16), 36.0, 28.0))
	UiStyle.style_button(_back_button, false)


func _connect_ui() -> void:
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_vsync_check.toggled.connect(SettingsService.set_vsync_enabled)
	_back_button.pressed.connect(_on_back_pressed)


func _load_display_values() -> void:
	_fullscreen_check.set_pressed_no_signal(SettingsService.is_fullscreen())
	_refresh_resolution_state()
	_vsync_check.set_pressed_no_signal(SettingsService.is_vsync_enabled())


# --- Résolution -------------------------------------------------------------

## L'id de chaque entrée est son index dans get_available_resolutions().
func _fill_resolutions() -> void:
	_resolution_option.clear()
	var resolutions: Array[Vector2i] = SettingsService.get_available_resolutions()
	for index: int in resolutions.size():
		_resolution_option.add_item("%d × %d" % [resolutions[index].x, resolutions[index].y], index)
	var current: int = resolutions.find(SettingsService.get_resolution())
	_resolution_option.select(current if current != -1 else 0)


## En plein écran, l'écran garde sa résolution native : le choix ne s'applique qu'en fenêtré.
func _refresh_resolution_state() -> void:
	_resolution_option.disabled = SettingsService.is_fullscreen()
	_resolution_option.tooltip_text = "Désactive le plein écran pour choisir la taille de la fenêtre." if SettingsService.is_fullscreen() else ""


func _on_resolution_selected(index: int) -> void:
	SettingsService.set_resolution(SettingsService.get_available_resolutions()[index])


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsService.set_fullscreen(enabled)
	_refresh_resolution_state()


# --- Lignes de volume -------------------------------------------------------

func _build_volume_rows() -> void:
	for bus: StringName in AudioBuses.ALL:
		_volume_list.add_child(_create_volume_row(bus))


func _create_volume_row(bus: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var value_label: Label = _create_row_label(_format_percent(SettingsService.get_volume(bus)), ROW_VALUE_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(_create_row_label(AudioBuses.label(bus), ROW_LABEL_WIDTH, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(_create_volume_slider(bus, value_label))
	row.add_child(value_label)
	return row


func _create_row_label(text: String, width: float, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", 17)
	return label


func _create_volume_slider(bus: StringName, value_label: Label) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.value = SettingsService.get_volume(bus)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	_style_slider(slider)
	slider.value_changed.connect(_on_volume_changed.bind(bus, value_label))
	return slider


func _style_slider(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", UiStyle.with_margins(UiStyle.box(Color(0, 0, 0, 0.5), 4), 0.0, 3.0))
	slider.add_theme_stylebox_override("grabber_area", UiStyle.with_margins(UiStyle.box(UiStyle.GOLD.darkened(0.2), 4), 0.0, 3.0))
	slider.add_theme_stylebox_override("grabber_area_highlight", UiStyle.with_margins(UiStyle.box(UiStyle.GOLD, 4), 0.0, 3.0))


func _format_percent(volume: float) -> String:
	return "%d %%" % roundi(volume * 100.0)


# --- Réactions --------------------------------------------------------------

func _on_volume_changed(volume: float, bus: StringName, value_label: Label) -> void:
	SettingsService.set_volume(bus, volume)
	value_label.text = _format_percent(volume)


func _on_back_pressed() -> void:
	navigation_requested.emit(Screen.Id.MAIN_MENU)
