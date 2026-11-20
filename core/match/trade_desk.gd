class_name TradeDesk
extends RefCounted
## Offres d'échange en cours pendant une manche : proposition, acceptation, refus, expiration.
## Tout est revérifié au moment de l'acceptation. Une offre dont une carte vient d'être jouée
## est annulée tout de suite (cancel_offers_using_card). Quand une alliance se forme, les autres
## demandes d'alliance qui concernent ces deux joueurs sont refusées (une alliance par manche).
## Un joueur qui a terminé ses combats ne peut plus recevoir d'offre.

signal offer_proposed(offer: TradeOffer)
## reason est vide si l'offre a été acceptée.
signal offer_resolved(offer: TradeOffer, accepted: bool, reason: String)

var _players: Dictionary[int, PlayerState]
var _fields: Dictionary[int, Field]
var _alliances: AllianceRegistry
var _offers: Dictionary[int, TradeOffer] = {}
var _next_id: int = 1


func _init(players: Dictionary[int, PlayerState], fields: Dictionary[int, Field], alliances: AllianceRegistry) -> void:
	_players = players
	_fields = fields
	_alliances = alliances
	_alliances.alliance_formed.connect(_on_alliance_formed)


# --- Lecture ----------------------------------------------------------------

func get_offer(offer_id: int) -> TradeOffer:
	return _offers.get(offer_id)


## Offre en attente envoyée par ce joueur (une seule à la fois), ou null.
func outgoing_offer_of(player_id: int) -> TradeOffer:
	for offer: TradeOffer in _offers.values():
		if offer.from_id == player_id:
			return offer
	return null


func incoming_count_of(player_id: int) -> int:
	var count: int = 0
	for offer: TradeOffer in _offers.values():
		if offer.to_id == player_id:
			count += 1
	return count


# --- Actions ----------------------------------------------------------------

## Renvoie "" si l'offre est envoyée, sinon la raison du refus.
func propose(offer: TradeOffer) -> String:
	var error: String = _get_proposal_error(offer)
	if not error.is_empty():
		return error
	offer.id = _next_id
	_next_id += 1
	offer.remaining_time = CombatConfig.TRADE_OFFER_TIMEOUT
	_offers[offer.id] = offer
	offer_proposed.emit(offer)
	return ""


func accept(offer_id: int, player_id: int) -> String:
	var offer: TradeOffer = get_offer(offer_id)
	if offer == null or offer.to_id != player_id:
		return "Cette offre n'est plus valable."
	var error: String = _get_execution_error(offer)
	if not error.is_empty():
		_resolve(offer, false, error)
		return error
	## Retirée avant l'exécution : l'alliance qu'elle forme ne doit pas l'annuler elle-même.
	_offers.erase(offer.id)
	_execute(offer)
	_resolve(offer, true, "")
	return ""


func decline(offer_id: int, player_id: int) -> void:
	var offer: TradeOffer = get_offer(offer_id)
	if offer and offer.to_id == player_id:
		_resolve(offer, false, "Offre refusée.")


func cancel(offer_id: int, player_id: int) -> void:
	var offer: TradeOffer = get_offer(offer_id)
	if offer and offer.from_id == player_id:
		_resolve(offer, false, "Offre annulée.")


## Annule les offres en attente adressées à ce joueur (ex : il vient de terminer ses combats).
func cancel_offers_to(player_id: int, reason: String) -> void:
	for offer: TradeOffer in _offers.values():
		if offer.to_id == player_id:
			_resolve(offer, false, reason)


## Un joueur vient de jouer `card` : les offres où il devait la donner (proposée par lui, ou
## demandée par l'autre) ne peuvent plus aboutir et sont annulées tout de suite.
func cancel_offers_using_card(player_id: int, card: CardData) -> void:
	for offer: TradeOffer in _offers.values():
		if _is_missing_cards(offer, player_id):
			_resolve(offer, false, "« %s » a été jouée : échange annulé." % card.display_name)


## Les deux joueurs viennent de s'allier : leurs autres offres d'alliance (reçues ou envoyées)
## ne peuvent plus aboutir.
func cancel_alliance_offers_of(first_id: int, second_id: int) -> void:
	for offer: TradeOffer in _offers.values():
		if offer.proposes_alliance and (offer.involves(first_id) or offer.involves(second_id)):
			var allied_id: int = first_id if offer.involves(first_id) else second_id
			_resolve(offer, false, "%s a déjà conclu une alliance." % _players[allied_id].display_name)


func cancel_all(reason: String) -> void:
	for offer: TradeOffer in _offers.values():
		_resolve(offer, false, reason)


func tick(delta: float) -> void:
	for offer: TradeOffer in _offers.values():
		offer.remaining_time -= delta
		if offer.remaining_time <= 0.0:
			_resolve(offer, false, "Offre expirée.")


# --- Vérifications ----------------------------------------------------------

func _get_proposal_error(offer: TradeOffer) -> String:
	if not _players.has(offer.from_id) or not _players.has(offer.to_id):
		return "Joueur introuvable."
	if offer.from_id == offer.to_id:
		return "Impossible d'échanger avec soi-même."
	if offer.is_empty():
		return "L'offre est vide."
	if outgoing_offer_of(offer.from_id):
		return "Tu as déjà une offre en attente."
	if incoming_count_of(offer.to_id) >= CombatConfig.MAX_PENDING_OFFERS_PER_PLAYER:
		return "Ce joueur a déjà %d offres en attente." % CombatConfig.MAX_PENDING_OFFERS_PER_PLAYER
	return _get_execution_error(offer)


func _get_execution_error(offer: TradeOffer) -> String:
	if _fields[offer.to_id].is_finished():
		return "Ce joueur a terminé ses combats."
	var giver: PlayerState = _players[offer.from_id]
	var receiver: PlayerState = _players[offer.to_id]
	if not _contains_all(giver.hand, offer.given_cards):
		return "Les cartes proposées ne sont plus disponibles."
	if not _contains_all(receiver.hand, offer.requested_cards):
		return "Les cartes demandées ne sont plus disponibles."
	if giver.points < offer.given_points or receiver.points < offer.requested_points:
		return "Pas assez de points pour cet échange."
	if offer.proposes_alliance:
		return _alliances.get_formation_error(offer.from_id, offer.to_id)
	return ""


## Vrai si ce joueur fait partie de l'offre et n'a plus en main les cartes qu'il devait donner.
func _is_missing_cards(offer: TradeOffer, player_id: int) -> bool:
	if offer.from_id == player_id:
		return not _contains_all(_players[player_id].hand, offer.given_cards)
	if offer.to_id == player_id:
		return not _contains_all(_players[player_id].hand, offer.requested_cards)
	return false


## Tient compte des doublons : deux exemplaires demandés = deux exemplaires en main.
static func _contains_all(hand: Array[CardData], cards: Array[CardData]) -> bool:
	var remaining: Array[CardData] = hand.duplicate()
	for card: CardData in cards:
		if not remaining.has(card):
			return false
		remaining.erase(card)
	return true


# --- Exécution --------------------------------------------------------------

func _execute(offer: TradeOffer) -> void:
	var giver: PlayerState = _players[offer.from_id]
	var receiver: PlayerState = _players[offer.to_id]
	_transfer_cards(giver, receiver, offer.given_cards)
	_transfer_cards(receiver, giver, offer.requested_cards)
	_transfer_points(giver, receiver, offer.given_points)
	_transfer_points(receiver, giver, offer.requested_points)
	if offer.proposes_alliance:
		_alliances.form(offer.from_id, offer.to_id)


static func _transfer_cards(source: PlayerState, destination: PlayerState, cards: Array[CardData]) -> void:
	for card: CardData in cards:
		source.consume_card(card)
		destination.receive_hand_card(card)


static func _transfer_points(source: PlayerState, destination: PlayerState, amount: int) -> void:
	if amount <= 0:
		return
	source.add_points(-amount)
	destination.add_points(amount)


## L'offre acceptée est déjà retirée quand l'alliance se forme : seules les autres sont touchées.
func _on_alliance_formed(first_id: int, second_id: int) -> void:
	cancel_alliance_offers_of(first_id, second_id)


func _resolve(offer: TradeOffer, accepted: bool, reason: String) -> void:
	_offers.erase(offer.id)
	offer_resolved.emit(offer, accepted, reason)
