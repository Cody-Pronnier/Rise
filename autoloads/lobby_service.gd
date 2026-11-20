extends Node
## Cycle de vie du salon courant : création, entrée, sortie, membres, état "prêt", lancement,
## réglages de l'hôte (nom, nombre de places, bots, visibilité, mot de passe) et invitations d'amis.
## C'est le seul endroit du jeu qui manipule le salon Steam ; les écrans passent par lui.
## Les bots ne sont pas des membres Steam : leur nombre est stocké dans les données du salon,
## et la limite de membres Steam est réduite d'autant pour qu'aucun humain ne prenne leur place.
## Mot de passe : seul l'hôte le connaît. Un nouvel arrivant publie une preuve (LobbyPassword) que
## l'hôte vérifie (LobbyGatekeeper) ; la réponse et l'éventuel renvoi passent par NetTransport.

signal lobby_created(lobby_id: int)
signal lobby_creation_failed(reason: String)
signal lobby_joined(lobby_id: int)
signal lobby_join_failed(reason: String)
signal lobby_left
signal lobby_data_changed
signal members_changed(members: Array[LobbyMember])
signal member_joined(member_name: String)
signal member_left(member_name: String)
signal game_start_requested(lobby_id: int)
## Le salon rejoint est protégé : l'écran doit demander le mot de passe.
signal password_required
signal password_accepted
signal password_rejected(attempts_left: int)

const MESSAGE_KICK: String = "lobby_kick"
const MESSAGE_PASSWORD_ACCEPTED: String = "lobby_password_accepted"
const MESSAGE_PASSWORD_REJECTED: String = "lobby_password_rejected"
const GATE_CHECK_INTERVAL: float = 1.0

const STEAM_RESULT_OK: int = 1

## Drapeaux EChatMemberStateChange de Steam.
const MEMBER_STATE_ENTERED: int = 1
const MEMBER_STATE_GONE_MASK: int = 2 | 4 | 8 | 16  # left | disconnected | kicked | banned

var current_lobby_id: int = 0

var _pending_lobby_name: String = ""
var _pending_max_players: int = GameConfig.MAX_PLAYERS
var _pending_visibility: LobbyVisibility.Type = LobbyVisibility.Type.PUBLIC
var _pending_password: String = ""
var _game_start_emitted: bool = false
var _gatekeeper := LobbyGatekeeper.new()
## Côté invité : l'hôte a validé notre mot de passe.
var _is_password_accepted: bool = false
var _password_attempt: int = 0
var _was_host: bool = false


func _ready() -> void:
	_connect_steam_signals()
	_connect_gatekeeper()
	_start_gate_timer()
	## Les autres autoloads ne sont pas forcément prêts quand celui-ci l'est.
	_connect_transport.call_deferred()
	_join_lobby_from_command_line.call_deferred()


func _exit_tree() -> void:
	if is_in_lobby():
		Steam.leaveLobby(current_lobby_id)


# --- API publique -----------------------------------------------------------

func is_in_lobby() -> bool:
	return current_lobby_id != 0


func is_local_host() -> bool:
	return is_in_lobby() and Steam.getLobbyOwner(current_lobby_id) == SteamService.local_steam_id


func get_lobby_name() -> String:
	return Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_NAME_KEY)


func get_members() -> Array[LobbyMember]:
	var members: Array[LobbyMember] = []
	if not is_in_lobby():
		return members
	for index: int in Steam.getNumLobbyMembers(current_lobby_id):
		members.append(_build_member(Steam.getLobbyMemberByIndex(current_lobby_id, index)))
	return members


func get_member_ids() -> Array[int]:
	var ids: Array[int] = []
	if not is_in_lobby():
		return ids
	for index: int in Steam.getNumLobbyMembers(current_lobby_id):
		ids.append(Steam.getLobbyMemberByIndex(current_lobby_id, index))
	return ids


func is_member(steam_id: int) -> bool:
	return get_member_ids().has(steam_id)


## Nombre total de places choisi par l'hôte (humains + bots + places libres).
func get_max_players() -> int:
	var value: int = Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_MAX_PLAYERS_KEY).to_int()
	return value if value > 0 else GameConfig.MAX_PLAYERS


func get_bot_count() -> int:
	return Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_BOTS_KEY).to_int()


func get_total_players() -> int:
	return Steam.getNumLobbyMembers(current_lobby_id) + get_bot_count()


func are_all_members_ready() -> bool:
	var members: Array[LobbyMember] = get_members()
	return not members.is_empty() and members.all(func(member: LobbyMember) -> bool: return member.is_ready)


func can_start_game() -> bool:
	return is_local_host() and are_all_members_ready() and get_unverified_count() == 0 and get_total_players() >= GameConfig.MIN_PLAYERS


func get_visibility() -> LobbyVisibility.Type:
	return LobbyVisibility.from_string(Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_VISIBILITY_KEY))


func has_password() -> bool:
	return Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_LOCKED_KEY) == "1"


## Seul l'hôte connaît le mot de passe (vide pour les autres).
func get_password() -> String:
	return _gatekeeper.get_password()


## Hôte : membres qui n'ont pas encore donné le bon mot de passe.
func get_unverified_count() -> int:
	if not is_local_host():
		return 0
	return get_member_ids().filter(func(steam_id: int) -> bool: return not _gatekeeper.is_trusted(steam_id)).size()


## Invité : on attend encore que l'hôte valide notre mot de passe.
func is_awaiting_password() -> bool:
	return is_in_lobby() and not is_local_host() and has_password() and not _is_password_accepted and not _was_invited()


func create_lobby(lobby_name: String, max_players: int = GameConfig.MAX_PLAYERS, visibility: LobbyVisibility.Type = LobbyVisibility.Type.PUBLIC, password: String = "") -> void:
	if not _ensure_steam_ready(lobby_creation_failed):
		return
	leave_lobby()
	_pending_lobby_name = _sanitize_lobby_name(lobby_name)
	_pending_max_players = clampi(max_players, GameConfig.MIN_PLAYERS, GameConfig.MAX_PLAYERS)
	_pending_visibility = visibility
	_pending_password = LobbyPassword.sanitize(password)
	Steam.createLobby(_steam_lobby_type(visibility), _pending_max_players)


# --- Réglages de l'hôte -----------------------------------------------------

func rename_lobby(lobby_name: String) -> void:
	if is_local_host():
		Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_NAME_KEY, _sanitize_lobby_name(lobby_name))


## Impossible de descendre sous le nombre de joueurs et de bots déjà présents.
func set_max_players(max_players: int) -> void:
	if not is_local_host():
		return
	var minimum: int = maxi(GameConfig.MIN_PLAYERS, get_total_players())
	Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_MAX_PLAYERS_KEY, str(clampi(max_players, minimum, GameConfig.MAX_PLAYERS)))
	_apply_member_limit()


func add_bot() -> void:
	if is_local_host() and get_total_players() < get_max_players():
		_set_bot_count(get_bot_count() + 1)


func remove_bot() -> void:
	if is_local_host() and get_bot_count() > 0:
		_set_bot_count(get_bot_count() - 1)


func set_visibility(visibility: LobbyVisibility.Type) -> void:
	if not is_local_host():
		return
	Steam.setLobbyType(current_lobby_id, _steam_lobby_type(visibility))
	Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_VISIBILITY_KEY, str(visibility))


## Mot de passe vide = salon ouvert. Les joueurs déjà présents restent admis.
func set_password(password: String) -> void:
	if not is_local_host():
		return
	var cleaned: String = LobbyPassword.sanitize(password)
	_gatekeeper.set_password(cleaned, get_member_ids())
	Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_LOCKED_KEY, "1" if not cleaned.is_empty() else "")


## Invitation Steam envoyée depuis le jeu. Un ami invité par l'hôte entre sans mot de passe.
func invite_friend(friend_id: int) -> bool:
	if not is_in_lobby() or not Steam.inviteUserToLobby(current_lobby_id, friend_id):
		return false
	if is_local_host():
		_whitelist_friend(friend_id)
	return true


## Fenêtre d'invitation de l'overlay Steam (ces invitations-là demandent le mot de passe).
func open_invite_overlay() -> void:
	if is_in_lobby():
		Steam.activateGameOverlayInviteDialog(current_lobby_id)


## Invité : envoie le mot de passe à l'hôte, sous forme de preuve. Le verdict arrive par
## password_accepted ou password_rejected (ou un renvoi du salon après trop d'essais).
func submit_password(password: String) -> void:
	if not is_in_lobby():
		return
	_password_attempt += 1
	var proof: String = LobbyPassword.proof(current_lobby_id, SteamService.local_steam_id, LobbyPassword.sanitize(password))
	Steam.setLobbyMemberData(current_lobby_id, GameConfig.MEMBER_PASSWORD_PROOF_KEY, "%d:%s" % [_password_attempt, proof])


func join_lobby(lobby_id: int) -> void:
	if not _ensure_steam_ready(lobby_join_failed) or lobby_id == current_lobby_id:
		return
	leave_lobby()
	Steam.joinLobby(lobby_id)


func leave_lobby() -> void:
	if not is_in_lobby():
		return
	Steam.leaveLobby(current_lobby_id)
	_reset_lobby_state()
	lobby_left.emit()


func set_local_ready(is_ready: bool) -> void:
	if not is_in_lobby():
		return
	Steam.setLobbyMemberData(current_lobby_id, GameConfig.MEMBER_READY_KEY, str(is_ready))


## Seul l'hôte peut lancer. Le lancement est diffusé à tous via les données du lobby.
func request_game_start() -> void:
	if not can_start_game():
		return
	Steam.setLobbyJoinable(current_lobby_id, false)
	Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_STATE_KEY, GameConfig.LOBBY_STATE_STARTING)


# --- Connexion aux signaux Steam -------------------------------------------

func _connect_steam_signals() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.persona_state_change.connect(_on_persona_state_change)
	Steam.join_requested.connect(_on_join_requested)


func _connect_gatekeeper() -> void:
	_gatekeeper.accepted.connect(_send_to_member.bind({ "kind": MESSAGE_PASSWORD_ACCEPTED }))
	_gatekeeper.rejected.connect(_on_gatekeeper_rejected)
	_gatekeeper.kick_requested.connect(_on_gatekeeper_kick)


func _connect_transport() -> void:
	NetTransport.message_received.connect(_on_net_message)


func _start_gate_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = GATE_CHECK_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_evaluate_newcomers)
	add_child(timer)


# --- Callbacks Steam --------------------------------------------------------

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != STEAM_RESULT_OK:
		lobby_creation_failed.emit("Steam a refusé la création du salon (code %d)." % result)
		return
	_configure_new_lobby(lobby_id)
	lobby_created.emit(lobby_id)


## Steam déclenche aussi ce callback pour le créateur du salon.
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != LobbyJoinErrors.SUCCESS:
		lobby_join_failed.emit(LobbyJoinErrors.describe(response))
		return
	current_lobby_id = lobby_id
	_game_start_emitted = false
	_was_host = is_local_host()
	lobby_joined.emit(lobby_id)
	_ask_password_if_needed.call_deferred()


func _on_lobby_chat_update(lobby_id: int, changed_id: int, _making_change_id: int, chat_state: int) -> void:
	if lobby_id != current_lobby_id:
		return
	_announce_member_change(changed_id, chat_state)
	_track_member_for_gate(changed_id, chat_state)
	_handle_host_migration()
	_emit_members_changed()


## member_id == lobby_id signifie que ce sont les données du salon (et non d'un joueur) qui ont changé.
func _on_lobby_data_update(success: int, lobby_id: int, member_id: int) -> void:
	if not success or lobby_id != current_lobby_id:
		return
	if member_id == lobby_id:
		_handle_lobby_data_changed()
	else:
		_evaluate_newcomers()
		_emit_members_changed()


## Les pseudos Steam arrivent parfois après l'entrée dans le salon.
func _on_persona_state_change(_steam_id: int, _flags: int) -> void:
	if is_in_lobby():
		_emit_members_changed()


## Invitation acceptée depuis l'overlay Steam pendant que le jeu tourne.
func _on_join_requested(lobby_id: int, _friend_id: int) -> void:
	join_lobby(lobby_id)


# --- Logique interne --------------------------------------------------------

func _configure_new_lobby(lobby_id: int) -> void:
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, GameConfig.LOBBY_NAME_KEY, _pending_lobby_name)
	Steam.setLobbyData(lobby_id, GameConfig.LOBBY_GAME_TAG_KEY, GameConfig.LOBBY_GAME_TAG_VALUE)
	Steam.setLobbyData(lobby_id, GameConfig.LOBBY_MAX_PLAYERS_KEY, str(_pending_max_players))
	Steam.setLobbyData(lobby_id, GameConfig.LOBBY_BOTS_KEY, "0")
	Steam.setLobbyData(lobby_id, GameConfig.LOBBY_VISIBILITY_KEY, str(_pending_visibility))
	current_lobby_id = lobby_id
	set_password(_pending_password)
	_pending_password = ""


func _steam_lobby_type(visibility: LobbyVisibility.Type) -> int:
	match visibility:
		LobbyVisibility.Type.FRIENDS:
			return Steam.LOBBY_TYPE_FRIENDS_ONLY
		LobbyVisibility.Type.PRIVATE:
			return Steam.LOBBY_TYPE_PRIVATE
		_:
			return Steam.LOBBY_TYPE_PUBLIC


# --- Mot de passe -----------------------------------------------------------

func _whitelist_friend(friend_id: int) -> void:
	_gatekeeper.trust(friend_id)
	var invited: PackedStringArray = _invited_ids()
	if not invited.has(str(friend_id)):
		invited.append(str(friend_id))
		Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_INVITED_KEY, ",".join(invited))


func _invited_ids() -> PackedStringArray:
	return Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_INVITED_KEY).split(",", false)


func _was_invited() -> bool:
	return _invited_ids().has(str(SteamService.local_steam_id))


func _ask_password_if_needed() -> void:
	if is_awaiting_password():
		password_required.emit()


## Hôte : examine les preuves des nouveaux venus (et renvoie ceux qui traînent trop).
func _evaluate_newcomers() -> void:
	if not is_local_host() or not _gatekeeper.has_password():
		return
	var proofs: Dictionary[int, String] = {}
	for steam_id: int in get_member_ids():
		proofs[steam_id] = Steam.getLobbyMemberData(current_lobby_id, steam_id, GameConfig.MEMBER_PASSWORD_PROOF_KEY)
	_gatekeeper.evaluate(current_lobby_id, proofs, _now())


func _track_member_for_gate(steam_id: int, chat_state: int) -> void:
	if chat_state & MEMBER_STATE_ENTERED:
		_gatekeeper.on_member_entered(steam_id, _now())
	elif chat_state & MEMBER_STATE_GONE_MASK:
		_gatekeeper.forget(steam_id)


## Nouvel hôte après le départ de l'ancien : il ne connaît pas le mot de passe, il le retire.
func _handle_host_migration() -> void:
	var is_host_now: bool = is_local_host()
	if is_host_now and not _was_host and has_password() and not _gatekeeper.has_password():
		Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_LOCKED_KEY, "")
	_was_host = is_host_now


func _send_to_member(steam_id: int, message: Dictionary) -> void:
	NetTransport.send(steam_id, message)


func _on_gatekeeper_rejected(steam_id: int, attempts_left: int) -> void:
	_send_to_member(steam_id, { "kind": MESSAGE_PASSWORD_REJECTED, "attempts_left": attempts_left })


func _on_gatekeeper_kick(steam_id: int, reason: String) -> void:
	_send_to_member(steam_id, { "kind": MESSAGE_KICK, "reason": reason })


## Seuls les messages de l'hôte du salon sont pris en compte.
func _on_net_message(sender_id: int, message: Dictionary) -> void:
	if not is_in_lobby() or sender_id != Steam.getLobbyOwner(current_lobby_id):
		return
	match message.get("kind", ""):
		MESSAGE_PASSWORD_ACCEPTED:
			_is_password_accepted = true
			password_accepted.emit()
		MESSAGE_PASSWORD_REJECTED:
			password_rejected.emit(int(message.get("attempts_left", 0)))
		MESSAGE_KICK:
			leave_lobby()
			lobby_join_failed.emit(str(message.get("reason", "Tu as été renvoyé du salon.")))


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _set_bot_count(bot_count: int) -> void:
	Steam.setLobbyData(current_lobby_id, GameConfig.LOBBY_BOTS_KEY, str(bot_count))
	_apply_member_limit()


## Places Steam = places totales - bots (jamais moins que les humains déjà là).
func _apply_member_limit() -> void:
	var human_slots: int = maxi(get_max_players() - get_bot_count(), Steam.getNumLobbyMembers(current_lobby_id))
	Steam.setLobbyMemberLimit(current_lobby_id, human_slots)


func _handle_lobby_data_changed() -> void:
	lobby_data_changed.emit()
	_emit_game_start_if_requested()


func _emit_game_start_if_requested() -> void:
	if _game_start_emitted or not _is_lobby_starting():
		return
	_game_start_emitted = true
	game_start_requested.emit(current_lobby_id)


func _is_lobby_starting() -> bool:
	return Steam.getLobbyData(current_lobby_id, GameConfig.LOBBY_STATE_KEY) == GameConfig.LOBBY_STATE_STARTING


func _emit_members_changed() -> void:
	members_changed.emit(get_members())


func _announce_member_change(steam_id: int, chat_state: int) -> void:
	var member_name: String = SteamService.get_persona_name(steam_id)
	if chat_state & MEMBER_STATE_ENTERED:
		member_joined.emit(member_name)
	elif chat_state & MEMBER_STATE_GONE_MASK:
		member_left.emit(member_name)


func _build_member(steam_id: int) -> LobbyMember:
	return LobbyMember.new(
		steam_id,
		SteamService.get_persona_name(steam_id),
		steam_id == Steam.getLobbyOwner(current_lobby_id),
		_is_member_ready(steam_id)
	)


func _is_member_ready(steam_id: int) -> bool:
	return Steam.getLobbyMemberData(current_lobby_id, steam_id, GameConfig.MEMBER_READY_KEY) == str(true)


func _sanitize_lobby_name(lobby_name: String) -> String:
	var cleaned: String = lobby_name.strip_edges().left(GameConfig.MAX_LOBBY_NAME_LENGTH)
	if cleaned.is_empty():
		return "Salon de %s" % SteamService.local_persona_name
	return cleaned


func _reset_lobby_state() -> void:
	current_lobby_id = 0
	_game_start_emitted = false
	_gatekeeper.reset()
	_is_password_accepted = false
	_password_attempt = 0
	_was_host = false


func _ensure_steam_ready(failure_signal: Signal) -> bool:
	if SteamService.is_ready:
		return true
	failure_signal.emit("Steam n'est pas disponible : %s" % SteamService.init_error)
	return false


## Lancement du jeu via une invitation Steam alors qu'il était fermé : "+connect_lobby <id>".
func _join_lobby_from_command_line() -> void:
	var lobby_id: int = _read_lobby_id_from_command_line()
	if lobby_id != 0:
		join_lobby(lobby_id)


func _read_lobby_id_from_command_line() -> int:
	var args: PackedStringArray = OS.get_cmdline_args()
	var index: int = args.find("+connect_lobby")
	if index == -1 or index + 1 >= args.size():
		return 0
	return args[index + 1].to_int()
