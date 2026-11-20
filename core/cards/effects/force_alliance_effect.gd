class_name ForceAllianceEffect
extends CardEffect
## Impose une alliance entre le lanceur et le joueur ciblé (son alliance actuelle est rompue).


func get_play_error(context: CardContext) -> String:
	return context.combat_round.alliances.get_forced_error(context.caster.id, context.target_player.id)


func apply(context: CardContext) -> void:
	context.combat_round.alliances.force(context.caster.id, context.target_player.id)
