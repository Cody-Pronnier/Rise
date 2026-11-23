class_name PickpocketEffect
extends CardEffect
## Vide la jauge de mana d'un joueur mieux classé que le lanceur dans la manche en cours
## (carte de rattrapage) : le lanceur récupère ce mana, dans la limite de sa jauge.
## Le meneur est ralenti, le lanceur accéléré, sans toucher aux points du classement.
## Si la cible n'a plus de mana, son personnage subit des dégâts à la place.

@export var fallback_damage: float = 15.0


func get_play_error(context: CardContext) -> String:
	if context.target_player == context.caster:
		return "Choisis un autre joueur."
	if CatchUpBoost.places_ahead(context.combat_round, context.caster.id, context.target_player.id) <= 0:
		return "Choisis un joueur mieux classé que toi."
	return ""


func apply(context: CardContext) -> void:
	var stolen: float = context.target_player.mana
	if stolen >= 1.0:
		context.target_player.spend_mana(ceili(stolen))
		context.caster.gain_mana(stolen)
		return
	if context.target_field.is_character_shielded():
		return
	context.target_field.character.receive_damage(DamageCalculator.build_spell(fallback_damage * context.power, false, false))
