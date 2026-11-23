class_name WarriorClass
extends RefCounted
## Guerrier : résistant, saignements et gros buffs. Ses frappes punissent les cibles qui saignent.

const PORTRAIT: Texture2D = preload("res://assets/characters/warrior.svg")
const ID: StringName = &"warrior"
const UNIT := CardData.TargetMode.UNIT
const SELF := CardData.TargetMode.SELF
const BLEEDING: Array[StringName] = [&"bleed"]
const DUEL_DURATION: float = 10.0


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Guerrier", 130.0, 9.15, 1.1, 0.1, Color(0.85, 0.3, 0.3), PORTRAIT)
	return ClassData.create(ID, "Guerrier", "Résistant, saignements et gros buffs.", character, _build_cards()) \
		.with_starter_deck(_starter_deck())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"warrior_hemorrhage", "Hémorragie",
			"Saignement de 5 dégâts par seconde pendant 8 s. Réduit les soins reçus.",
			UNIT, [EffectFactory.status(StatusLibrary.bleed(5.0, 8.0))], false).with_cost(2),
		CardFactory.card(&"warrior_bloody_strike", "Frappe sanglante",
			"Inflige 22 dégâts, ×1,5 si la cible saigne.",
			UNIT, [EffectFactory.damage_bonus_if(EffectFactory.damage(22.0), BLEEDING, 1.5)], false).with_cost(3),
		CardFactory.card(&"warrior_whirlwind", "Tourbillon",
			"Inflige 12 dégâts à la cible et à tout son camp, et les fait saigner.",
			UNIT, [EffectFactory.side_damage(12.0, StatusLibrary.bleed())], false).with_cost(3),
		CardFactory.card(&"warrior_dual_blades", "Double épées",
			"+40 % de vitesse d'attaque et +20 % de dégâts pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.dual_blades())], true).with_cost(4),
		CardFactory.card(&"warrior_berserker", "Berserker",
			"Immunisé aux contrôles, +60 % de dégâts, mais +60 % de dégâts reçus pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.berserk())], true).with_cost(3),
		CardFactory.card(&"warrior_hack_away", "Hachez-vous",
			"-40 % de vitesse d'attaque mais dégâts doublés pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.hack_away())], true).with_cost(3),
		CardFactory.card(&"warrior_absolute_defense", "Défense absolue",
			"-60 % de dégâts reçus pendant 6 s.",
			UNIT, [EffectFactory.status(StatusLibrary.absolute_defense())], true).with_cost(2),
		CardFactory.ultimate(&"warrior_honor_duel", "Duel pour l'honneur",
			"Pendant 10 s, aucune carte adverse ne peut toucher ton terrain et ton camp inflige 60 % de dégâts en plus.",
			SELF, [EffectFactory.protect_field(DUEL_DURATION, false), EffectFactory.status(StatusLibrary.honor_duel(DUEL_DURATION))], true).with_cost(6),
		CardFactory.ultimate(&"warrior_fatal_blow", "Coup fatal",
			"Inflige 35 dégâts, +1 par % de PV manquant à la cible.",
			UNIT, [EffectFactory.execute_damage(35.0, 1.0)], false).with_cost(6),
	]
	return cards


static func _starter_deck() -> Dictionary[StringName, int]:
	return {
		&"warrior_hemorrhage": 3,
		&"warrior_bloody_strike": 3,
		&"warrior_whirlwind": 2,
		&"warrior_dual_blades": 2,
		&"warrior_berserker": 2,
		&"warrior_hack_away": 1,
		&"warrior_absolute_defense": 2,
		&"warrior_honor_duel": 1,
	}
