class_name RogueClass
extends RefCounted
## Voleur, l'ombre : poison, combos sur les cibles affaiblies, vol et coups bas.

const PORTRAIT: Texture2D = preload("res://assets/characters/rogue.svg")
const ID: StringName = &"rogue"
const UNIT := CardData.TargetMode.UNIT
const SELF := CardData.TargetMode.SELF
const PLAYER := CardData.TargetMode.PLAYER
const WOUNDS: Array[StringName] = [&"poison", &"bleed"]


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Voleur", 85.0, 7.25, 0.8, 0.25, Color(0.65, 0.4, 0.85), PORTRAIT)
	return ClassData.create(ID, "Voleur", "Poison, combos et coups bas.", character, _build_cards()) \
		.with_starter_deck(_starter_deck())


static func _build_cards() -> Array[CardData]:
	var cards: Array[CardData] = [
		CardFactory.card(&"rogue_poison", "Poison",
			"Empoisonne la cible : 4 dégâts par seconde pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.poison(4.0, 8.0))], false).with_cost(2),
		CardFactory.card(&"rogue_backstab", "Coup dans le dos",
			"Inflige 18 dégâts, doublés si la cible est empoisonnée ou saigne.",
			UNIT, [EffectFactory.damage_bonus_if(EffectFactory.damage(18.0), WOUNDS, 2.0)], false).with_cost(3),
		CardFactory.card(&"rogue_poisoned_blade", "Lame empoisonnée",
			"Pendant 6 s, les attaques de la cible empoisonnent ce qu'elles touchent.",
			UNIT, [EffectFactory.status(StatusLibrary.poisoned_weapon())], true).with_cost(4),
		CardFactory.card(&"rogue_cutpurse", "Détrousser",
			"Vide la jauge de mana d'un joueur mieux classé que toi et te la donne. S'il n'en a plus, son personnage subit 15 dégâts.",
			PLAYER, [EffectFactory.pickpocket(15.0)], false).with_cost(2),
		CardFactory.card(&"rogue_trip", "Croc-en-jambe",
			"La cible ne peut plus attaquer pendant 2 s et subit 25 % de dégâts en plus pendant 4 s.",
			UNIT, [EffectFactory.status(StatusLibrary.trip()), EffectFactory.status(StatusLibrary.off_balance())], false).with_cost(2),
		CardFactory.card(&"rogue_evasion", "Esquive",
			"La cible esquive toutes les attaques pendant 3 s.",
			UNIT, [EffectFactory.status(StatusLibrary.evasion())], true).with_cost(2),
		CardFactory.card(&"rogue_invisibility", "Invisibilité",
			"Pendant 6 s, ton terrain est inciblable, les autres ne voient plus ta progression et ton camp attaque 30 % plus vite.",
			SELF, [EffectFactory.protect_field(6.0, true), EffectFactory.status(StatusLibrary.shadow_strike())], true).with_cost(3),
		CardFactory.ultimate(&"rogue_assassinate", "Assassinat",
			"Inflige 55 dégâts, +15 par type de dégâts sur la durée sur la cible (poison, saignement, brûlure).",
			UNIT, [EffectFactory.damage_per_damage_over_time(55.0, 15.0)], false),
		CardFactory.ultimate(&"rogue_blade_dance", "Danse des lames",
			"Pendant 8 s, ton camp attaque 60 % plus vite et chaque coup fait saigner la cible.",
			SELF, [EffectFactory.status(StatusLibrary.blade_dance())], true),
	]
	return cards


static func _starter_deck() -> Dictionary[StringName, int]:
	return {
		&"rogue_poison": 3,
		&"rogue_backstab": 3,
		&"rogue_poisoned_blade": 2,
		&"rogue_cutpurse": 2,
		&"rogue_trip": 2,
		&"rogue_evasion": 2,
		&"rogue_invisibility": 1,
		&"rogue_assassinate": 1,
	}
