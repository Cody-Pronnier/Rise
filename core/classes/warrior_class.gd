class_name WarriorClass
extends RefCounted
## Guerrier : buffs de dégâts, saignements et duel.

const PORTRAIT: Texture2D = preload("res://assets/characters/warrior.svg")
const ID: StringName = &"warrior"
const UNIT := CardData.TargetMode.UNIT
const FIELD := CardData.TargetMode.FIELD


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Guerrier", 130.0, 8.0, 1.1, 0.1, Color(0.85, 0.3, 0.3), PORTRAIT)
	return ClassData.create(ID, "Guerrier", "Résistant, saignements et gros buffs.", character, _build_cards())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"warrior_berserker", "Berserker",
			"Immunisé aux contrôles, +60 % de dégâts, mais +60 % de dégâts reçus pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.berserk())], true),
		CardFactory.card(&"warrior_hemorrhage", "Hémorragie",
			"Saignement de 5 dégâts par seconde pendant 8 s. Réduit les soins reçus.",
			UNIT, [EffectFactory.status(StatusLibrary.bleed(5.0, 8.0))], false),
		CardFactory.card(&"warrior_absolute_defense", "Défense absolue",
			"-60 % de dégâts reçus pendant 6 s.",
			UNIT, [EffectFactory.status(StatusLibrary.absolute_defense())], true),
		CardFactory.ultimate(&"warrior_honor_duel", "Duel pour l'honneur",
			"1 contre 1 pendant 10 s : aucune carte adverse ne peut toucher ce terrain.",
			FIELD, [EffectFactory.protect_field(10.0, false)], true),
		CardFactory.card(&"warrior_hack_away", "Hachez-vous",
			"-40 % de vitesse d'attaque mais dégâts doublés pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.hack_away())], true),
		CardFactory.card(&"warrior_dual_blades", "Double épées",
			"+40 % de vitesse d'attaque et +20 % de dégâts pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.dual_blades())], true),
	]
	return cards
