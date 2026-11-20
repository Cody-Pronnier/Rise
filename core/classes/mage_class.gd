class_name MageClass
extends RefCounted
## Mage : gros dégâts de zone et restriction des cartes adverses.

const PORTRAIT: Texture2D = preload("res://assets/characters/mage.svg")
const ID: StringName = &"mage"
const UNIT := CardData.TargetMode.UNIT
const PLAYER := CardData.TargetMode.PLAYER
const FIELD := CardData.TargetMode.FIELD
const ALL_FIELDS := CardData.TargetMode.ALL_FIELDS


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Mage", 80.0, 10.0, 1.1, 0.1, Color(0.35, 0.5, 0.95), PORTRAIT)
	return ClassData.create(ID, "Mage", "Dégâts de zone et contrôle des adversaires.", character, _build_cards())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"mage_fireball", "Boule de feu",
			"Inflige 30 dégâts.",
			UNIT, [EffectFactory.damage(30.0)], false),
		CardFactory.card(&"mage_chains", "Chaîne",
			"Le joueur ciblé ne peut plus jouer de cartes pendant 6 s.",
			PLAYER, [EffectFactory.lock_cards(6.0)], false),
		CardFactory.card(&"mage_fire_nova", "Nova de feu",
			"Inflige 12 dégâts à tout le terrain et brûle les cibles.",
			FIELD, [EffectFactory.damage(12.0, 1, StatusLibrary.burn())], false),
		CardFactory.card(&"mage_frost_nova", "Nova de givre",
			"Inflige 15 dégâts et réduit la vitesse d'attaque de 40 %.",
			UNIT, [EffectFactory.damage(15.0, 1, StatusLibrary.frost())], false),
		CardFactory.ultimate(&"mage_armageddon", "Armageddon",
			"Inflige 45 dégâts à toutes les unités de tous les terrains (sauf terrains protégés et ton allié).",
			ALL_FIELDS, [EffectFactory.damage(45.0)], false),
		CardFactory.card(&"mage_chain_lightning", "Chaîne de foudre",
			"Inflige 20 dégâts puis rebondit sur 2 autres unités du terrain.",
			UNIT, [EffectFactory.chain_damage(20.0, 3)], false),
	]
	return cards
