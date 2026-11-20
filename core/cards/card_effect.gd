class_name CardEffect
extends Resource
## Classe de base d'un effet de carte.
## Par défaut, l'effet s'applique à chaque unité vivante ciblée via _apply_to_unit().
## Les effets qui visent un joueur ou un terrain surchargent apply().


## "" si l'effet peut s'appliquer à cette cible, sinon la raison (la carte n'est alors pas jouée).
func get_play_error(_context: CardContext) -> String:
	return ""


func apply(context: CardContext) -> void:
	for unit: CombatUnit in context.target_units:
		if unit.is_alive():
			_apply_to_unit(unit, context)


func _apply_to_unit(_unit: CombatUnit, _context: CardContext) -> void:
	pass
