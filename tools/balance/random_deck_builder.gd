class_name RandomDeckBuilder
extends RefCounted
## Decks aléatoires mais valides (règles de DeckRules) pour le simulateur : chaque carte se retrouve
## dans certains decks et pas dans d'autres, ce qui permet de mesurer ce qu'elle apporte.
## Utilise le hasard global, fixé par la graine de la partie : mêmes graines = mêmes decks.

## Chance de prendre une ultime (la plupart des joueurs en mettront une).
const ULTIMATE_CHANCE: float = 0.85
## Les cartes de la classe sont plus souvent choisies que les cartes neutres.
const CLASS_CARD_WEIGHT: float = 3.0
const NEUTRAL_CARD_WEIGHT: float = 1.0


static func build(class_data: ClassData) -> Array[StringName]:
	var ids: Array[StringName] = []
	var pool: Array[CardData] = DeckRules.pool(class_data)
	var ultimates: Array[CardData] = pool.filter(func(card: CardData) -> bool: return card.is_ultimate)
	if not ultimates.is_empty() and randf() < ULTIMATE_CHANCE:
		ids.append(ultimates.pick_random().id)
	var normals: Array[CardData] = pool.filter(func(card: CardData) -> bool: return not card.is_ultimate)
	while ids.size() < DeckRules.DECK_SIZE:
		var candidates: Array[CardData] = normals.filter(func(card: CardData) -> bool: return ids.count(card.id) < DeckRules.MAX_COPIES)
		if candidates.is_empty():
			break
		ids.append(_weighted_pick(candidates, class_data.id).id)
	return ids


static func _weighted_pick(cards: Array[CardData], class_id: StringName) -> CardData:
	var total: float = 0.0
	for card: CardData in cards:
		total += _weight(card, class_id)
	var roll: float = randf() * total
	for card: CardData in cards:
		roll -= _weight(card, class_id)
		if roll <= 0.0:
			return card
	return cards.back()


static func _weight(card: CardData, class_id: StringName) -> float:
	return CLASS_CARD_WEIGHT if card.class_id == class_id else NEUTRAL_CARD_WEIGHT
