class_name ChainDamageEffect
extends CardEffect
## Frappe la cible puis rebondit sur les autres unités de son camp, en perdant de la puissance.
## Ne rebondit jamais sur l'autre camp : lancée sur un monstre, elle ne touche pas ton personnage.

@export var amount: float = 20.0
@export var max_targets: int = 3
@export_range(0.0, 1.0) var falloff: float = 0.7


func apply(context: CardContext) -> void:
	var damage: float = amount * context.power
	for unit: CombatUnit in _pick_chain(context):
		unit.receive_damage(DamageCalculator.build_spell(damage, false, false))
		damage *= falloff


func _pick_chain(context: CardContext) -> Array[CombatUnit]:
	var chain: Array[CombatUnit] = []
	if context.target_units.is_empty():
		return chain
	chain.append_array(context.target_units)
	for unit: CombatUnit in context.target_field.get_side_of(context.target_units[0]):
		if chain.size() >= max_targets:
			break
		if unit.is_alive() and not chain.has(unit):
			chain.append(unit)
	return chain
