class_name ClassStatSummary
extends RefCounted
## Résume les stats d'une classe pour l'affichage, chacune ramenée entre 0 et 1
## par rapport à la meilleure classe sur ce critère.

const MIN_REFERENCE: float = 0.0001


class Stat:
	var label: String
	var value_text: String
	var ratio: float

	func _init(p_label: String, p_value_text: String, p_ratio: float) -> void:
		label = p_label
		value_text = p_value_text
		ratio = p_ratio


static func build(class_data: ClassData) -> Array[Stat]:
	var character: UnitData = class_data.character
	var best: Vector3 = _best_values()
	var stats: Array[Stat] = [
		Stat.new("Vie", "%d" % roundi(character.max_health), character.max_health / best.x),
		Stat.new("Dégâts/s", "%.1f" % dps(character), dps(character) / best.y),
		Stat.new("Critique", "%d %%" % roundi(character.crit_chance * 100.0), character.crit_chance / best.z),
	]
	return stats


static func dps(character: UnitData) -> float:
	return character.attack_damage / character.attack_interval


## Meilleures valeurs parmi toutes les classes : x = vie, y = dégâts/s, z = critique.
static func _best_values() -> Vector3:
	var best := Vector3.ONE * MIN_REFERENCE
	for class_data: ClassData in ClassCatalog.get_all():
		var character: UnitData = class_data.character
		best = best.max(Vector3(character.max_health, dps(character), character.crit_chance))
	return best
