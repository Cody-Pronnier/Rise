class_name DamageCalculator
extends RefCounted
## Formules de dégâts. Fonctions pures, sans état.


static func build_attack(attacker: CombatUnit) -> DamageInfo:
	var base: float = attacker.data.attack_damage * attacker.statuses.damage_multiplier()
	var info := DamageInfo.new(base, attacker)
	info.on_hit_statuses = attacker.statuses.on_hit_statuses()
	_roll_critical(info, attacker.data.crit_chance + attacker.statuses.crit_bonus())
	return info


static func build_spell(amount: float, unblockable: bool, undodgeable: bool) -> DamageInfo:
	var info := DamageInfo.new(amount)
	info.unblockable = unblockable
	info.undodgeable = undodgeable
	return info


static func incoming_amount(defender: CombatUnit, info: DamageInfo) -> float:
	if info.unblockable:
		return info.amount
	return info.amount * defender.statuses.damage_taken_multiplier()


static func _roll_critical(info: DamageInfo, chance: float) -> void:
	if GameRandom.float_value() >= chance:
		return
	info.is_critical = true
	info.amount *= CombatConfig.CRITICAL_MULTIPLIER
