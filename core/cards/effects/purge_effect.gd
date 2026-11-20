class_name PurgeEffect
extends CardEffect
## Retire les contrôles et les débuffs de la cible.

const PURGED_CATEGORIES: Array[int] = [StatusData.Category.DEBUFF, StatusData.Category.CONTROL]


func _apply_to_unit(unit: CombatUnit, _context: CardContext) -> void:
	unit.purge(PURGED_CATEGORIES)
