class_name ArcherClass
extends RefCounted
## Archer : attaques rapides, aveuglement et tir dévastateur.

const PORTRAIT: Texture2D = preload("res://assets/characters/archer.svg")
const ID: StringName = &"archer"
const UNIT := CardData.TargetMode.UNIT


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Archer", 90.0, 6.0, 0.7, 0.15, Color(0.4, 0.8, 0.4), PORTRAIT)
	return ClassData.create(ID, "Archer", "Attaques rapides et tirs précis.", character, _build_cards())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"archer_blind", "Aveuglement",
			"La cible n'inflige plus de dégâts pendant 4 s.",
			UNIT, [EffectFactory.status(StatusLibrary.blind())], false),
		CardFactory.card(&"archer_piercing_arrow", "Flèche perçante",
			"Inflige 28 dégâts impossibles à esquiver.",
			UNIT, [EffectFactory.piercing_damage(28.0)], false),
		CardFactory.card(&"archer_attack_speed", "Boost d'attaque speed",
			"+60 % de vitesse d'attaque pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.haste())], true),
		CardFactory.card(&"archer_multi_shot", "Multi flèches",
			"Tire 3 flèches de 8 dégâts et fait saigner la cible.",
			UNIT, [EffectFactory.damage(8.0, 3, StatusLibrary.bleed())], false),
		CardFactory.card(&"archer_decoy", "Leurre",
			"La cible esquive la prochaine attaque.",
			UNIT, [EffectFactory.status(StatusLibrary.decoy())], true),
		CardFactory.ultimate(&"archer_devastating_shot", "Tir dévastateur",
			"Inflige 80 dégâts. Inesquivable et imblocable.",
			UNIT, [EffectFactory.true_damage(80.0)], false),
	]
	return cards
