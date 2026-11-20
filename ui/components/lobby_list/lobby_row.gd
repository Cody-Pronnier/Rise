class_name LobbyRow
extends PanelContainer
## Carte d'un salon dans la liste : nom, places occupées (une pastille par joueur) et bouton Rejoindre.

signal join_pressed(lobby_id: int)

const RADIUS: int = 10
const SLOT_SIZE := Vector2(14, 14)
const SLOT_FILLED := Color(1.0, 0.78, 0.3)
const SLOT_BOT := Color(0.5, 0.7, 0.95)
const SLOT_EMPTY := Color(1.0, 1.0, 1.0, 0.12)
const FULL_COLOR := Color(1.0, 0.5, 0.45)

@onready var _name_label: Label = %NameLabel
@onready var _players_label: Label = %PlayersLabel
@onready var _slots: HBoxContainer = %Slots
@onready var _join_button: Button = %JoinButton

var _lobby_id: int = 0
var _is_full: bool = false


func _ready() -> void:
	UiStyle.style_button(_join_button, true)
	_join_button.add_theme_font_size_override("font_size", 16)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	_join_button.pressed.connect(_on_join_button_pressed)
	_set_hovered(false)


## À appeler après add_child() pour que les nœuds @onready soient prêts.
func display(lobby: LobbyInfo) -> void:
	_lobby_id = lobby.id
	_is_full = lobby.is_full()
	_name_label.text = lobby.name
	_players_label.text = "Complet" if _is_full else _describe_players(lobby)
	if lobby.is_locked:
		_players_label.text += "  ·  Mot de passe"
	_players_label.add_theme_color_override("font_color", FULL_COLOR if _is_full else UiStyle.TEXT_DIM)
	_build_slots(lobby)
	set_join_enabled(true)


## Un salon complet reste toujours désactivé.
func set_join_enabled(enabled: bool) -> void:
	_join_button.disabled = _is_full or not enabled


func _describe_players(lobby: LobbyInfo) -> String:
	var text: String = "%d / %d joueurs" % [lobby.member_count + lobby.bot_count, lobby.max_members]
	return text + (" (dont %d bot%s)" % [lobby.bot_count, "s" if lobby.bot_count > 1 else ""] if lobby.bot_count > 0 else "")


## Une pastille par place : dorée = joueur, bleue = bot, grise = libre.
func _build_slots(lobby: LobbyInfo) -> void:
	for slot: Node in _slots.get_children():
		slot.queue_free()
	for index: int in lobby.max_members:
		_slots.add_child(_create_slot(_slot_color(index, lobby)))


func _slot_color(index: int, lobby: LobbyInfo) -> Color:
	if index < lobby.member_count:
		return SLOT_FILLED
	if index < lobby.member_count + lobby.bot_count:
		return SLOT_BOT
	return SLOT_EMPTY


func _create_slot(color: Color) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel", UiStyle.box(color, 7))
	return slot


func _set_hovered(hovered: bool) -> void:
	var border: Color = UiStyle.GOLD if hovered else Color(UiStyle.SECONDARY_BORDER, 0.5)
	var bg: Color = UiStyle.PANEL_LIGHT if hovered else UiStyle.PANEL_DARK
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.box(bg, RADIUS, border, 1), 16.0, 10.0))


func _on_join_button_pressed() -> void:
	join_pressed.emit(_lobby_id)
