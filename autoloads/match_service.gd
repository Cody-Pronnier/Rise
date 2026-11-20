extends Node
## Fait vivre la partie : boucle à pas fixe, commandes, réseau.
## Trois rôles :
## - OFFLINE : entraînement ; on est son propre hôte, sans réseau ;
## - HOST : on décide de l'ordre des commandes et on les diffuse à chaque image ;
## - CLIENT : on envoie ses actions à l'hôte et on applique les images qu'il diffuse.
## Toutes les machines appliquent les mêmes commandes dans le même ordre à la même MatchSession.
## L'UI ne parle qu'à ce service ; les actions du joueur sont asynchrones
## (un refus arrive plus tard via action_failed).

signal class_selection_started
signal round_started(round_index: int)
signal reward_phase_started
signal match_finished
## reason est vide quand le joueur quitte volontairement.
signal match_ended(reason: String)
signal action_failed(message: String)

enum Role { NONE, OFFLINE, HOST, CLIENT }

const TICK_RATE: int = 20
const TICK_DELTA: float = 1.0 / TICK_RATE
## Sécurité anti-spirale si le jeu a gelé un moment.
const MAX_TICKS_PER_FRAME: int = 10
## Au-delà, un client considère que l'hôte est parti.
const HOST_TIMEOUT: float = 10.0
## L'hôte attend que les clients soient prêts avant de commencer, au plus ce délai.
const HELLO_TIMEOUT: float = 15.0
const DEFAULT_PLAYER_NAME: String = "Toi"

const MESSAGE_HELLO: String = "hello"
const MESSAGE_REQUEST: String = "request"
const MESSAGE_FRAME: String = "frame"

var role: Role = Role.NONE
var local_player_id: int = 0
var session: MatchSession

var current_round: CombatRound:
	get: return session.current_round if session else null
var current_rewards: RewardPhase:
	get: return session.current_rewards if session else null
var round_index: int:
	get: return session.round_index if session else 0

var _director: HostDirector
var _host_id: int = 0
var _accumulator: float = 0.0
var _pending_commands: Array[Dictionary] = []
var _incoming_frames: Array[Dictionary] = []
var _time_since_host_frame: float = 0.0
var _waiting_clients: Dictionary[int, bool] = {}
var _hello_time_left: float = 0.0
var _pending_specs: Array[Dictionary] = []


func _ready() -> void:
	set_process(false)
	NetTransport.message_received.connect(_on_net_message)


func _process(delta: float) -> void:
	match role:
		Role.OFFLINE, Role.HOST:
			_process_host(delta)
		Role.CLIENT:
			_process_client(delta)


# --- Lecture ----------------------------------------------------------------

func is_in_match() -> bool:
	return role != Role.NONE


func is_online() -> bool:
	return role == Role.HOST or role == Role.CLIENT


## Vrai chez l'hôte et en entraînement : c'est nous qui faisons avancer les phases.
func has_authority() -> bool:
	return role == Role.HOST or role == Role.OFFLINE


func is_last_round() -> bool:
	return session != null and session.is_last_round()


func get_local_player() -> PlayerState:
	return session.get_player(local_player_id) if session else null


# --- Démarrage --------------------------------------------------------------

## deck_ids : ids du deck choisi (vide = deck de base).
func start_local_match(class_id: StringName, deck_ids: Array[StringName] = []) -> void:
	_start_session(Role.OFFLINE, 0)
	_director.start_match(LocalMatchFactory.create_training_specs(local_player_id, _local_player_name(), class_id, deck_ids))


## Appelé chez tous les membres quand l'hôte lance la partie depuis le salon.
func start_online_match(lobby_id: int) -> void:
	_host_id = Steam.getLobbyOwner(lobby_id)
	var is_host: bool = _host_id == SteamService.local_steam_id
	_start_session(Role.HOST if is_host else Role.CLIENT, SteamService.local_steam_id)
	if is_host:
		_wait_for_clients(LobbyService.get_members(), LobbyService.get_bot_count())
	else:
		NetTransport.send(_host_id, { "kind": MESSAGE_HELLO })


func _start_session(new_role: Role, local_id: int) -> void:
	_reset()
	role = new_role
	local_player_id = local_id
	session = MatchSession.new()
	_connect_session()
	if has_authority():
		_director = HostDirector.new(session, _queue_command)
	set_process(true)


func _connect_session() -> void:
	session.class_selection_started.connect(class_selection_started.emit)
	session.round_started.connect(round_started.emit)
	session.reward_phase_started.connect(reward_phase_started.emit)
	session.match_finished.connect(match_finished.emit)
	session.action_failed.connect(_on_action_failed)


func _wait_for_clients(members: Array[LobbyMember], bot_count: int) -> void:
	_pending_specs = LocalMatchFactory.create_online_specs(members, bot_count)
	_hello_time_left = HELLO_TIMEOUT
	for member: LobbyMember in members:
		if member.steam_id != local_player_id:
			_waiting_clients[member.steam_id] = true
	_begin_class_selection_if_ready()


func _begin_class_selection_if_ready() -> void:
	if _pending_specs.is_empty() or (not _waiting_clients.is_empty() and _hello_time_left > 0.0):
		return
	_director.begin_class_selection(_pending_specs)
	_pending_specs = []


# --- Actions du joueur local ------------------------------------------------

func play_card(card: CardData, target: CardTarget) -> void:
	var field: Field = current_round.fields.get(target.player_id) if current_round else null
	if field:
		_submit_local(MatchCommands.play_card(local_player_id, card, target, field))


## Capacité de la classe du joueur local (ex : recruter un mercenaire).
func use_class_ability() -> void:
	_submit_local(MatchCommands.use_ability(local_player_id))


func propose_trade(offer: TradeOffer) -> void:
	_submit_local(MatchCommands.propose_trade(local_player_id, offer))


func accept_trade(offer_id: int) -> void:
	_submit_local(MatchCommands.accept_trade(local_player_id, offer_id))


func decline_trade(offer_id: int) -> void:
	_submit_local(MatchCommands.decline_trade(local_player_id, offer_id))


func cancel_trade(offer_id: int) -> void:
	_submit_local(MatchCommands.cancel_trade(local_player_id, offer_id))


func break_alliance() -> void:
	_submit_local(MatchCommands.break_alliance(local_player_id))


## Achat de la carte n° index de sa boutique.
func buy_shop_card(index: int) -> void:
	_submit_local(MatchCommands.buy_card(local_player_id, index))


## keep_indices : positions des cartes gardées parmi celles tirées de son deck.
func set_rewards_ready(keep_indices: Array[int]) -> void:
	_submit_local(MatchCommands.rewards_ready(local_player_id, keep_indices))


func draft_podium_card(card: CardData) -> void:
	if current_rewards:
		_submit_local(MatchCommands.draft_pick(local_player_id, current_rewards.draft.get_offer().find(card)))


## Choix de classe secret : envoyé à l'hôte seulement.
func choose_class(class_id: StringName, deck_ids: Array[StringName] = []) -> void:
	if has_authority():
		_director.receive_class_choice(local_player_id, class_id, deck_ids)
	else:
		NetTransport.send(_host_id, { "kind": MESSAGE_REQUEST, "command": MatchCommands.choose_class(local_player_id, class_id, deck_ids) })


## Bouton « Continuer » des résultats (hôte et entraînement uniquement).
func continue_after_round() -> void:
	if has_authority():
		_director.request_continue()


func leave_match() -> void:
	var was_online: bool = is_online()
	_reset()
	if was_online:
		NetTransport.close_all_sessions()
		LobbyService.leave_lobby()
	match_ended.emit("")


# --- Hôte -------------------------------------------------------------------

func _process_host(delta: float) -> void:
	if not _pending_specs.is_empty():
		_hello_time_left -= delta
		_begin_class_selection_if_ready()
	_accumulator += delta
	var ticks: int = 0
	while _accumulator >= TICK_DELTA and ticks < MAX_TICKS_PER_FRAME and role != Role.NONE:
		_accumulator -= TICK_DELTA
		ticks += 1
		_run_host_tick()


## Une image : l'hôte décide (bots, minuteries), puis applique et diffuse les commandes de l'image.
func _run_host_tick() -> void:
	_director.tick(TICK_DELTA)
	var frame: Dictionary = { "commands": _pending_commands }
	_pending_commands = []
	if role == Role.HOST:
		NetTransport.broadcast({ "kind": MESSAGE_FRAME, "frame": frame })
	_apply_frame(frame)


func _queue_command(command: Dictionary) -> void:
	_pending_commands.append(command)


## Requête d'un client : on remplace l'auteur par l'expéditeur réel (anti-triche).
func _handle_client_request(sender_id: int, command: Dictionary) -> void:
	command["player"] = sender_id
	if command.get(MatchCommands.TYPE, "") == MatchCommands.CHOOSE_CLASS:
		_director.receive_class_choice(sender_id, command.get("class", &""), command.get("deck", []))
	elif MatchCommands.is_player_action(command):
		_queue_command(command)


func _handle_client_hello(sender_id: int) -> void:
	_waiting_clients.erase(sender_id)
	_begin_class_selection_if_ready()


# --- Client -----------------------------------------------------------------

func _process_client(delta: float) -> void:
	_time_since_host_frame += delta
	if _time_since_host_frame > HOST_TIMEOUT:
		_end_with_error("L'hôte ne répond plus. La partie est terminée.")
		return
	while not _incoming_frames.is_empty() and role == Role.CLIENT:
		_apply_frame(_incoming_frames.pop_front())


# --- Commun -----------------------------------------------------------------

func _apply_frame(frame: Dictionary) -> void:
	for command: Dictionary in frame.get("commands", []):
		session.apply(command)
	session.step(TICK_DELTA)


func _submit_local(command: Dictionary) -> void:
	if not is_in_match():
		return
	if has_authority():
		_queue_command(command)
	else:
		NetTransport.send(_host_id, { "kind": MESSAGE_REQUEST, "command": command })


func _on_net_message(sender_id: int, message: Dictionary) -> void:
	match message.get("kind", ""):
		MESSAGE_FRAME:
			if role == Role.CLIENT and sender_id == _host_id:
				_incoming_frames.append(message.get("frame", {}))
				_time_since_host_frame = 0.0
		MESSAGE_REQUEST:
			if role == Role.HOST and LobbyService.is_member(sender_id):
				_handle_client_request(sender_id, message.get("command", {}))
		MESSAGE_HELLO:
			if role == Role.HOST:
				_handle_client_hello(sender_id)


func _on_action_failed(player_id: int, message: String) -> void:
	if player_id == local_player_id:
		action_failed.emit(message)


func _end_with_error(reason: String) -> void:
	_reset()
	NetTransport.close_all_sessions()
	LobbyService.leave_lobby()
	match_ended.emit(reason)


func _reset() -> void:
	set_process(false)
	role = Role.NONE
	session = null
	_director = null
	_accumulator = 0.0
	_pending_commands = []
	_incoming_frames = []
	_time_since_host_frame = 0.0
	_waiting_clients.clear()
	_pending_specs = []


func _local_player_name() -> String:
	if SteamService.is_ready:
		return SteamService.local_persona_name
	return DEFAULT_PLAYER_NAME
