class_name MatchSession
extends RefCounted
## État complet d'une partie, piloté uniquement par des commandes (MatchCommands).
## Chaque machine possède sa propre MatchSession et lui applique les mêmes commandes dans le même
## ordre, puis la fait avancer du même pas de temps : toutes restent identiques.
## Aucune décision ici : les bots, les minuteries et l'enchaînement des phases sont dans HostDirector.

signal class_selection_started
signal class_locked(player_id: int)
signal round_started(round_index: int)
signal reward_phase_started
signal match_finished
## Une action d'un joueur a été refusée (seul ce joueur a besoin du message).
signal action_failed(player_id: int, message: String)

enum Phase { NONE, CLASS_SELECTION, ROUND, RESULTS, REWARDS, FINISHED }

var phase: Phase = Phase.NONE
var round_index: int = 0
var players: Array[PlayerState] = []
var current_round: CombatRound
var current_rewards: RewardPhase
## Pendant le choix de classe : [{ "id", "name", "bot" }].
var selection_players: Array = []
var selection_duration: float = 0.0

var _locked_players: Dictionary[int, bool] = {}


# --- Lecture ----------------------------------------------------------------

func get_player(player_id: int) -> PlayerState:
	for player: PlayerState in players:
		if player.id == player_id:
			return player
	return null


func is_last_round() -> bool:
	return round_index >= CombatConfig.MAX_ROUNDS - 1


func is_class_locked(player_id: int) -> bool:
	return _locked_players.has(player_id)


func locked_count() -> int:
	return _locked_players.size()


# --- Avancement -------------------------------------------------------------

func step(delta: float) -> void:
	if phase == Phase.ROUND:
		current_round.tick(delta)


func apply(command: Dictionary) -> void:
	match command.get(MatchCommands.TYPE, ""):
		MatchCommands.BEGIN_CLASS_SELECTION:
			_begin_class_selection(command)
		MatchCommands.CLASS_LOCKED:
			_lock_class(command)
		MatchCommands.START_MATCH:
			_start_match(command)
		MatchCommands.START_ROUND:
			_start_round(command.get("round", 0))
		MatchCommands.START_REWARDS:
			_start_rewards()
		MatchCommands.END_MATCH:
			_end_match()
		MatchCommands.PLAY_CARD:
			_play_card(command)
		MatchCommands.USE_ABILITY:
			_use_ability(command)
		MatchCommands.PROPOSE_TRADE:
			_propose_trade(command)
		MatchCommands.ACCEPT_TRADE:
			_accept_trade(command)
		MatchCommands.DECLINE_TRADE:
			_with_round(func() -> void: current_round.trades.decline(command.get("offer", -1), command.get("player", -1)))
		MatchCommands.CANCEL_TRADE:
			_with_round(func() -> void: current_round.trades.cancel(command.get("offer", -1), command.get("player", -1)))
		MatchCommands.BREAK_ALLIANCE:
			_break_alliance(command)
		MatchCommands.BUY_CARD:
			_with_rewards(func() -> void: _report(command.get("player", -1), current_rewards.buy(command.get("player", -1), command.get("index", -1))))
		MatchCommands.REWARDS_READY:
			_with_rewards(func() -> void: _report(command.get("player", -1), current_rewards.set_ready(command.get("player", -1), command.get("keep", []))))
		MatchCommands.DRAFT_PICK:
			_draft_pick(command)


# --- Déroulé ----------------------------------------------------------------

func _begin_class_selection(command: Dictionary) -> void:
	phase = Phase.CLASS_SELECTION
	selection_players = command.get("players", [])
	selection_duration = command.get("duration", 0.0)
	_locked_players.clear()
	class_selection_started.emit()


func _lock_class(command: Dictionary) -> void:
	var player_id: int = command.get("player", -1)
	_locked_players[player_id] = true
	class_locked.emit(player_id)


func _start_match(command: Dictionary) -> void:
	GameRandom.set_seed(command.get("seed", 0))
	players = _build_players(command.get("players", []))
	_start_round(0)


func _build_players(specs: Array) -> Array[PlayerState]:
	var built: Array[PlayerState] = []
	for spec: Dictionary in specs:
		var class_data: ClassData = ClassCatalog.find(spec["class"])
		var deck: Array[CardData] = DeckRules.resolve_deck(class_data, spec.get("deck", []))
		built.append(PlayerState.new(spec["id"], spec["name"], class_data, spec["bot"], deck))
	return built


func _start_round(index: int) -> void:
	round_index = index
	current_rewards = null
	current_round = CombatRound.new(index, players)
	current_round.round_finished.connect(_on_round_finished)
	phase = Phase.ROUND
	round_started.emit(index)


func _on_round_finished(_results: Array[RoundResult]) -> void:
	phase = Phase.RESULTS


func _start_rewards() -> void:
	if phase != Phase.RESULTS:
		return
	var podium: Array[int] = current_round.get_top_finishers(CombatConfig.PODIUM_SIZE)
	current_rewards = RewardPhase.new(players, podium)
	phase = Phase.REWARDS
	reward_phase_started.emit()
	current_rewards.start()


func _end_match() -> void:
	phase = Phase.FINISHED
	match_finished.emit()


# --- Actions des joueurs ----------------------------------------------------

func _play_card(command: Dictionary) -> void:
	if phase != Phase.ROUND:
		return
	var player_id: int = command.get("player", -1)
	var player: PlayerState = get_player(player_id)
	var card: CardData = _find_card(player.hand, command.get("card", &"")) if player else null
	if card == null:
		_fail(player_id, "Tu n'as plus cette carte.")
		return
	var target_id: int = command.get("target", -1)
	var field: Field = current_round.fields.get(target_id)
	var unit: CombatUnit = field.unit_from_ref(command.get("unit", "")) if field else null
	_report(player_id, current_round.play_card(player_id, card, CardTarget.new(target_id, unit)))


func _use_ability(command: Dictionary) -> void:
	if phase != Phase.ROUND:
		return
	var player_id: int = command.get("player", -1)
	_report(player_id, current_round.use_ability(player_id))


func _propose_trade(command: Dictionary) -> void:
	if phase != Phase.ROUND:
		return
	var player_id: int = command.get("player", -1)
	var receiver: PlayerState = get_player(command.get("to", -1))
	var giver: PlayerState = get_player(player_id)
	if giver == null or receiver == null:
		_fail(player_id, "Joueur introuvable.")
		return
	var offer := TradeOffer.new()
	offer.from_id = player_id
	offer.to_id = receiver.id
	offer.given_cards = _find_cards(giver.hand, command.get("give", []))
	offer.requested_cards = _find_cards(receiver.hand, command.get("ask", []))
	offer.given_points = command.get("give_points", 0)
	offer.requested_points = command.get("ask_points", 0)
	offer.proposes_alliance = command.get("alliance", false)
	if offer.given_cards.size() != command.get("give", []).size() or offer.requested_cards.size() != command.get("ask", []).size():
		_fail(player_id, "Les cartes de l'échange ne sont plus disponibles.")
		return
	_report(player_id, current_round.trades.propose(offer))


func _accept_trade(command: Dictionary) -> void:
	if phase != Phase.ROUND:
		return
	var player_id: int = command.get("player", -1)
	_report(player_id, current_round.trades.accept(command.get("offer", -1), player_id))


func _break_alliance(command: Dictionary) -> void:
	if phase != Phase.ROUND:
		return
	var player_id: int = command.get("player", -1)
	_report(player_id, current_round.break_alliance(player_id))


func _draft_pick(command: Dictionary) -> void:
	if phase != Phase.REWARDS:
		return
	var player_id: int = command.get("player", -1)
	var index: int = command.get("index", -1)
	var offer: Array[CardData] = current_rewards.draft.get_offer()
	if index < 0 or index >= offer.size():
		_fail(player_id, "Carte invalide.")
		return
	_report(player_id, current_rewards.draft_pick(player_id, offer[index]))


# --- Outils -----------------------------------------------------------------

func _with_round(action: Callable) -> void:
	if phase == Phase.ROUND:
		action.call()


func _with_rewards(action: Callable) -> void:
	if phase == Phase.REWARDS:
		action.call()


func _report(player_id: int, error: String) -> void:
	if not error.is_empty():
		_fail(player_id, error)


func _fail(player_id: int, message: String) -> void:
	action_failed.emit(player_id, message)


static func _find_card(hand: Array[CardData], card_id: StringName) -> CardData:
	for card: CardData in hand:
		if card.id == card_id:
			return card
	return null


## Retrouve chaque id dans la main, un exemplaire distinct par id (doublons possibles).
static func _find_cards(hand: Array[CardData], card_ids: Array) -> Array[CardData]:
	var remaining: Array[CardData] = hand.duplicate()
	var found: Array[CardData] = []
	for card_id: StringName in card_ids:
		var card: CardData = _find_card(remaining, card_id)
		if card:
			remaining.erase(card)
			found.append(card)
	return found

