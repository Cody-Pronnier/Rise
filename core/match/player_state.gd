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
## Émis quand le mana entier change (assez pour savoir quelles cartes sont jouables).
signal mana_changed(mana: float)

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
## Mana pour jouer ses cartes : il se recharge avec le temps (voir CombatConfig.MANA_*).
var mana: float = CombatConfig.MANA_START

var _card_lock_remaining: float = 0.0
## Secondes pendant lesquelles le mana ne se recharge plus (ex : Chaîne du Mage).
var _mana_freeze_remaining: float = 0.0


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
	_mana_freeze_remaining = 0.0
	_set_mana(CombatConfig.MANA_START)
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


func can_afford(card: CardData) -> bool:
	return mana >= card.cost


func spend_mana(amount: int) -> void:
	_set_mana(mana - amount)


## Mana reçu d'un effet (ex : Détrousser), sans dépasser le maximum.
func gain_mana(amount: float) -> void:
	_set_mana(mana + amount)


func add_points(amount: int) -> void:
	points += amount
	points_changed.emit(points)


func tick(delta: float) -> void:
	_tick_mana(delta)
	_tick_card_lock(delta)


func is_mana_frozen() -> bool:
	return _mana_freeze_remaining > 0.0


## Le mana ne se recharge plus pendant `duration` secondes (sans perdre ce qui est déjà là).
func freeze_mana(duration: float) -> void:
	_mana_freeze_remaining = maxf(_mana_freeze_remaining, duration)


func _tick_mana(delta: float) -> void:
	if is_mana_frozen():
		_mana_freeze_remaining = maxf(_mana_freeze_remaining - delta, 0.0)
		return
	_set_mana(mana + CombatConfig.MANA_PER_SECOND * delta)


func _set_mana(value: float) -> void:
	var previous: int = floori(mana)
	mana = clampf(value, 0.0, CombatConfig.MANA_MAX)
	if floori(mana) != previous:
		mana_changed.emit(mana)


func _tick_card_lock(delta: float) -> void:
	if not is_card_locked():
		return
	_card_lock_remaining -= delta
	if not is_card_locked():
		_card_lock_remaining = 0.0
		card_lock_changed.emit(false)
