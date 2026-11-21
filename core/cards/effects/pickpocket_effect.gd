class_name PickpocketEffect
extends CardEffect
## Vole des points au joueur ciblé. S'il n'en a pas (début de partie), son personnage
## subit des dégâts à la place : la carte n'est jamais inutile.

@export var stolen_points: int = 1
@export var fallback_damage: float = 15.0


func get_play_error(context: CardContext) -> String:
	if context.target_player == context.caster:
		return "Choisis un autre joueur."
	return ""


func apply(context: CardContext) -> void:
	var stolen: int = mini(stolen_points, context.target_player.points)
	if stolen > 0:
		context.target_player.add_points(-stolen)
		context.caster.add_points(stolen)
		return
	if context.target_field.is_character_shielded():
		return
	context.target_field.character.receive_damage(DamageCalculator.build_spell(fallback_damage * context.power, false, false))
