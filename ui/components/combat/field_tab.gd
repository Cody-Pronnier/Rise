class_name FieldTab
extends Button
## Onglet d'un joueur : icône de sa classe, nom, progression et mini-barre.
## Clic gauche : affiche son terrain. Clic droit : demande le menu d'actions (context_requested).

signal context_requested(player_id: int)

const MIN_SIZE := Vector2(132, 60)
const RADIUS: int = 8
const CLASS_STRIPE_WIDTH: int = 5
const PROGRESS_BAR_HEIGHT: float = 5.0
const ALLY_COLOR := Color(0.5, 0.85, 1.0)
const ICON_SIZE: int = 28
const FONT_SIZE: int = 12
const HORIZONTAL_PADDING: float = 6.0

var _player: PlayerState
var _field: Field
var _viewer_id: int
var _alliances: AllianceRegistry
var _rank: int = 0
var _progress_bar: ProgressBar


func setup(player: PlayerState, field: Field, viewer_id: int, alliances: AllianceRegistry) -> void:
	_player = player
	_field = field
	_viewer_id = viewer_id
	_alliances = alliances
	_configure_button()
	_apply_styles()
	_create_progress_bar()
	_bind_field_signals()
	_refresh()


func set_rank(rank: int) -> void:
	_rank = rank
	_refresh()


# --- Mise en place ----------------------------------------------------------

func _configure_button() -> void:
	toggle_mode = true
	custom_minimum_size = MIN_SIZE
	clip_text = true
	focus_mode = Control.FOCUS_NONE
	tooltip_text = _describe_tooltip()
	add_theme_font_size_override("font_size", FONT_SIZE)
	icon = ClassIcons.for_class(_player.class_data.id)
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_constant_override("icon_max_width", ICON_SIZE)
	add_theme_constant_override("h_separation", 4)


func _describe_tooltip() -> String:
	var tooltip: String = "%s — %s" % [_player.display_name, _player.class_data.display_name]
	return tooltip + ("\nClic droit : classement…" if _player.id == _viewer_id else "\nClic droit : échange, alliance…")


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		context_requested.emit(_player.id)
		accept_event()


func _apply_styles() -> void:
	add_theme_stylebox_override("normal", _build_style(UiStyle.PANEL_DARK, Color.TRANSPARENT))
	add_theme_stylebox_override("hover", _build_style(UiStyle.PANEL_LIGHT, Color.TRANSPARENT))
	add_theme_stylebox_override("pressed", _build_style(UiStyle.PANEL_LIGHT, UiStyle.GOLD))
	add_theme_stylebox_override("hover_pressed", _build_style(UiStyle.PANEL_LIGHT, UiStyle.GOLD))
	add_theme_color_override("font_pressed_color", UiStyle.GOLD)
	add_theme_color_override("font_hover_pressed_color", UiStyle.GOLD)


## Bordure gauche à la couleur de la classe ; bordure dorée sur l'onglet affiché.
## Bordure dorée sur l'onglet affiché, cyan pour un allié.
func _build_style(bg: Color, highlight: Color) -> StyleBoxFlat:
	var border: Color = highlight if highlight.a > 0.0 else (ALLY_COLOR if _is_ally() else Color.TRANSPARENT)
	var style: StyleBoxFlat = UiStyle.box(bg, RADIUS, border, 2 if border.a > 0.0 else 0)
	style.border_width_left = CLASS_STRIPE_WIDTH
	if border.a == 0.0:
		style.border_color = _player.class_data.character.color
	return UiStyle.with_margins(style, HORIZONTAL_PADDING, 4.0)


func _create_progress_bar() -> void:
	_progress_bar = ProgressBar.new()
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.max_value = _field.total_monsters
	_progress_bar.add_theme_stylebox_override("background", UiStyle.box(Color(0, 0, 0, 0.5), 2))
	_progress_bar.add_theme_stylebox_override("fill", UiStyle.box(_player.class_data.character.color, 2))
	add_child(_progress_bar)
	_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_progress_bar.offset_left = CLASS_STRIPE_WIDTH + 4.0
	_progress_bar.offset_right = -6.0
	_progress_bar.offset_top = -PROGRESS_BAR_HEIGHT - 4.0
	_progress_bar.offset_bottom = -4.0


func _bind_field_signals() -> void:
	_field.progress_changed.connect(_refresh.unbind(1))
	_field.protection_changed.connect(_refresh)
	_field.finished.connect(_refresh)
	_alliances.alliance_formed.connect(_on_alliances_changed.unbind(2))
	_alliances.alliance_broken.connect(_on_alliances_changed.unbind(2))


func _on_alliances_changed() -> void:
	_apply_styles()
	_refresh()


# --- Affichage --------------------------------------------------------------

func _refresh() -> void:
	text = "%s\n%s" % [_describe_name(), _describe_progress()]
	_progress_bar.visible = not _is_hidden_from_viewer()
	_progress_bar.value = _field.get_progress()


## Un allié voit la progression de son allié même quand elle est cachée.
func _is_hidden_from_viewer() -> bool:
	return _field.hides_progress() and _player.id != _viewer_id and not _is_ally()


func _is_ally() -> bool:
	return _alliances.are_allied(_viewer_id, _player.id)


func _describe_name() -> String:
	if _player.id == _viewer_id:
		return "Toi"
	return "%s (allié)" % _short_name() if _is_ally() else _short_name()


## L'icône montre déjà la classe : on retire le « (Mage) » que portent les noms des bots.
func _short_name() -> String:
	var class_suffix: String = " (%s)" % _player.class_data.display_name
	if _player.display_name.ends_with(class_suffix):
		return _player.display_name.trim_suffix(class_suffix)
	return _player.display_name


func _describe_progress() -> String:
	if _is_hidden_from_viewer():
		return "???"
	if _rank > 0:
		return "Terminé · #%d" % _rank
	return "Monstre %d/%d" % [mini(_field.kills + 1, _field.total_monsters), _field.total_monsters]
