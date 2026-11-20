class_name RewardPhase
extends RefCounted
## Phase entre deux manches :
## - chaque joueur tire DECK_CARDS_OFFERED cartes de la suite de son deck et en garde DECK_CARDS_KEPT
##   (le reste est défaussé) : son choix est envoyé avec « Prêt » ;
## - une boutique lui propose quelques cartes à acheter avec ses points (MAX_SHOP_PURCHASES par partie) ;
## - le podium se partage des cartes uniques via un PodiumDraft ;
## - chacun valide quand il est prêt. La phase est finie quand tout le monde est prêt et le draft terminé.
## Le tirage (déblocage, boutique, podium) utilise GameRandom : identique sur toutes les machines.

signal player_ready(player_id: int)
signal shop_changed(player_id: int)
signal draft_turn_changed(picker_id: int)
signal completed

var draft: PodiumDraft

var _players: Dictionary[int, PlayerState] = {}
var _deck_offers: Dictionary[int, Array] = {}
var _shop_offers: Dictionary[int, Array] = {}
var _bought: Dictionary[int, Array] = {}
var _ready: Dictionary[int, bool] = {}
var _is_completed: bool = false


func _init(players: Array[PlayerState], podium: Array[int]) -> void:
	for player: PlayerState in players:
		_players[player.id] = player
		_deck_offers[player.id] = player.draw_locked_cards(CombatConfig.DECK_CARDS_OFFERED)
		_shop_offers[player.id] = RewardGenerator.shop_offer(player.class_data, CombatConfig.SHOP_OFFER_SIZE)
		_bought[player.id] = []
	draft = PodiumDraft.new(podium, PodiumCards.draw(podium.size()))
	draft.picked.connect(_on_draft_picked)


## À appeler après avoir connecté les signaux.
func start() -> void:
	draft.start()
	draft_turn_changed.emit(draft.current_picker_id())
	_check_completed()


func get_player(player_id: int) -> PlayerState:
	return _players[player_id]


## Cartes tirées de son deck, parmi lesquelles le joueur en garde DECK_CARDS_KEPT.
func get_deck_offer(player_id: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.assign(_deck_offers.get(player_id, []))
	return cards


## Nombre de cartes à garder (moins si le deck est presque vide).
func get_keep_count(player_id: int) -> int:
	return mini(CombatConfig.DECK_CARDS_KEPT, get_deck_offer(player_id).size())


func get_shop_offer(player_id: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.assign(_shop_offers.get(player_id, []))
	return cards


func is_bought(player_id: int, index: int) -> bool:
	return _bought.get(player_id, []).has(index)


func is_ready(player_id: int) -> bool:
	return _ready.has(player_id)


func is_complete() -> bool:
	return _ready.size() == _players.size() and draft.is_complete()


## Achat de la carte n° index de sa boutique. Renvoie "" si c'est fait, sinon la raison du refus.
func buy(player_id: int, index: int) -> String:
	var error: String = get_buy_error(player_id, index)
	if not error.is_empty():
		return error
	var player: PlayerState = _players[player_id]
	player.add_points(-CombatConfig.SHOP_CARD_COST)
	player.purchases += 1
	player.add_card_to_deck(get_shop_offer(player_id)[index])
	_bought[player_id].append(index)
	shop_changed.emit(player_id)
	return ""


func get_buy_error(player_id: int, index: int) -> String:
	var player: PlayerState = _players.get(player_id)
	if player == null or is_ready(player_id):
		return "Tu as déjà validé."
	if index < 0 or index >= get_shop_offer(player_id).size() or is_bought(player_id, index):
		return "Cette carte n'est plus en vente."
	if not player.can_purchase():
		return "Tu as déjà acheté %d cartes cette partie." % CombatConfig.MAX_SHOP_PURCHASES
	if player.points < CombatConfig.SHOP_CARD_COST:
		return "Pas assez de points (%d nécessaires)." % CombatConfig.SHOP_CARD_COST
	return ""


## keep_indices : positions des cartes gardées dans get_deck_offer (exactement get_keep_count).
func set_ready(player_id: int, keep_indices: Array) -> String:
	if not _players.has(player_id) or is_ready(player_id):
		return "Tu as déjà validé."
	var kept: Array[CardData] = _cards_at(get_deck_offer(player_id), keep_indices)
	if kept.size() != get_keep_count(player_id):
		return "Choisis %d cartes à garder." % get_keep_count(player_id)
	for card: CardData in kept:
		_players[player_id].add_card_to_deck(card)
	_ready[player_id] = true
	player_ready.emit(player_id)
	_check_completed()
	return ""


func draft_pick(player_id: int, card: CardData) -> String:
	return draft.pick(player_id, card)


## Cartes aux positions données (positions invalides ou répétées ignorées).
static func _cards_at(offer: Array[CardData], indices: Array) -> Array[CardData]:
	var cards: Array[CardData] = []
	var used: Array[int] = []
	for index: Variant in indices:
		var position: int = int(index)
		if position >= 0 and position < offer.size() and not used.has(position):
			used.append(position)
			cards.append(offer[position])
	return cards


func _check_completed() -> void:
	if _is_completed or not is_complete():
		return
	_is_completed = true
	completed.emit()


func _on_draft_picked(player_id: int, card: CardData) -> void:
	_players[player_id].add_card_to_deck(card)
	draft_turn_changed.emit(draft.current_picker_id())
	_check_completed()
