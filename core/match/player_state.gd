class_name PlayerState
extends RefCounted
## Un joueur de la partie : sa classe, son deck, sa main de cartes, ses points et ses restrictions.
## Le deck de 16 cartes est mélangé au début de la partie : STARTING_HAND_SIZE cartes sont
## disponibles à la manche 1 ; après chaque manche, le joueur tire les suivantes et en garde une partie.
## Les achats en boutique et les cartes de podium s'ajoutent directement aux cartes disponibles.

signal hand_changed
signal deck_changed
signal card_lock_changed(is_locked: bool)
signal points_changed(points: int)

var id: int
var display_name: String
var class_data: ClassData
var is_bot: bool
var points: int = 0
## Cartes disponibles pour la partie (débloquées, achetées ou gagnées au podium).
var deck: Array[CardData] = []
## Cartes du deck pas encore débloquées, dans l'ordre où elles arriveront.
var locked_cards: Array[CardData] = []
## Cartes achetées en boutique pendant la partie.
var purchases: int = 0
## Cartes à usage unique pour la manche en cours (copie du deck au début de chaque manche).
var hand: Array[CardData] = []

var _card_lock_remaining: float = 0.0


## deck_cards : le deck complet (16 cartes). Il est mélangé avec GameRandom : identique sur toutes les machines.
func _init(p_id: int, p_display_name: String, p_class_data: ClassData, p_is_bot: bool, deck_cards: Array[CardData]) -> void:
	id = p_id
	display_name = p_display_name
	class_data = p_class_data
	is_bot = p_is_bot
	locked_cards = deck_cards.duplicate()
	GameRandom.shuffle(locked_cards)
	unlock_cards(CombatConfig.STARTING_HAND_SIZE)


## Débloque les prochaines cartes du deck et les renvoie.
func unlock_cards(count: int) -> Array[CardData]:
	var unlocked: Array[CardData] = draw_locked_cards(count)
	deck.append_array(unlocked)
	deck_changed.emit()
	return unlocked


## Retire les prochaines cartes du deck non débloqué (le joueur choisira lesquelles garder).
func draw_locked_cards(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = locked_cards.slice(0, count)
	locked_cards = locked_cards.slice(count)
	return drawn


func can_purchase() -> bool:
	return purchases < CombatConfig.MAX_SHOP_PURCHASES


func add_card_to_deck(card: CardData) -> void:
	deck.append(card)
	deck_changed.emit()


## Remet tout le deck en main pour une nouvelle manche.
func deal_deck() -> void:
	hand = deck.duplicate()
	_clear_card_lock()
	hand_changed.emit()


func _clear_card_lock() -> void:
	if not is_card_locked():
		return
	_card_lock_remaining = 0.0
	card_lock_changed.emit(false)


func has_card(card: CardData) -> bool:
	return hand.has(card)


func consume_card(card: CardData) -> void:
	hand.erase(card)
	hand_changed.emit()


## Carte reçue d'un autre joueur, utilisable une fois pendant la manche en cours.
func receive_hand_card(card: CardData) -> void:
	hand.append(card)
	hand_changed.emit()


func is_card_locked() -> bool:
	return _card_lock_remaining > 0.0


func lock_cards(duration: float) -> void:
	var was_locked: bool = is_card_locked()
	_card_lock_remaining = maxf(_card_lock_remaining, duration)
	if not was_locked:
		card_lock_changed.emit(true)


func add_points(amount: int) -> void:
	points += amount
	points_changed.emit(points)


func tick(delta: float) -> void:
	if not is_card_locked():
		return
	_card_lock_remaining -= delta
	if not is_card_locked():
		_card_lock_remaining = 0.0
		card_lock_changed.emit(false)
