class_name MageClass
extends RefCounted
## Mage : gros sorts, contrôle des adversaires, mais fragile.

const PORTRAIT: Texture2D = preload("res://assets/characters/mage.svg")
const ID: StringName = &"mage"
const UNIT := CardData.TargetMode.UNIT
const PLAYER := CardData.TargetMode.PLAYER
const ALL_FIELDS := CardData.TargetMode.ALL_FIELDS


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Mage", 80.0, 10.0, 1.1, 0.1, Color(0.35, 0.5, 0.95), PORTRAIT)
	return ClassData.create(ID, "Mage", "Gros sorts et contrôle des adversaires.", character, _build_cards()) \
		.with_starter_deck(_starter_deck())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"mage_fireball", "Boule de feu",
			"Inflige 26 dégâts.",
			UNIT, [EffectFactory.damage(26.0)], false).with_cost(3),
		CardFactory.card(&"mage_frost_nova", "Nova de givre",
			"Inflige 15 dégâts et réduit la vitesse d'attaque de 40 %.",
			UNIT, [EffectFactory.damage(15.0, 1, StatusLibrary.frost())], false).with_cost(2),
		CardFactory.card(&"mage_chain_lightning", "Chaîne de foudre",
			"Inflige 20 dégâts puis rebondit sur 2 autres unités du même camp.",
			UNIT, [EffectFactory.chain_damage(20.0, 3)], false).with_cost(4),
		CardFactory.card(&"mage_fire_nova", "Nova de feu",
			"Inflige 12 dégâts à la cible et à tout son camp, et les brûle.",
			UNIT, [EffectFactory.side_damage(12.0, StatusLibrary.burn())], false).with_cost(4),
		CardFactory.card(&"mage_chains", "Chaîne",
			"Le joueur ciblé ne peut plus jouer de cartes pendant 5 s.",
			PLAYER, [EffectFactory.lock_cards(5.0)], false).with_cost(4),
		CardFactory.card(&"mage_meteor", "Météore",
			"Inflige 55 dégâts à la cible au bout de 3 secondes. Une dissipation l'annule.",
			UNIT, [EffectFactory.delayed_damage(55.0, 3.0)], false).with_cost(4),
		CardFactory.card(&"mage_arcane_barrier", "Barrière arcanique",
			"Absorbe les 35 prochains dégâts reçus par la cible (pendant 10 s).",
			UNIT, [EffectFactory.status(StatusLibrary.arcane_barrier())], true).with_cost(2),
		CardFactory.ultimate(&"mage_armageddon", "Armageddon",
			"Inflige 45 dégâts aux monstres de ton terrain et aux personnages de tous les adversaires (sauf terrains protégés et ton allié).",
			ALL_FIELDS, [EffectFactory.enemy_damage(45.0)], false).with_cost(7),
	]
	return cards


static func _starter_deck() -> Dictionary[StringName, int]:
	return {
		&"mage_fireball": 3,
		&"mage_frost_nova": 2,
		&"mage_chain_lightning": 2,
		&"mage_fire_nova": 2,
		&"mage_chains": 2,
		&"mage_meteor": 2,
		&"mage_arcane_barrier": 2,
		&"mage_armageddon": 1,
	}
