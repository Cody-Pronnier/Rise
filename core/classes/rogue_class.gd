class_name RogueClass
extends RefCounted
## Voleur : poison, critiques, esquive et invisibilité.

const PORTRAIT: Texture2D = preload("res://assets/characters/rogue.svg")
const ID: StringName = &"rogue"
const UNIT := CardData.TargetMode.UNIT
const SELF := CardData.TargetMode.SELF


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Voleur", 85.0, 7.0, 0.8, 0.25, Color(0.65, 0.4, 0.85), PORTRAIT)
	return ClassData.create(ID, "Voleur", "Poison, critiques et coups bas.", character, _build_cards())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.ultimate(&"rogue_invisibility", "Invisibilité",
			"Pendant 12 s, ton terrain est inciblable et les autres ne voient plus ta progression.",
			SELF, [EffectFactory.protect_field(12.0, true)], true),
		CardFactory.card(&"rogue_poison", "Poison",
			"Pendant 10 s, les attaques de la cible empoisonnent ce qu'elles touchent.",
			UNIT, [EffectFactory.status(StatusLibrary.poisoned_weapon())], true),
		CardFactory.card(&"rogue_crit_boost", "Boost de critique",
			"+40 % de chances de coup critique pendant 10 s.",
			UNIT, [EffectFactory.status(StatusLibrary.crit_boost())], true),
		CardFactory.card(&"rogue_trap", "Trappe",
			"Pendant 5 s, les attaques reçues par la cible sont renvoyées à l'attaquant.",
			UNIT, [EffectFactory.status(StatusLibrary.trap())], true),
		CardFactory.card(&"rogue_evasion", "Esquive",
			"La cible esquive toutes les attaques pendant 3 s.",
			UNIT, [EffectFactory.status(StatusLibrary.evasion())], true),
		CardFactory.card(&"rogue_backstab", "Coup dans le dos",
			"Inflige 18 dégâts et fait saigner la cible.",
			UNIT, [EffectFactory.damage(18.0, 1, StatusLibrary.bleed())], false),
	]
	return cards
