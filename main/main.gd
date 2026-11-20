extends Control
## Point d'entrée : affiche l'écran courant et réagit aux événements globaux (salon, partie).
## C'est le seul script qui connaît la liste des écrans.

const SCREEN_SCENES: Dictionary[Screen.Id, PackedScene] = {
	Screen.Id.MAIN_MENU: preload("res://ui/screens/main_menu/main_menu.tscn"),
	Screen.Id.LOBBY_BROWSER: preload("res://ui/screens/lobby_browser/lobby_browser.tscn"),
	Screen.Id.LOBBY: preload("res://ui/screens/lobby/lobby_screen.tscn"),
	Screen.Id.CLASS_SELECT: preload("res://ui/screens/class_select/class_select_screen.tscn"),
	Screen.Id.COMBAT: preload("res://ui/screens/combat/combat_screen.tscn"),
	Screen.Id.OPTIONS: preload("res://ui/screens/options/options_screen.tscn"),
	Screen.Id.REWARDS: preload("res://ui/screens/rewards/reward_screen.tscn"),
	Screen.Id.CODEX: preload("res://ui/screens/codex/codex_screen.tscn"),
	Screen.Id.DECKS: preload("res://ui/screens/decks/decks_screen.tscn"),
}

@onready var _screen_container: Control = %ScreenContainer
@onready var _error_dialog: AcceptDialog = %ErrorDialog

var _current_screen: Screen


func _ready() -> void:
	_connect_lobby_signals()
	_connect_match_signals()
	_show_screen(Screen.Id.MAIN_MENU)


func _connect_lobby_signals() -> void:
	LobbyService.lobby_joined.connect(_on_lobby_joined)
	LobbyService.lobby_left.connect(_on_lobby_left)
	LobbyService.lobby_creation_failed.connect(_show_error)
	LobbyService.lobby_join_failed.connect(_show_error)
	LobbyService.game_start_requested.connect(_on_game_start_requested)


func _connect_match_signals() -> void:
	MatchService.class_selection_started.connect(_show_screen.bind(Screen.Id.CLASS_SELECT))
	MatchService.round_started.connect(_show_screen.bind(Screen.Id.COMBAT).unbind(1))
	MatchService.reward_phase_started.connect(_show_screen.bind(Screen.Id.REWARDS))
	MatchService.match_ended.connect(_on_match_ended)


func _show_screen(screen_id: Screen.Id) -> void:
	_free_current_screen()
	_current_screen = SCREEN_SCENES[screen_id].instantiate()
	_current_screen.navigation_requested.connect(_show_screen)
	_screen_container.add_child(_current_screen)


func _free_current_screen() -> void:
	if is_instance_valid(_current_screen):
		_current_screen.queue_free()
	_current_screen = null


func _show_error(message: String) -> void:
	_error_dialog.dialog_text = message
	_error_dialog.popup_centered()


func _on_lobby_joined(_lobby_id: int) -> void:
	_show_screen(Screen.Id.LOBBY)


func _on_lobby_left() -> void:
	_show_screen(Screen.Id.MAIN_MENU)


## Tous les membres démarrent la partie en ligne ; l'écran change quand l'hôte lance le choix de classe.
func _on_game_start_requested(lobby_id: int) -> void:
	MatchService.start_online_match(lobby_id)


func _on_match_ended(reason: String) -> void:
	_show_screen(Screen.Id.MAIN_MENU)
	if not reason.is_empty():
		_show_error(reason)
