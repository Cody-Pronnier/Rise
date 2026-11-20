class_name PlayerActionMenu
extends PopupMenu
## Menu déroulant ouvert par un clic droit sur l'onglet d'un joueur : voir son terrain, échanger,
## proposer une alliance, rompre l'alliance, annuler son offre… (sur soi : classement en direct).
## Il ne décide rien : SocialPanel choisit les actions disponibles et réagit à action_chosen.

signal action_chosen(action: Action, player_id: int)

enum Action { VIEW_FIELD, TRADE, ALLIANCE, BREAK_ALLIANCE, CANCEL_OFFER, STANDINGS }

const FONT_SIZE: int = 15

var _player_id: int = -1


func _ready() -> void:
	_apply_styles()
	id_pressed.connect(_on_id_pressed)


## Vide le menu et met le nom du joueur en titre.
func begin(player_id: int, title: String) -> void:
	_player_id = player_id
	clear()
	add_separator(title)


## error : "" si l'action est possible, sinon la raison (l'entrée est grisée et l'explique).
func add_action(action: Action, label: String, error: String = "") -> void:
	add_item(label if error.is_empty() else "%s  (%s)" % [label, error], action)
	var index: int = get_item_index(action)
	set_item_disabled(index, not error.is_empty())


## position : coordonnées dans la fenêtre du jeu (ex : get_global_mouse_position()).
func show_at(position_in_viewport: Vector2) -> void:
	reset_size()
	popup(Rect2i(Vector2i(position_in_viewport), Vector2i.ZERO))


func _apply_styles() -> void:
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.97), 10, Color(UiStyle.GOLD, 0.6), 2), UiStyle.SHADOW, 10), 6.0, 6.0))
	add_theme_stylebox_override("hover", UiStyle.box(Color(UiStyle.PRIMARY_BUTTON, 0.9), 6))
	add_theme_stylebox_override("separator", UiStyle.with_margins(UiStyle.box(Color.TRANSPARENT), 6.0, 4.0))
	add_theme_color_override("font_color", UiStyle.BUTTON_TEXT)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_disabled_color", UiStyle.TEXT_DIM.darkened(0.25))
	add_theme_color_override("font_separator_color", UiStyle.GOLD)
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_font_size_override("font_separator_size", FONT_SIZE)
	add_theme_constant_override("v_separation", 10)
	add_theme_constant_override("item_start_padding", 12)
	add_theme_constant_override("item_end_padding", 16)


func _on_id_pressed(id: int) -> void:
	action_chosen.emit(id as Action, _player_id)
