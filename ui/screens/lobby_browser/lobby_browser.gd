extends Screen
## Recherche de partie : liste les salons publics et permet d'en créer un.
## La navigation vers le lobby est gérée par Main quand LobbyService émet lobby_joined.

const SEARCHING_TEXT: String = "Recherche des salons…"
const EMPTY_TEXT: String = "Aucun salon public pour le moment.\nCrée le tien et invite tes amis !"

@onready var _panel: PanelContainer = %Panel
@onready var _lobby_name_input: LineEdit = %LobbyNameInput
@onready var _max_players_option: OptionButton = %MaxPlayersOption
@onready var _visibility_option: OptionButton = %VisibilityOption
@onready var _password_input: LineEdit = %PasswordInput
@onready var _create_button: Button = %CreateButton
@onready var _refresh_button: Button = %RefreshButton
@onready var _back_button: Button = %BackButton
@onready var _status_label: Label = %StatusLabel
@onready var _list_frame: PanelContainer = %ListFrame
@onready var _empty_label: Label = %EmptyLabel
@onready var _lobby_list: LobbyList = %LobbyList


func _ready() -> void:
	_apply_styles()
	_connect_ui()
	_connect_services()
	_fill_default_lobby_name()
	PlayerCountOptions.fill(_max_players_option, GameConfig.MAX_PLAYERS)
	LobbyVisibility.fill_option(_visibility_option, LobbyVisibility.Type.PUBLIC)
	_password_input.max_length = GameConfig.MAX_PASSWORD_LENGTH
	_refresh_lobbies()


# --- Mise en place ----------------------------------------------------------

func _apply_styles() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	_list_frame.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.box(Color(0.03, 0.03, 0.05, 0.7), 12), 10.0, 10.0))
	UiStyle.style_line_edit(_lobby_name_input)
	UiStyle.style_line_edit(_password_input)
	UiStyle.style_button(_create_button, true)
	UiStyle.style_button(_refresh_button, false)
	UiStyle.style_button(_back_button, false)
	_refresh_button.add_theme_font_size_override("font_size", 15)


func _connect_ui() -> void:
	_create_button.pressed.connect(_on_create_pressed)
	_lobby_name_input.text_submitted.connect(_on_lobby_name_submitted)
	_password_input.text_submitted.connect(_on_lobby_name_submitted)
	_refresh_button.pressed.connect(_refresh_lobbies)
	_back_button.pressed.connect(_on_back_pressed)
	_lobby_list.join_requested.connect(_on_join_requested)


func _connect_services() -> void:
	LobbySearch.lobbies_found.connect(_on_lobbies_found)
	LobbyService.lobby_creation_failed.connect(_on_lobby_request_failed)
	LobbyService.lobby_join_failed.connect(_on_lobby_request_failed)


func _fill_default_lobby_name() -> void:
	_lobby_name_input.max_length = GameConfig.MAX_LOBBY_NAME_LENGTH
	_lobby_name_input.text = "Salon de %s" % SteamService.local_persona_name


# --- Affichage --------------------------------------------------------------

func _refresh_lobbies() -> void:
	_refresh_button.disabled = true
	_status_label.text = SEARCHING_TEXT
	LobbySearch.request_lobbies()


func _set_actions_enabled(enabled: bool) -> void:
	_create_button.disabled = not enabled
	_refresh_button.disabled = not enabled
	_lobby_name_input.editable = enabled
	_max_players_option.disabled = not enabled
	_visibility_option.disabled = not enabled
	_password_input.editable = enabled
	_lobby_list.set_join_enabled(enabled)


func _show_empty_state(is_empty: bool) -> void:
	_empty_label.text = EMPTY_TEXT
	_empty_label.visible = is_empty
	_lobby_list.visible = not is_empty


func _describe_lobby_count(count: int) -> String:
	if count == 0:
		return ""
	return "%d salon%s trouvé%s" % [count, "s" if count > 1 else "", "s" if count > 1 else ""]


# --- Réactions --------------------------------------------------------------

func _on_lobbies_found(lobbies: Array[LobbyInfo]) -> void:
	_refresh_button.disabled = false
	_lobby_list.display(lobbies)
	_show_empty_state(lobbies.is_empty())
	_status_label.text = _describe_lobby_count(lobbies.size())


func _on_create_pressed() -> void:
	_set_actions_enabled(false)
	_status_label.text = "Création du salon…"
	LobbyService.create_lobby(
		_lobby_name_input.text,
		PlayerCountOptions.selected_count(_max_players_option),
		LobbyVisibility.selected_in(_visibility_option),
		_password_input.text
	)


func _on_lobby_name_submitted(_text: String) -> void:
	if not _create_button.disabled:
		_on_create_pressed()


func _on_join_requested(lobby_id: int) -> void:
	_set_actions_enabled(false)
	_status_label.text = "Connexion au salon…"
	LobbyService.join_lobby(lobby_id)


func _on_lobby_request_failed(_reason: String) -> void:
	_set_actions_enabled(true)
	_status_label.text = ""


func _on_back_pressed() -> void:
	navigation_requested.emit(Screen.Id.MAIN_MENU)
