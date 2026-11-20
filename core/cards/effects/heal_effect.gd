class_name HealEffect
extends CardEffect
## Soigne la cible (réduit par le saignement via heal_received_mult).
## heroes_only : sur un terrain entier, ne soigne que les personnages et leurs compagnons (pas les monstres).

@export var amount: float = 30.0
@export var heroes_only: bool = false


func _apply_to_unit(unit: CombatUnit, _context: CardContext) -> void:
	if heroes_only and unit.side != CombatUnit.Side.HERO:
		return
	unit.receive_heal(amount)
