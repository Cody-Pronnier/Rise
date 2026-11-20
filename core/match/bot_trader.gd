class_name BotTrader
extends RefCounted
## Comportement d'échange d'un bot :
## - répond aux offres reçues après un court délai (accepte si l'échange lui est favorable) ;
## - propose de temps en temps un échange ou une alliance à un joueur humain.
## Ne tourne que chez l'hôte et ne fait que soumettre des commandes.

const RESPONSE_MIN_DELAY: float = 1.5
const RESPONSE_MAX_DELAY: float = 3.5
const PROPOSAL_MIN_DELAY: float = 25.0
const PROPOSAL_MAX_DELAY: float = 45.0
const ALLIANCE_ACCEPT_CHANCE: float = 0.6
const ALLIANCE_PROPOSAL_CHANCE: float = 0.5
## Valeur d'une carte en points, pour juger un échange.
const CARD_VALUE: int = 3

var _player: PlayerState
var _round: CombatRound
var _submit: Callable
var _pending_responses: Dictionary[int, float] = {}
var _proposal_delay: float = 0.0


func _init(p_player: PlayerState, p_round: CombatRound, submit: Callable) -> void:
	_player = p_player
	_round = p_round
	_submit = submit
	_round.trades.offer_proposed.connect(_on_offer_proposed)
	_schedule_next_proposal()


func tick(delta: float) -> void:
	if _round.is_over:
		return
	_tick_responses(delta)
	_tick_proposal(delta)


# --- Réponses ---------------------------------------------------------------

func _on_offer_proposed(offer: TradeOffer) -> void:
	if offer.to_id == _player.id:
		_pending_responses[offer.id] = randf_range(RESPONSE_MIN_DELAY, RESPONSE_MAX_DELAY)


func _tick_responses(delta: float) -> void:
	for offer_id: int in _pending_responses.keys():
		_pending_responses[offer_id] -= delta
		if _pending_responses[offer_id] <= 0.0:
			_pending_responses.erase(offer_id)
			_respond(offer_id)


func _respond(offer_id: int) -> void:
	var offer: TradeOffer = _round.trades.get_offer(offer_id)
	if offer == null:
		return
	if _likes(offer):
		_submit.call(MatchCommands.accept_trade(_player.id, offer_id))
	else:
		_submit.call(MatchCommands.decline_trade(_player.id, offer_id))


func _likes(offer: TradeOffer) -> bool:
	var gain: int = _value(offer.given_cards, offer.given_points) - _value(offer.requested_cards, offer.requested_points)
	if gain < 0:
		return false
	return randf() < ALLIANCE_ACCEPT_CHANCE if offer.proposes_alliance else true


static func _value(cards: Array[CardData], points: int) -> int:
	return cards.size() * CARD_VALUE + points


# --- Propositions -----------------------------------------------------------

func _schedule_next_proposal() -> void:
	_proposal_delay = randf_range(PROPOSAL_MIN_DELAY, PROPOSAL_MAX_DELAY)


func _tick_proposal(delta: float) -> void:
	_proposal_delay -= delta
	if _proposal_delay > 0.0:
		return
	_schedule_next_proposal()
	var target: PlayerState = _pick_human_target()
	if target:
		_submit.call(MatchCommands.propose_trade(_player.id, _build_offer(target)))


func _pick_human_target() -> PlayerState:
	var humans: Array[PlayerState] = []
	for player: PlayerState in _round.players.values():
		if not player.is_bot and not _round.fields[player.id].is_finished():
			humans.append(player)
	return humans.pick_random() if not humans.is_empty() else null


func _build_offer(target: PlayerState) -> TradeOffer:
	var offer := TradeOffer.new()
	offer.from_id = _player.id
	offer.to_id = target.id
	var can_ally: bool = _round.alliances.get_formation_error(_player.id, target.id).is_empty()
	if can_ally and randf() < ALLIANCE_PROPOSAL_CHANCE:
		offer.proposes_alliance = true
	else:
		_fill_card_swap(offer, target)
	return offer


## Une carte de sa main contre une carte de la main du joueur visé.
func _fill_card_swap(offer: TradeOffer, target: PlayerState) -> void:
	if not _player.hand.is_empty():
		offer.given_cards.append(_player.hand.pick_random())
	if not target.hand.is_empty():
		offer.requested_cards.append(target.hand.pick_random())
