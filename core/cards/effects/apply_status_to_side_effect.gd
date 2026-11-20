class_name ApplyStatusToSideEffect
extends CardEffect
## Applique un statut à l'unité ciblée et à tout son camp sur ce terrain :
## personnage + compagnons, ou monstre + compagnons du monstre.

@export var status: StatusData


func apply(context: CardContext) -> void:
	if context.target_units.is_empty():
		return
	for unit: CombatUnit in _side_of(context.target_units[0], context.target_field):
		if unit.is_alive():
			unit.apply_status(status)


func _side_of(unit: CombatUnit, field: Field) -> Array[CombatUnit]:
	if unit.side == CombatUnit.Side.HERO:
		return field.get_heroes()
	var monsters: Array[CombatUnit] = []
	if field.current_monster:
		monsters.append(field.current_monster)
	monsters.append_array(field.monster_companions)
	return monsters
