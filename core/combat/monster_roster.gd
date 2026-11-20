class_name MonsterRoster
extends RefCounted
## Les 3 monstres d'une manche, de plus en plus forts à chaque manche.
## Plusieurs familles existent (peaux-vertes, dragons…) : CombatRound en tire une par manche,
## la même pour tous les joueurs pour que la course reste équitable.

const GOBLIN_PORTRAIT: Texture2D = preload("res://assets/monsters/goblin.svg")
const ORC_PORTRAIT: Texture2D = preload("res://assets/monsters/orc.svg")
const TROLL_PORTRAIT: Texture2D = preload("res://assets/monsters/troll.svg")
const DRAGONLING_PORTRAIT: Texture2D = preload("res://assets/monsters/dragonling.svg")
const DRAGON_PORTRAIT: Texture2D = preload("res://assets/monsters/dragon.svg")
const ANCIENT_DRAGON_PORTRAIT: Texture2D = preload("res://assets/monsters/ancient_dragon.svg")

enum Family { GREENSKINS, DRAGONS }

const FAMILY_NAMES: Dictionary[Family, String] = {
	Family.GREENSKINS: "Peaux-vertes",
	Family.DRAGONS: "Dragons",
}


static func family_name(family: Family) -> String:
	return FAMILY_NAMES.get(family, "")


## Famille tirée au hasard avec GameRandom (identique sur toutes les machines).
static func pick_family() -> Family:
	return GameRandom.pick(FAMILY_NAMES.keys()) as Family


static func build_for_round(round_index: int, family: Family = Family.GREENSKINS) -> Array[UnitData]:
	var multiplier: float = 1.0 + CombatConfig.MONSTER_SCALING_PER_ROUND * round_index
	var monsters: Array[UnitData] = []
	for monster: UnitData in _base_monsters(family):
		monsters.append(monster.scaled(multiplier))
	return monsters


## Les deux familles ont une difficulté proche : les dragons frappent un peu plus fort
## mais ont un peu moins de PV.
static func _base_monsters(family: Family) -> Array[UnitData]:
	var monsters: Array[UnitData] = []
	match family:
		Family.DRAGONS:
			monsters = [
				UnitData.create("Dragonnet", 100.0, 4.5, 1.4, 0.05, Color(0.4, 0.75, 0.45), DRAGONLING_PORTRAIT),
				UnitData.create("Dragon", 150.0, 6.5, 1.6, 0.08, Color(0.8, 0.3, 0.25), DRAGON_PORTRAIT),
				UnitData.create("Dragon ancien", 215.0, 8.5, 1.8, 0.1, Color(0.45, 0.3, 0.75), ANCIENT_DRAGON_PORTRAIT),
			]
		_:
			monsters = [
				UnitData.create("Gobelin", 110.0, 4.0, 1.4, 0.05, Color(0.45, 0.6, 0.3), GOBLIN_PORTRAIT),
				UnitData.create("Orc", 160.0, 6.0, 1.6, 0.05, Color(0.35, 0.45, 0.3), ORC_PORTRAIT),
				UnitData.create("Troll", 230.0, 8.0, 1.8, 0.05, Color(0.4, 0.35, 0.5), TROLL_PORTRAIT),
			]
	## Les monstres sont dessinés tournés vers la gauche.
	for monster: UnitData in monsters:
		monster.portrait_faces_left = true
	return monsters
