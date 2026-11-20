class_name StealPointsEffect
extends CardEffect
## Prend des points au joueur ciblé (jamais plus qu'il n'en a) et les donne au lanceur.

@export var amount: int = 3


func get_play_error(context: CardContext) -> String:
	if context.target_player == context.caster:
		return "Choisis un autre joueur."
	if context.target_player.points <= 0:
		return "Ce joueur n'a aucun point à voler."
	return ""


func apply(context: CardContext) -> void:
	var stolen: int = mini(amount, context.target_player.points)
	context.target_player.add_points(-stolen)
	context.caster.add_points(stolen)
