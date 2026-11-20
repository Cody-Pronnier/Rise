class_name DamageEffect
extends CardEffect
## Inflige des dégâts, éventuellement en plusieurs coups et avec un statut à l'impact.

@export var amount: float = 10.0
@export var hits: int = 1
@export var unblockable: bool = false
@export var undodgeable: bool = false
@export var status_on_hit: StatusData


func _apply_to_unit(unit: CombatUnit, context: CardContext) -> void:
	for _hit: int in hits:
		unit.receive_damage(DamageCalculator.build_spell(amount * context.power, unblockable, undodgeable))
	if status_on_hit:
		unit.apply_status(status_on_hit)
