class_name GainGoldEffect
extends CardEffect
## Donne de l'or au terrain visé. Sans effet pour une classe qui n'utilise pas d'or.

@export var amount: int = 20


func apply(context: CardContext) -> void:
	context.target_field.passive.receive_gold(amount)
