class_name RestoreMonsterEffect
extends CardEffect
## Le monstre en cours du terrain ciblé récupère tous ses PV.


func get_play_error(context: CardContext) -> String:
	return "" if context.target_field.current_monster else "Ce terrain n'a plus de monstre."


func apply(context: CardContext) -> void:
	var monster: CombatUnit = context.target_field.current_monster
	if monster:
		monster.receive_heal(monster.get_max_health() * 10.0)
