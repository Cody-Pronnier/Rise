class_name DamageEffect
extends CardEffect
## Inflige des dégâts, éventuellement en plusieurs coups et avec un statut à l'impact.
## La portée choisit les unités touchées, et des bonus peuvent dépendre des statuts de la cible.

enum Scope {
	TARGETS,     ## Les unités ciblées par la carte (une unité, tout un terrain…).
	TARGET_SIDE, ## L'unité ciblée et tout son camp (ex : Nova de feu, Bombe).
	ENEMIES,     ## Sur ton terrain le camp du monstre, ailleurs le camp des héros (ex : Armageddon).
}

@export var amount: float = 10.0
@export var hits: int = 1
@export var unblockable: bool = false
@export var undodgeable: bool = false
@export var status_on_hit: StatusData
@export var scope: Scope = Scope.TARGETS

@export_group("Bonus selon la cible")
## Dégâts multipliés par bonus_multiplier si la cible porte un de ces statuts.
@export var bonus_if_statuses: Array[StringName] = []
@export var bonus_multiplier: float = 1.0
## Dégâts ajoutés par type de dégâts sur la durée présent sur la cible (poison, saignement…).
@export var bonus_per_damage_over_time: float = 0.0
## Dégâts ajoutés par pourcent de PV manquant à la cible (ex : Coup fatal).
@export var bonus_per_missing_health_percent: float = 0.0


func apply(context: CardContext) -> void:
	for unit: CombatUnit in _units_in_scope(context):
		if unit.is_alive():
			_apply_to_unit(unit, context)


func _apply_to_unit(unit: CombatUnit, context: CardContext) -> void:
	var damage: float = amount_against(unit) * context.power
	for _hit: int in hits:
		unit.receive_damage(DamageCalculator.build_spell(damage, unblockable, undodgeable))
	if status_on_hit:
		unit.apply_status(status_on_hit)


## Dégâts d'un coup contre cette unité, bonus compris (avant le bonus de rattrapage).
func amount_against(unit: CombatUnit) -> float:
	var damage: float = amount + bonus_per_damage_over_time * unit.statuses.damage_over_time_kinds()
	damage += bonus_per_missing_health_percent * (1.0 - unit.get_health_ratio()) * 100.0
	if unit.statuses.has_any_status(bonus_if_statuses):
		damage *= bonus_multiplier
	return damage


func _units_in_scope(context: CardContext) -> Array[CombatUnit]:
	match scope:
		Scope.TARGET_SIDE:
			if context.target_units.is_empty():
				return context.target_units
			return context.target_field.get_side_of(context.target_units[0])
		Scope.ENEMIES:
			if context.target_field.owner_id == context.caster.id:
				return context.target_field.get_monster_side()
			return context.target_field.get_heroes()
	return context.target_units
