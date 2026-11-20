class_name DruidClass
extends RefCounted
## Druide : compagnon, soins sur la durée et contrôle de la nature.

const PORTRAIT: Texture2D = preload("res://assets/characters/druid.svg")
const WOLF_PORTRAIT: Texture2D = preload("res://assets/characters/wolf.svg")
const ID: StringName = &"druid"
const UNIT := CardData.TargetMode.UNIT
const FIELD := CardData.TargetMode.FIELD
const ALL_FIELDS := CardData.TargetMode.ALL_FIELDS


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Druide", 105.0, 7.0, 1.0, 0.05, Color(0.55, 0.45, 0.25), PORTRAIT)
	return ClassData.create(ID, "Druide", "Compagnon, soins sur la durée et nature.", character, _build_cards())


static func _build_cards() -> Array[CardData]:
	var wolf: UnitData = UnitData.create("Loup", 60.0, 4.0, 0.9, 0.1, Color(0.6, 0.6, 0.65), WOLF_PORTRAIT)
	var cards: Array[CardData] = [
		CardFactory.card(&"druid_companion", "Compagnon",
			"Invoque un loup aux côtés de l'unité ciblée : il aide un personnage, ou se bat pour un monstre. Il peut être ciblé.",
			UNIT, [EffectFactory.summon(wolf)], true),
		CardFactory.card(&"druid_regrowth", "Revitalisation",
			"Soigne 4 PV par seconde pendant 8 s. Le saignement réduit ce soin.",
			UNIT, [EffectFactory.status(StatusLibrary.regrowth())], true),
		CardFactory.card(&"druid_root", "Enracinement",
			"Réduit la vitesse d'attaque de la cible de 50 % pendant 5 s.",
			UNIT, [EffectFactory.status(StatusLibrary.root())], false),
		CardFactory.ultimate(&"druid_yggdrasil", "Yggdrasil",
			"Aucune unité de tous les terrains ne reçoit de dégâts pendant 5 s (sauf terrains protégés).",
			ALL_FIELDS, [EffectFactory.status(StatusLibrary.yggdrasil())], true),
		CardFactory.card(&"druid_vitality_seed", "Graine de vitalité",
			"Si la cible passe sous 10 % de PV dans les 20 s, elle récupère 40 PV.",
			UNIT, [EffectFactory.status(StatusLibrary.vitality_seed())], true),
		CardFactory.card(&"druid_gigantism", "Gigantisme",
			"+40 % de dégâts et +50 % de PV max pendant 10 s.",
			UNIT, [EffectFactory.status(StatusLibrary.gigantism())], true),
	]
	return cards
