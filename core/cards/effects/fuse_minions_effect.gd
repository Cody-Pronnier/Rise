class_name FuseMinionsEffect
extends CardEffect
## Fusionne toutes les invocations (tag « minion ») du terrain en une seule créature :
## ses PV et ses dégâts valent ceux de la base plus la somme des invocations, multipliés par le bonus.
## Elle arrive avec tous ses PV et reste une invocation (le squelette automatique ne revient pas).

const MINION_TAG: StringName = &"minion"

@export var base: UnitData
@export var bonus: float = 1.3


func apply(context: CardContext) -> void:
	var minions: Array[CombatUnit] = context.target_field.get_companions_tagged(MINION_TAG)
	context.target_field.dismiss_companions(minions)
	context.target_field.add_companion(_build_fused_unit(minions))


func _build_fused_unit(minions: Array[CombatUnit]) -> UnitData:
	var fused: UnitData = base.scaled(1.0)
	for minion: CombatUnit in minions:
		fused.max_health += minion.data.max_health
		fused.attack_damage += minion.data.attack_damage
		fused.crit_chance = maxf(fused.crit_chance, minion.data.crit_chance)
	fused.max_health *= bonus
	fused.attack_damage *= bonus
	fused.tag = MINION_TAG
	return fused
