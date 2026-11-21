class_name DelayedDamageEffect
extends CardEffect
## Dégâts à retardement (Météore) : un statut est posé sur la cible et explose à la fin du délai.
## Le délai ne s'allonge pas avec le bonus de rattrapage : seuls les dégâts augmentent.
## Une dissipation retire le statut avant l'impact.

@export var amount: float = 50.0
@export var delay: float = 3.0


func _apply_to_unit(unit: CombatUnit, context: CardContext) -> void:
	unit.apply_status(StatusLibrary.meteor(amount * context.power, delay))
