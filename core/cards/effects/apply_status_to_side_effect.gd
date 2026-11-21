class_name ApplyStatusToSideEffect
extends CardEffect
## Applique un statut à l'unité ciblée et à tout son camp sur ce terrain :
## personnage + compagnons, ou monstre + compagnons du monstre.

@export var status: StatusData


func apply(context: CardContext) -> void:
	if context.target_units.is_empty():
		return
	for unit: CombatUnit in context.target_field.get_side_of(context.target_units[0]):
		if unit.is_alive():
			unit.apply_status(status)
