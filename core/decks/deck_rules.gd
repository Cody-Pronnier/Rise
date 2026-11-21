class_name DeckRules
extends RefCounted
## Règles de construction d'un deck, façon jeu de cartes à collectionner :
## - exactement DECK_SIZE cartes ;
## - les cartes de sa classe + les cartes neutres ;
## - MAX_COPIES exemplaires au plus d'une même carte, MAX_ULTIMATES ultime au plus.
## Le deck de base d'une classe : son deck de départ s'il en a un, sinon 3 exemplaires
## de chaque carte normale + l'ultime.

const DECK_SIZE: int = 16
const MAX_COPIES: int = 3
const MAX_ULTIMATES: int = 1


## Cartes autorisées dans un deck de cette classe (classe d'abord, puis neutres).
static func pool(class_data: ClassData) -> Array[CardData]:
	var cards: Array[CardData] = class_data.cards.duplicate()
	cards.append_array(NeutralCards.get_all())
	return cards


static func max_copies_of(card: CardData) -> int:
	return MAX_ULTIMATES if card.is_ultimate else MAX_COPIES


static func default_deck_ids(class_data: ClassData) -> Array[StringName]:
	if not class_data.starter_deck.is_empty():
		return _starter_deck_ids(class_data)
	var ids: Array[StringName] = []
	for card: CardData in class_data.cards:
		for _copy: int in max_copies_of(card):
			ids.append(card.id)
	return ids


## "" si le deck est valide, sinon la première règle non respectée.
static func get_error(class_data: ClassData, card_ids: Array) -> String:
	if card_ids.size() != DECK_SIZE:
		return "Le deck doit contenir exactement %d cartes (%d actuellement)." % [DECK_SIZE, card_ids.size()]
	var counts: Dictionary = count_ids(card_ids)
	var allowed: Dictionary[StringName, CardData] = _pool_by_id(class_data)
	var ultimates: int = 0
	for card_id: StringName in counts:
		var card: CardData = allowed.get(card_id)
		if card == null:
			return "Une carte n'est pas autorisée pour cette classe."
		if counts[card_id] > max_copies_of(card):
			return "« %s » : %d exemplaire(s) au maximum." % [card.display_name, max_copies_of(card)]
		if card.is_ultimate:
			ultimates += counts[card_id]
	if ultimates > MAX_ULTIMATES:
		return "Une seule carte ultime par deck."
	return ""


static func is_valid(class_data: ClassData, card_ids: Array) -> bool:
	return get_error(class_data, card_ids).is_empty()


## Deck à utiliser en partie : celui demandé s'il est valide, sinon le deck de base.
static func resolve_deck(class_data: ClassData, card_ids: Array) -> Array[CardData]:
	var ids: Array = card_ids if is_valid(class_data, card_ids) else default_deck_ids(class_data)
	var allowed: Dictionary[StringName, CardData] = _pool_by_id(class_data)
	var cards: Array[CardData] = []
	for card_id: Variant in ids:
		cards.append(allowed[StringName(card_id)])
	return cards


## Nombre d'exemplaires par id (accepte des String ou des StringName).
static func count_ids(card_ids: Array) -> Dictionary:
	var counts: Dictionary = {}
	for card_id: Variant in card_ids:
		var key := StringName(card_id)
		counts[key] = counts.get(key, 0) + 1
	return counts


static func _starter_deck_ids(class_data: ClassData) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card_id: StringName in class_data.starter_deck:
		for _copy: int in class_data.starter_deck[card_id]:
			ids.append(card_id)
	var error: String = get_error(class_data, ids)
	if not error.is_empty():
		push_error("Deck de départ invalide pour %s : %s" % [class_data.display_name, error])
	return ids


static func _pool_by_id(class_data: ClassData) -> Dictionary[StringName, CardData]:
	var by_id: Dictionary[StringName, CardData] = {}
	for card: CardData in pool(class_data):
		by_id[card.id] = card
	return by_id
