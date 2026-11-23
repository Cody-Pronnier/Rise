class_name NeutralCards
extends RefCounted
## Cartes neutres (sans classe) : n'importe quelle classe peut les mettre dans son deck.
## Créées une seule fois (comme les cartes de classe) : une carte est identifiée par son id.

const CLASS_ID: StringName = &"neutral"
const UNIT := CardData.TargetMode.UNIT


static var _cards: Array[CardData] = []


static func get_all() -> Array[CardData]:
	if _cards.is_empty():
		_cards = _build_all()
	return _cards


static func _build_all() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"neutral_healing_potion", "Potion de soin",
			"Soigne 35 PV. Le saignement réduit ce soin.",
			UNIT, [EffectFactory.heal(35.0)], true).with_cost(2),
		CardFactory.card(&"neutral_bomb", "Bombe",
			"Inflige 20 dégâts à la cible et à tout son camp.",
			UNIT, [EffectFactory.side_damage(20.0)], false).with_cost(4),
		CardFactory.card(&"neutral_hourglass", "Sablier",
			"Réduit la vitesse d'attaque de la cible de 40 % pendant 6 s.",
			UNIT, [EffectFactory.status(StatusLibrary.slow())], false).with_cost(2),
		CardFactory.card(&"neutral_strength_elixir", "Élixir de force",
			"+30 % de dégâts pendant 10 s.",
			UNIT, [EffectFactory.status(StatusLibrary.strength())], true).with_cost(3),
		CardFactory.card(&"neutral_stone_skin", "Peau de pierre",
			"-30 % de dégâts reçus pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.stone_skin())], true).with_cost(2),
		CardFactory.card(&"neutral_smoke_bomb", "Fumigène",
			"La cible n'inflige plus de dégâts pendant 2,5 s.",
			UNIT, [EffectFactory.status(StatusLibrary.smoke())], false).with_cost(2),
		CardFactory.card(&"neutral_dispel_scroll", "Parchemin de dissipation",
			"Retire les contrôles et les débuffs de la cible.",
			UNIT, [EffectFactory.purge()], true).with_cost(1),
		CardFactory.card(&"neutral_throwing_knife", "Couteau de lancer",
			"Inflige 15 dégâts impossibles à esquiver.",
			UNIT, [EffectFactory.piercing_damage(15.0)], false).with_cost(1),
	]
	for card: CardData in cards:
		card.class_id = CLASS_ID
	return cards
