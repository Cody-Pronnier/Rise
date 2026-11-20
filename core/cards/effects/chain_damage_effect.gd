class_name ChainDamageEffect
extends CardEffect
## Frappe la cible puis rebondit sur les autres unités du terrain, en perdant de la puissance.

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
	chain.append_array(context.target_units)
	for unit: CombatUnit in context.target_field.get_all_units():
		if chain.size() >= max_targets:
			break
		if unit.is_alive() and not chain.has(unit):
			chain.append(unit)
	return chain
