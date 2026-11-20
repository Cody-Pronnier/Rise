class_name PriestClass
extends RefCounted
## Prêtre : soins, protections et bénédictions.

const PORTRAIT: Texture2D = preload("res://assets/characters/priest.svg")
const ID: StringName = &"priest"
const UNIT := CardData.TargetMode.UNIT
const ALL_FIELDS := CardData.TargetMode.ALL_FIELDS


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Prêtre", 110.0, 6.0, 1.0, 0.05, Color(0.95, 0.85, 0.45), PORTRAIT)
	return ClassData.create(ID, "Prêtre", "Soins, boucliers et bénédictions.", character, _build_cards())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"priest_heal", "Heal",
			"Soigne 40 PV. Le saignement réduit ce soin.",
			UNIT, [EffectFactory.heal(40.0)], true),
		CardFactory.card(&"priest_shield", "Bouclier",
			"La cible ne reçoit plus de dégâts pendant 4 s.",
			UNIT, [EffectFactory.status(StatusLibrary.shield())], true),
		CardFactory.card(&"priest_blessing", "Bénédiction",
			"+50 % de dégâts pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.blessing())], true),
		CardFactory.ultimate(&"priest_divine_favor", "Faveur divine",
			"Soigne 60 PV à tous les personnages et compagnons de tous les terrains (sauf terrains protégés).",
			ALL_FIELDS, [EffectFactory.heal_heroes(60.0)], true),
		CardFactory.card(&"priest_purge", "Purge",
			"Retire les contrôles et les débuffs de la cible.",
			UNIT, [EffectFactory.purge()], true),
		CardFactory.card(&"priest_staff_strike", "Coup de bâton",
			"Inflige 20 dégâts.",
			UNIT, [EffectFactory.damage(20.0)], false),
	]
	return cards
