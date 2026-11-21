class_name ArcherClass
extends RefCounted
## Archer, le chasseur : tirs précis, cadence élevée et marque qui fragilise la proie.

const PORTRAIT: Texture2D = preload("res://assets/characters/archer.svg")
const ID: StringName = &"archer"
const UNIT := CardData.TargetMode.UNIT
const MARK: Array[StringName] = [&"hunter_mark"]


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Archer", 90.0, 6.0, 0.7, 0.15, Color(0.4, 0.8, 0.4), PORTRAIT)
	return ClassData.create(ID, "Archer", "Tirs précis, cadence et marque du chasseur.", character, _build_cards()) \
		.with_starter_deck(_starter_deck())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"archer_piercing_arrow", "Flèche perçante",
			"Inflige 28 dégâts impossibles à esquiver.",
			UNIT, [EffectFactory.piercing_damage(28.0)], false).with_cost(3),
		CardFactory.card(&"archer_multi_shot", "Multi flèches",
			"Tire 3 flèches de 8 dégâts et fait saigner la cible.",
			UNIT, [EffectFactory.damage(8.0, 3, StatusLibrary.bleed())], false).with_cost(3),
		CardFactory.card(&"archer_attack_speed", "Tir rapide",
			"+60 % de vitesse d'attaque pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.haste())], true).with_cost(3),
		CardFactory.card(&"archer_hunter_mark", "Marque du chasseur",
			"La cible subit 30 % de dégâts en plus pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.hunter_mark())], false).with_cost(2),
		CardFactory.card(&"archer_fire_arrow", "Flèche enflammée",
			"Inflige 14 dégâts et brûle la cible (4 dégâts par seconde).",
			UNIT, [EffectFactory.damage(14.0, 1, StatusLibrary.burn())], false).with_cost(2),
		CardFactory.card(&"archer_blind", "Aveuglement",
			"La cible n'inflige plus de dégâts pendant 4 s.",
			UNIT, [EffectFactory.status(StatusLibrary.blind())], false).with_cost(3),
		CardFactory.card(&"archer_decoy", "Leurre",
			"La cible esquive ses 2 prochaines attaques reçues.",
			UNIT, [EffectFactory.status(StatusLibrary.decoy()), EffectFactory.status(StatusLibrary.decoy())], true).with_cost(1),
		CardFactory.ultimate(&"archer_devastating_shot", "Tir dévastateur",
			"Inflige 80 dégâts, inesquivable et imblocable. ×1,5 sur une cible marquée.",
			UNIT, [EffectFactory.damage_bonus_if(EffectFactory.true_damage(80.0), MARK, 1.5)], false),
	]
	return cards


static func _starter_deck() -> Dictionary[StringName, int]:
	return {
		&"archer_piercing_arrow": 3,
		&"archer_hunter_mark": 3,
		&"archer_multi_shot": 2,
		&"archer_attack_speed": 2,
		&"archer_fire_arrow": 2,
		&"archer_blind": 2,
		&"archer_decoy": 1,
		&"archer_devastating_shot": 1,
	}
