class_name RecruitEffect
extends CardEffect
## Congédie le mercenaire en place (s'il y en a un) et en recrute un nouveau : il n'y en a jamais deux.

const MERCENARY_TAG: StringName = &"mercenary"

@export var mercenary: UnitData


func apply(context: CardContext) -> void:
	context.target_field.dismiss_companions(context.target_field.get_companions_tagged(MERCENARY_TAG))
	context.target_field.add_companion(mercenary)
