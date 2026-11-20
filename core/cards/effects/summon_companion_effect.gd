class_name SummonCompanionEffect
extends CardEffect
## Invoque un compagnon aux côtés de l'unité ciblée :
## sur un personnage ou un compagnon, il aide ce héros ; sur un monstre, il se bat pour le monstre.

@export var companion: UnitData


func _apply_to_unit(unit: CombatUnit, context: CardContext) -> void:
	if unit.side == CombatUnit.Side.HERO:
		context.target_field.add_companion(companion)
	else:
		context.target_field.add_monster_companion(companion)
