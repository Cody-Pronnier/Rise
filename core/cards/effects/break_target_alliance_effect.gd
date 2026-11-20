class_name BreakTargetAllianceEffect
extends CardEffect
## Rompt l'alliance du joueur ciblé, sans que personne ne perde de points.


func get_play_error(context: CardContext) -> String:
	if context.combat_round.alliances.ally_of(context.target_player.id) == -1:
		return "Ce joueur n'a pas d'allié."
	return ""


func apply(context: CardContext) -> void:
	context.combat_round.alliances.break_alliance(context.target_player.id)
