class_name ExecuteEffect
extends CardEffect
## Achève un monstre déjà affaibli (sous le seuil de PV), en ignorant esquive et protections.

@export var health_threshold: float = 0.3


func get_play_error(context: CardContext) -> String:
	var unit: CombatUnit = context.target_units[0] if not context.target_units.is_empty() else null
	if unit == null or unit.side != CombatUnit.Side.MONSTER:
		return "Vise un monstre."
	if unit.get_health_ratio() >= health_threshold:
		return "Le monstre doit avoir moins de %d %% de PV." % roundi(health_threshold * 100.0)
	return ""


func _apply_to_unit(unit: CombatUnit, _context: CardContext) -> void:
	unit.receive_damage(DamageCalculator.build_spell(unit.get_max_health() * 10.0, true, true))
