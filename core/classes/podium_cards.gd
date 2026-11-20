class_name PodiumCards
extends RefCounted
## Cartes uniques du podium : gagnées seulement en finissant parmi les 3 premiers d'une manche.
## Elles ne peuvent pas être mises dans un deck et pèsent sur la partie (points, alliances, cartes).

const CLASS_ID: StringName = &"podium"
const UNIT := CardData.TargetMode.UNIT
const PLAYER := CardData.TargetMode.PLAYER
const STOLEN_POINTS: int = 3

static var _cards: Array[CardData] = []


static func get_all() -> Array[CardData]:
	if _cards.is_empty():
		_cards = _build_all()
	return _cards


## `count` cartes différentes tirées au hasard (GameRandom : identique sur toutes les machines).
static func draw(count: int) -> Array[CardData]:
	var cards: Array[CardData] = get_all().duplicate()
	GameRandom.shuffle(cards)
	return cards.slice(0, count)


static func _build_all() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"podium_forced_pact", "Pacte forcé",
			"Impose une alliance avec le joueur ciblé, même s'il en a déjà une (elle est rompue) ou en a déjà eu une cette manche.",
			PLAYER, [ForceAllianceEffect.new()], false),
		CardFactory.card(&"podium_larceny", "Larcin",
			"Vole %d points au joueur ciblé." % STOLEN_POINTS,
			PLAYER, [_steal_points()], false),
		CardFactory.card(&"podium_pickpocket", "Vol à la tire",
			"Vole une carte au hasard dans la main du joueur ciblé. Tu peux la jouer pendant cette manche.",
			PLAYER, [StealCardEffect.new()], false),
		CardFactory.card(&"podium_discord", "Discorde",
			"Rompt l'alliance du joueur ciblé, sans pénalité de points.",
			PLAYER, [BreakTargetAllianceEffect.new()], false),
		CardFactory.card(&"podium_second_wind", "Second souffle",
			"Le monstre en cours du joueur ciblé récupère tous ses PV.",
			PLAYER, [RestoreMonsterEffect.new()], false),
		CardFactory.card(&"podium_coup_de_grace", "Coup de grâce",
			"Achève un monstre qui a moins de 30 % de PV, sans tenir compte des protections.",
			UNIT, [ExecuteEffect.new()], false),
	]
	for card: CardData in cards:
		card.class_id = CLASS_ID
	return cards


static func _steal_points() -> StealPointsEffect:
	var effect := StealPointsEffect.new()
	effect.amount = STOLEN_POINTS
	return effect
