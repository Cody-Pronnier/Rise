class_name NecromancerClass
extends RefCounted
## Nécromancien : ne frappe jamais lui-même. Il se bat avec ses invocations, les renforce,
## et peut toutes les fusionner en une abomination avec son ultime.

const PORTRAIT: Texture2D = preload("res://assets/characters/necromancer.svg")
const SKELETON_PORTRAIT: Texture2D = preload("res://assets/characters/skeleton.svg")
const GHOUL_PORTRAIT: Texture2D = preload("res://assets/characters/ghoul.svg")
const ABOMINATION_PORTRAIT: Texture2D = preload("res://assets/characters/abomination.svg")
const ID: StringName = &"necromancer"
const UNIT := CardData.TargetMode.UNIT
const SELF := CardData.TargetMode.SELF
const MINION: StringName = &"minion"
const COLOR := Color(0.4, 0.78, 0.62)
const FUSION_BONUS: float = 1.3
const PASSIVE_TEXT: String = "Ne frappe jamais lui-même. Quand il n'a plus aucune invocation, il relève un squelette au bout de 2,5 s (et dès le début de la manche)."


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Nécromancien", 95.0, 0.0, 1.0, 0.0, COLOR, PORTRAIT)
	var skeleton: UnitData = _skeleton()
	var data: ClassData = ClassData.create(ID, "Nécromancien", "Ne se bat qu'avec ses invocations, qu'il renforce et fusionne.", character, _build_cards())
	return data.with_passive(func() -> ClassPassive: return NecromancerPassive.new(skeleton), PASSIVE_TEXT)


static func _skeleton() -> UnitData:
	return UnitData.create("Squelette", 40.0, 5.0, 1.0, 0.05, Color(0.85, 0.85, 0.8), SKELETON_PORTRAIT).with_tag(MINION)


static func _build_cards() -> Array[CardData]:
	var ghoul: UnitData = UnitData.create("Goule", 75.0, 7.0, 1.1, 0.05, Color(0.5, 0.65, 0.45), GHOUL_PORTRAIT).with_tag(MINION)
	var abomination_base: UnitData = UnitData.create("Abomination", 30.0, 4.0, 1.2, 0.05, Color(0.55, 0.7, 0.5), ABOMINATION_PORTRAIT).with_tag(MINION)
	var cards: Array[CardData] = [
		CardFactory.card(&"necro_raise_dead", "Relever les morts",
			"Invoque 2 squelettes aux côtés de l'unité ciblée : ils se battent pour son camp (héros ou monstre).",
			UNIT, [EffectFactory.summon_on_field(_skeleton(), 2)], true),
		CardFactory.card(&"necro_ghoul", "Goule",
			"Invoque une goule robuste (75 PV) aux côtés de l'unité ciblée, pour son camp.",
			UNIT, [EffectFactory.summon_on_field(ghoul)], true),
		CardFactory.card(&"necro_unholy_frenzy", "Frénésie impie",
			"L'unité ciblée et tout son camp gagnent +50 % de vitesse d'attaque et +20 % de dégâts pendant 8 s.",
			UNIT, [EffectFactory.status_to_side(StatusLibrary.unholy_frenzy())], true),
		CardFactory.card(&"necro_bone_armor", "Armure d'os",
			"L'unité ciblée et tout son camp reçoivent 40 % de dégâts en moins pendant 8 s.",
			UNIT, [EffectFactory.status_to_side(StatusLibrary.bone_armor())], true),
		CardFactory.card(&"necro_curse", "Malédiction",
			"La cible reçoit 40 % de dégâts en plus pendant 8 s.",
			UNIT, [EffectFactory.status(StatusLibrary.curse())], false),
		CardFactory.ultimate(&"necro_abomination", "Fusion abominable",
			"Fusionne toutes tes invocations en une abomination : leurs PV et dégâts s'additionnent, +30 %.",
			SELF, [EffectFactory.fuse_minions(abomination_base, FUSION_BONUS)], true),
	]
	return cards
