class_name BotTrader
extends RefCounted
## Comportement social d'un bot, envers les humains comme envers les autres bots :
## - répond aux offres reçues après un court délai ;
## - propose de temps en temps une alliance ou un échange de cartes.
## Les cartes sont jugées avec BotCardScorer (ce qu'elles rapporteraient à chacun maintenant),
## les alliances avec le classement en direct (les points sont partagés en fin de manche).
## Ne tourne que chez l'hôte et ne fait que soumettre des commandes.

const RESPONSE_MIN_DELAY: float = 1.5
const RESPONSE_MAX_DELAY: float = 3.5
const PROPOSAL_MIN_DELAY: float = 15.0
const PROPOSAL_MAX_DELAY: float = 30.0
## Alliance reçue : acceptée si celui qui la propose est devant soi ; s'il est juste derrière,
## acceptée une fois sur ALLIANCE_ACCEPT_BEHIND_CHANCE (partager ses points avec plus faible coûte).
const ALLIANCE_ACCEPT_BEHIND_CHANCE: float = 0.35
## Un bot ne propose d'alliance qu'à partir de cette place (en tête, il partagerait ses points).
const ALLIANCE_MIN_POSITION: int = 4
const ALLIANCE_PROPOSAL_CHANCE: float = 0.4
## Un échange doit rapporter au moins ça au bot (en dégâts équivalents) pour qu'il le propose.
const MIN_TRADE_GAIN: float = 5.0
## Pour ne pas inonder un humain d'offres : chance qu'un bot envisage les humains à chaque proposition.
const HUMAN_OFFER_CHANCE: float = 0.35

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
	if _round.is_over or _round.fields[_player.id].is_finished():
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
	if offer.proposes_alliance and not _likes_alliance_with(offer.from_id):
		return false
	var received: float = _value_for(_player, offer.given_cards, offer.given_points)
	var given: float = _value_for(_player, offer.requested_cards, offer.requested_points)
	return received >= given


## Points partagés en fin de manche : s'allier à quelqu'un devant soi est rentable,
## à quelqu'un juste derrière parfois (on gagne un allié qui ne nous attaquera plus).
func _likes_alliance_with(proposer_id: int) -> bool:
	var gap: int = _position_of(proposer_id) - _position_of(_player.id)
	if gap < 0:
		return true
	return gap == 1 and randf() < ALLIANCE_ACCEPT_BEHIND_CHANCE


# --- Propositions -----------------------------------------------------------

func _schedule_next_proposal() -> void:
	_proposal_delay = randf_range(PROPOSAL_MIN_DELAY, PROPOSAL_MAX_DELAY)


func _tick_proposal(delta: float) -> void:
	_proposal_delay -= delta
	if _proposal_delay > 0.0:
		return
	_schedule_next_proposal()
	if _round.trades.outgoing_offer_of(_player.id):
		return
	var include_humans: bool = randf() < HUMAN_OFFER_CHANCE
	var offer: TradeOffer = _pick_alliance_offer(include_humans) if randf() < ALLIANCE_PROPOSAL_CHANCE else null
	if offer == null:
		offer = _pick_card_swap(include_humans)
	if offer:
		_submit.call(MatchCommands.propose_trade(_player.id, offer))


## Alliance avec le joueur le plus proche devant soi, quand on n'est pas en tête.
func _pick_alliance_offer(include_humans: bool) -> TradeOffer:
	var my_position: int = _position_of(_player.id)
	if my_position < ALLIANCE_MIN_POSITION:
		return null
	var order: Array[int] = RoundRanking.order(_round)
	for index: int in range(my_position - 2, -1, -1):
		var candidate_id: int = order[index]
		if _can_receive_offer(candidate_id, include_humans) and _round.alliances.get_formation_error(_player.id, candidate_id).is_empty():
			var offer: TradeOffer = _new_offer(candidate_id)
			offer.proposes_alliance = true
			return offer
	return null


## Le meilleur échange une carte contre une carte que l'autre joueur devrait accepter :
## la carte reçue vaut plus pour le bot que celle donnée, et l'inverse pour l'autre joueur.
func _pick_card_swap(include_humans: bool) -> TradeOffer:
	var best_gain: float = MIN_TRADE_GAIN
	var best_offer: TradeOffer = null
	var my_values: Dictionary[CardData, float] = _hand_values(_player, _player.hand)
	for other: PlayerState in _round.players.values():
		if other == _player or not _can_receive_offer(other.id, include_humans) or other.hand.is_empty():
			continue
		var their_hand_for_me: Dictionary[CardData, float] = _hand_values(_player, other.hand)
		var their_hand_for_them: Dictionary[CardData, float] = _hand_values(other, other.hand)
		var my_hand_for_them: Dictionary[CardData, float] = _hand_values(other, _player.hand)
		for wanted: CardData in other.hand:
			for given: CardData in _player.hand:
				if wanted.id == given.id:
					continue
				var gain: float = their_hand_for_me[wanted] - my_values[given]
				var they_agree: bool = my_hand_for_them[given] >= their_hand_for_them[wanted]
				if gain > best_gain and they_agree:
					best_gain = gain
					best_offer = _swap_offer(other.id, given, wanted)
	return best_offer


func _swap_offer(target_id: int, given: CardData, wanted: CardData) -> TradeOffer:
	var offer: TradeOffer = _new_offer(target_id)
	offer.given_cards.append(given)
	offer.requested_cards.append(wanted)
	return offer


func _new_offer(target_id: int) -> TradeOffer:
	var offer := TradeOffer.new()
	offer.from_id = _player.id
	offer.to_id = target_id
	return offer


# --- Outils -----------------------------------------------------------------

func _can_receive_offer(player_id: int, include_humans: bool) -> bool:
	if not include_humans and not _round.players[player_id].is_bot:
		return false
	return player_id != _player.id and not _round.fields[player_id].is_finished() \
		and _round.trades.incoming_count_of(player_id) < CombatConfig.MAX_PENDING_OFFERS_PER_PLAYER


func _position_of(player_id: int) -> int:
	return RoundRanking.position_of(_round, player_id)


## Valeur d'un lot (cartes + points) pour un joueur donné.
func _value_for(player: PlayerState, cards: Array[CardData], points: int) -> float:
	var total: float = points * BotCardScorer.POINT_VALUE
	for card: CardData in cards:
		total += BotCardScorer.best_value(card, _round, player)
	return total


func _hand_values(player: PlayerState, hand: Array[CardData]) -> Dictionary[CardData, float]:
	var values: Dictionary[CardData, float] = {}
	for card: CardData in hand:
		if not values.has(card):
			values[card] = BotCardScorer.best_value(card, _round, player)
	return values
