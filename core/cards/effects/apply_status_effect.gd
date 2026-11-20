class_name ApplyStatusEffect
extends CardEffect
## Applique un statut à la cible. Un débuff ou un contrôle renforcé (context.power) dure plus longtemps.

@export var status: StatusData


func _apply_to_unit(unit: CombatUnit, context: CardContext) -> void:
	unit.apply_status(_status_for(context.power))


func _status_for(power: float) -> StatusData:
	if is_equal_approx(power, 1.0) or status.category == StatusData.Category.BUFF:
		return status
	var boosted: StatusData = status.duplicate()
	boosted.duration *= power
	return boosted
