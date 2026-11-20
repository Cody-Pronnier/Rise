class_name RewardGenerator
extends RefCounted
## Tirage des cartes proposées en boutique entre deux manches.


## `count` cartes différentes parmi celles que la classe peut avoir dans son deck (classe + neutres),
## sans l'ultime : il reste unique (on ne peut en obtenir un second que par un échange).
static func shop_offer(class_data: ClassData, count: int) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card: CardData in DeckRules.pool(class_data):
		if not card.is_ultimate:
			pool.append(card)
	GameRandom.shuffle(pool)
	return pool.slice(0, count)
