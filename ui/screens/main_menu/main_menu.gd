extends Screen
## Page d'accueil : titre animé, icônes des classes, accès au jeu en ligne, à l'entraînement,
## à ses decks, au codex (classes et cartes), aux règles du jeu et aux options.

const ICON_SIZE := Vector2(56, 56)
const ICON_BOB_HEIGHT: float = 8.0
const ICON_BOB_DURATION: float = 2.4
## Décalage de phase entre deux icônes, pour un effet de vague.
const ICON_PHASE_STEP: float = 0.3
const TITLE_PULSE_SCALE: float = 1.03
const TITLE_PULSE_DURATION: float = 2.8
const STATUS_OK_COLOR := Color(0.55, 0.9, 0.6)
const STATUS_ERROR_COLOR := Color(1.0, 0.55, 0.5)

@onready var _title_label: Label = %TitleLabel
@onready var _icon_row: HBoxContainer = %IconRow
@onready var _status_label: Label = %SteamStatusLabel
@onready var _play_button: Button = %PlayButton
@onready var _training_button: Button = %TrainingButton
@onready var _decks_button: Button = %DecksButton
@onready var _codex_button: Button = %CodexButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_style_buttons()
	_connect_buttons()
	_display_steam_status()
	_build_icon_row()
	_start_title_pulse()


# --- Mise en place ----------------------------------------------------------

func _style_buttons() -> void:
	UiStyle.style_button(_play_button, true)
	UiStyle.style_button(_training_button, false)
	UiStyle.style_button(_decks_button, false)
	UiStyle.style_button(_codex_button, false)
	UiStyle.style_button(_how_to_play_button, false)
	UiStyle.style_button(_options_button, false)
	UiStyle.style_button(_quit_button, false)


func _connect_buttons() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_training_button.pressed.connect(_on_training_pressed)
	_decks_button.pressed.connect(navigation_requested.emit.bind(Screen.Id.DECKS))
	_codex_button.pressed.connect(_on_codex_pressed)
	_how_to_play_button.pressed.connect(navigation_requested.emit.bind(Screen.Id.HOW_TO_PLAY))
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _display_steam_status() -> void:
	_play_button.disabled = not SteamService.is_ready
	_status_label.text = _build_status_text()
	_status_label.add_theme_color_override("font_color", STATUS_OK_COLOR if SteamService.is_ready else STATUS_ERROR_COLOR)


func _build_status_text() -> String:
	if SteamService.is_ready:
		return "● Steam : %s" % SteamService.local_persona_name
	return "● Steam indisponible : %s" % SteamService.init_error


# --- Décor animé ------------------------------------------------------------

func _build_icon_row() -> void:
	var classes: Array[ClassData] = ClassCatalog.get_all()
	for index: int in classes.size():
		_add_bobbing_icon(classes[index], index)


func _add_bobbing_icon(class_data: ClassData, index: int) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = ICON_SIZE + Vector2(0.0, ICON_BOB_HEIGHT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := _create_icon(class_data)
	holder.add_child(icon)
	_icon_row.add_child(holder)
	_start_icon_bob(icon, index)


func _create_icon(class_data: ClassData) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = ClassIcons.for_class(class_data.id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = ICON_SIZE
	icon.position.y = ICON_BOB_HEIGHT
	icon.tooltip_text = class_data.display_name
	return icon


func _start_icon_bob(icon: TextureRect, index: int) -> void:
	var tween: Tween = icon.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon, "position:y", 0.0, ICON_BOB_DURATION / 2.0)
	tween.tween_property(icon, "position:y", ICON_BOB_HEIGHT, ICON_BOB_DURATION / 2.0)
	tween.custom_step(index * ICON_PHASE_STEP)


func _start_title_pulse() -> void:
	_title_label.resized.connect(_center_title_pivot)
	_center_title_pivot()
	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_title_label, "scale", Vector2.ONE * TITLE_PULSE_SCALE, TITLE_PULSE_DURATION / 2.0)
	tween.tween_property(_title_label, "scale", Vector2.ONE, TITLE_PULSE_DURATION / 2.0)


func _center_title_pivot() -> void:
	_title_label.pivot_offset = _title_label.size / 2.0


# --- Réactions --------------------------------------------------------------

func _on_play_pressed() -> void:
	navigation_requested.emit(Screen.Id.LOBBY_BROWSER)


func _on_training_pressed() -> void:
	navigation_requested.emit(Screen.Id.CLASS_SELECT)


func _on_codex_pressed() -> void:
	navigation_requested.emit(Screen.Id.CODEX)


func _on_options_pressed() -> void:
	navigation_requested.emit(Screen.Id.OPTIONS)


func _on_quit_pressed() -> void:
	get_tree().quit()
