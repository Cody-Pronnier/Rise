class_name SettingsForm
extends VBoxContainer
## Réglages du jeu modifiables partout (menu Échap en partie) : volumes, plein écran, résolution, V-Sync.
## Chaque changement est appliqué tout de suite par SettingsService ; save() les enregistre.
## Construit entièrement en code.

const LABEL_WIDTH: float = 170.0
const VALUE_WIDTH: float = 52.0
const VOLUME_STEP: float = 0.01
const FONT_SIZE: int = 16

var _resolution_option := OptionButton.new()


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	for bus: StringName in AudioBuses.ALL:
		add_child(_create_volume_row(bus))
	add_child(_create_check_row("Plein écran", SettingsService.is_fullscreen(), _on_fullscreen_toggled))
	add_child(_create_resolution_row())
	add_child(_create_check_row("V-Sync", SettingsService.is_vsync_enabled(), SettingsService.set_vsync_enabled))
	_refresh_resolution_state()


func save() -> void:
	SettingsService.save()


# --- Lignes -----------------------------------------------------------------

func _create_volume_row(bus: StringName) -> HBoxContainer:
	var value_label: Label = _create_label(_format_percent(SettingsService.get_volume(bus)), VALUE_WIDTH)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.value = SettingsService.get_volume(bus)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	slider.add_theme_stylebox_override("slider", UiStyle.with_margins(UiStyle.box(Color(0, 0, 0, 0.5), 4), 0.0, 3.0))
	slider.add_theme_stylebox_override("grabber_area", UiStyle.with_margins(UiStyle.box(UiStyle.GOLD.darkened(0.2), 4), 0.0, 3.0))
	slider.add_theme_stylebox_override("grabber_area_highlight", UiStyle.with_margins(UiStyle.box(UiStyle.GOLD, 4), 0.0, 3.0))
	slider.value_changed.connect(_on_volume_changed.bind(bus, value_label))
	return _row(AudioBuses.label(bus), [slider, value_label])


func _create_check_row(text: String, pressed: bool, action: Callable) -> HBoxContainer:
	var check := CheckButton.new()
	check.focus_mode = Control.FOCUS_NONE
	check.set_pressed_no_signal(pressed)
	check.toggled.connect(action)
	return _row(text, [check])


func _create_resolution_row() -> HBoxContainer:
	_resolution_option.focus_mode = Control.FOCUS_NONE
	_resolution_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var resolutions: Array[Vector2i] = SettingsService.get_available_resolutions()
	for index: int in resolutions.size():
		_resolution_option.add_item("%d × %d" % [resolutions[index].x, resolutions[index].y], index)
	var current: int = resolutions.find(SettingsService.get_resolution())
	_resolution_option.select(current if current != -1 else 0)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	return _row("Résolution", [_resolution_option])


func _row(title: String, controls: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_create_label(title, LABEL_WIDTH))
	for control: Control in controls:
		row.add_child(control)
	return row


func _create_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


func _format_percent(volume: float) -> String:
	return "%d %%" % roundi(volume * 100.0)


## En plein écran, l'écran garde sa résolution native : le choix ne s'applique qu'en fenêtré.
func _refresh_resolution_state() -> void:
	_resolution_option.disabled = SettingsService.is_fullscreen()


# --- Réactions --------------------------------------------------------------

func _on_volume_changed(volume: float, bus: StringName, value_label: Label) -> void:
	SettingsService.set_volume(bus, volume)
	value_label.text = _format_percent(volume)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsService.set_fullscreen(enabled)
	_refresh_resolution_state()


func _on_resolution_selected(index: int) -> void:
	SettingsService.set_resolution(SettingsService.get_available_resolutions()[index])
