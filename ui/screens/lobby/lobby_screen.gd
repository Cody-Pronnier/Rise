extends Screen
## Salon d'attente : places (joueurs, bots, places libres), état « prêt », chat, lancement.
## L'hôte peut renommer le salon, changer le nombre de places, ajouter ou retirer des bots,
## choisir la visibilité et poser un mot de passe. Tout le monde peut inviter des amis Steam.
## Un invité qui arrive dans un salon protégé doit d'abord saisir le mot de passe (PasswordPrompt).
## Quitter passe par LobbyService ; Main ramène au menu quand lobby_left est émis.

const READY_BUTTON_COLOR := Color(0.22, 0.55, 0.3)
const READY_BUTTON_BORDER := Color(0.5, 0.95, 0.6)

@onready var _lobby_name_label: Label = %LobbyNameLabel
@onready var _lobby_name_edit: LineEdit = %LobbyNameEdit
@onready var _max_players_option: OptionButton = %MaxPlayersOption
@onready var _player_count_label: Label = %PlayerCountLabel
@onready var _players_panel: PanelContainer = %PlayersPanel
@onready var _chat_frame: PanelContainer = %ChatFrame
@onready var _member_list: MemberList = %MemberList
@onready var _ready_status_label: Label = %ReadyStatusLabel
@onready var _leave_button: Button = %LeaveButton
@onready var _ready_button: Button = %ReadyButton
@onready var _start_button: Button = %StartButton
@onready var _visibility_option: OptionButton = %VisibilityOption
@onready var _password_edit: LineEdit = %PasswordEdit
@onready var _privacy_label: Label = %PrivacyLabel
@onready var _invite_button: Button = %InviteButton
@onready var _invite_dialog: FriendInviteDialog = %FriendInviteDialog
@onready var _password_prompt: PasswordPrompt = %PasswordPrompt

var _is_starting: bool = false


func _ready() -> void:
	_apply_styles()
	PlayerCountOptions.fill(_max_players_option, LobbyService.get_max_players())
	LobbyVisibility.fill_option(_visibility_option, LobbyService.get_visibility())
	_lobby_name_edit.max_length = GameConfig.MAX_LOBBY_NAME_LENGTH
	_password_edit.max_length = GameConfig.MAX_PASSWORD_LENGTH
	_password_edit.text = LobbyService.get_password()
	_connect_ui()
	_connect_services()
	_refresh_all()
	if LobbyService.is_awaiting_password():
		_password_prompt.open()


# --- Mise en place ----------------------------------------------------------

func _apply_styles() -> void:
	_players_panel.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	_chat_frame.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	_player_count_label.add_theme_stylebox_override("normal", UiStyle.with_margins(UiStyle.box(Color(0.05, 0.04, 0.08, 0.85), 8, Color(UiStyle.GOLD, 0.5), 1), 14.0, 6.0))
	UiStyle.style_line_edit(_lobby_name_edit)
	UiStyle.style_line_edit(_password_edit)
	UiStyle.style_button(_invite_button, false)
	_lobby_name_edit.add_theme_font_size_override("font_size", 24)
	UiStyle.style_button(_leave_button, false)
	UiStyle.style_button(_start_button, true)
	_style_ready_button()


## Bouton bascule : sombre au repos, vert quand le joueur est prêt.
func _style_ready_button() -> void:
	UiStyle.style_button(_ready_button, false)
	var ready_style: StyleBoxFlat = UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(READY_BUTTON_COLOR, 10, READY_BUTTON_BORDER, 2), Color(READY_BUTTON_BORDER, 0.4), 10), 28.0, 10.0)
	_ready_button.add_theme_stylebox_override("pressed", ready_style)
	_ready_button.add_theme_stylebox_override("hover_pressed", ready_style)
	_ready_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	_ready_button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)


func _connect_ui() -> void:
	_leave_button.pressed.connect(_on_leave_pressed)
	_ready_button.toggled.connect(_on_ready_toggled)
	_start_button.pressed.connect(_on_start_pressed)
	_lobby_name_edit.text_submitted.connect(_on_lobby_name_submitted)
	_lobby_name_edit.focus_exited.connect(_submit_lobby_name)
	_max_players_option.item_selected.connect(_on_max_players_selected)
	_member_list.add_bot_requested.connect(LobbyService.add_bot)
	_member_list.remove_bot_requested.connect(LobbyService.remove_bot)
	_visibility_option.item_selected.connect(_on_visibility_selected)
	_password_edit.text_submitted.connect(_on_password_submitted)
	_password_edit.focus_exited.connect(_submit_password)
	_invite_button.pressed.connect(_invite_dialog.open)
	_password_prompt.submitted.connect(LobbyService.submit_password)
	_password_prompt.cancelled.connect(LobbyService.leave_lobby)


func _connect_services() -> void:
	LobbyService.members_changed.connect(_refresh_all.unbind(1))
	LobbyService.lobby_data_changed.connect(_refresh_all)
	LobbyService.game_start_requested.connect(_on_game_start_requested)
	LobbyService.password_required.connect(_password_prompt.open)
	LobbyService.password_accepted.connect(_password_prompt.close)
	LobbyService.password_rejected.connect(_on_password_rejected)


# --- Affichage --------------------------------------------------------------

func _refresh_all() -> void:
	var members: Array[LobbyMember] = LobbyService.get_members()
	var is_host: bool = LobbyService.is_local_host()
	_refresh_header(is_host)
	_refresh_privacy(is_host)
	_member_list.display(members, LobbyService.get_bot_count(), LobbyService.get_max_players(), is_host and not _is_starting)
	_player_count_label.text = "%d / %d joueurs" % [LobbyService.get_total_players(), LobbyService.get_max_players()]
	_ready_status_label.text = _describe_ready_status(members)
	_update_start_button(is_host)


## L'hôte édite le nom et le nombre de places ; les autres les voient seulement.
func _refresh_header(is_host: bool) -> void:
	var lobby_name: String = LobbyService.get_lobby_name()
	_lobby_name_label.text = lobby_name
	_lobby_name_label.visible = not is_host
	_lobby_name_edit.visible = is_host
	if not _lobby_name_edit.has_focus():
		_lobby_name_edit.text = lobby_name
	_max_players_option.disabled = not is_host or _is_starting
	PlayerCountOptions.select(_max_players_option, LobbyService.get_max_players())


## L'hôte règle la visibilité et le mot de passe ; les autres voient un résumé.
func _refresh_privacy(is_host: bool) -> void:
	var visibility: LobbyVisibility.Type = LobbyService.get_visibility()
	_visibility_option.visible = is_host
	_visibility_option.disabled = _is_starting
	_visibility_option.select(_visibility_option.get_item_index(visibility))
	_password_edit.visible = is_host
	_password_edit.editable = not _is_starting
	_privacy_label.visible = not is_host
	_privacy_label.text = LobbyVisibility.label(visibility) + ("  ·  Protégé par mot de passe" if LobbyService.has_password() else "")
	_invite_button.disabled = _is_starting


func _describe_ready_status(members: Array[LobbyMember]) -> String:
	if _is_starting:
		return "Lancement de la partie…"
	var unverified: int = LobbyService.get_unverified_count()
	if unverified > 0:
		return "%d joueur%s doi%s saisir le mot de passe" % [unverified, "s" if unverified > 1 else "", "vent" if unverified > 1 else "t"]
	if LobbyService.get_total_players() < GameConfig.MIN_PLAYERS:
		return "Il faut au moins %d joueurs (ajoute un bot)" % GameConfig.MIN_PLAYERS
	var ready_count: int = members.filter(func(member: LobbyMember) -> bool: return member.is_ready).size()
	if not LobbyService.is_local_host() and ready_count == members.size():
		return "Tout le monde est prêt — en attente de l'hôte"
	return "%d / %d prêts" % [ready_count, members.size()]


func _update_start_button(is_host: bool) -> void:
	_start_button.visible = is_host
	_start_button.disabled = _is_starting or not LobbyService.can_start_game()


func _update_ready_button_text(is_ready: bool) -> void:
	_ready_button.text = "Prêt !" if is_ready else "Je suis prêt"


# --- Réactions --------------------------------------------------------------

func _on_leave_pressed() -> void:
	LobbyService.leave_lobby()


func _on_ready_toggled(is_ready: bool) -> void:
	_update_ready_button_text(is_ready)
	LobbyService.set_local_ready(is_ready)


func _on_start_pressed() -> void:
	_start_button.disabled = true
	LobbyService.request_game_start()


func _on_lobby_name_submitted(_text: String) -> void:
	_lobby_name_edit.release_focus()


func _submit_lobby_name() -> void:
	if _lobby_name_edit.text != LobbyService.get_lobby_name():
		LobbyService.rename_lobby(_lobby_name_edit.text)


func _on_max_players_selected(_index: int) -> void:
	LobbyService.set_max_players(PlayerCountOptions.selected_count(_max_players_option))
	_refresh_all()


func _on_visibility_selected(_index: int) -> void:
	LobbyService.set_visibility(LobbyVisibility.selected_in(_visibility_option))


func _on_password_submitted(_text: String) -> void:
	_password_edit.release_focus()


func _submit_password() -> void:
	if _password_edit.text != LobbyService.get_password():
		LobbyService.set_password(_password_edit.text)
		_password_edit.text = LobbyService.get_password()


func _on_password_rejected(attempts_left: int) -> void:
	_password_prompt.show_error("Mot de passe incorrect — %d essai%s restant%s" % [attempts_left, "s" if attempts_left > 1 else "", "s" if attempts_left > 1 else ""])


## La navigation vers le choix de classe se fait quand l'hôte a démarré la partie (MatchService).
func _on_game_start_requested(_lobby_id: int) -> void:
	_is_starting = true
	_ready_button.disabled = true
	_refresh_all()
