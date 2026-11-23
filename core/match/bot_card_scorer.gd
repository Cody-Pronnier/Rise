class_name BotCardScorer
extends RefCounted
## Estime la valeur d'une carte sur une cible, en « points de dégâts équivalents », pour les bots malins.
## Ce n'est pas une simulation exacte : juste assez pour préférer la bonne carte au bon moment
## (Coup dans le dos sur une cible empoisonnée, Tir dévastateur sur une cible marquée…).
## Fonctions pures : rien n'est modifié.

## Gêner un adversaire ne gêne qu'un rival sur sept : ça compte moins que d'avancer soi-même.
const SABOTAGE_FACTOR: float = 0.4
## Des dégâts sur le personnage d'un adversaire ne le ralentissent vraiment que s'ils le tuent
## (il attend alors RESPAWN_DELAY) : le reste ne compte presque pas.
const HERO_DAMAGE_FACTOR: float = 0.15
## Retirer un débuff ou un contrôle de son personnage.
const PURGE_VALUE_PER_STATUS: float = 10.0
## Valeur d'une seconde de cartes bloquées chez un adversaire.
const LOCK_VALUE_PER_SECOND: float = 4.0
## Valeur d'un point de classement (échanges de points entre joueurs).
const POINT_VALUE: float = 12.0
## Valeur d'un point de mana volé : ce qu'il rapporte au voleur + ce qu'il coûte à la cible.
const STOLEN_MANA_VALUE: float = 9.0
## Valeur d'un terrain protégé (Invisibilité) par seconde.
const PROTECTION_VALUE_PER_SECOND: float = 1.5
## Effets que le bot ne sait pas estimer : valeur moyenne par point de mana.
const DEFAULT_VALUE_PER_MANA: float = 9.0
## Part de la valeur d'un contrôle sur un monstre (dégâts évités : utile, mais moins que d'avancer).
const DEFENSIVE_FACTOR: float = 0.5
## Perte de puissance à chaque rebond de Chaîne de foudre.
const CHAIN_FALLOFF: float = 0.7


## Valeur estimée de la carte jouée sur cette cible (0 si elle ne sert à rien).
static func score(card: CardData, target: CardTarget, combat_round: CombatRound, caster: PlayerState) -> float:
	var field: Field = combat_round.fields.get(target.player_id)
	if field == null:
		return 0.0
	var total: float = 0.0
	for effect: CardEffect in card.effects:
		total += _effect_value(effect, card, target, field, combat_round, caster)
	return total


## Valeur de la carte pour ce joueur sur sa meilleure cible du moment (pour juger un échange).
static func best_value(card: CardData, combat_round: CombatRound, player: PlayerState) -> float:
	var best: float = 0.0
	for target: CardTarget in BotTargets.for_card(card, combat_round, player.id):
		best = maxf(best, score(card, target, combat_round, player))
	return best


# --- Par type d'effet --------------------------------------------------------

static func _effect_value(effect: CardEffect, card: CardData, target: CardTarget, field: Field, combat_round: CombatRound, caster: PlayerState) -> float:
	if effect is DamageEffect:
		return _damage_value(effect as DamageEffect, target, field, caster)
	if effect is ChainDamageEffect:
		return _chain_value(effect as ChainDamageEffect, target, field, caster)
	if effect is DelayedDamageEffect:
		return _single_damage_value((effect as DelayedDamageEffect).amount, target.unit, field, caster, false)
	if effect is ApplyStatusEffect:
		return _status_value((effect as ApplyStatusEffect).status, _status_holder(target, field), field, caster)
	if effect is ApplyStatusToSideEffect:
		return _side_status_value((effect as ApplyStatusToSideEffect).status, target.unit, field, caster)
	if effect is HealEffect:
		return _heal_value(effect as HealEffect, target.unit, field, caster)
	if effect is PurgeEffect:
		return _purge_value(target.unit, field, caster)
	if effect is LockCardsEffect:
		return _lock_value(effect as LockCardsEffect) if target.player_id != caster.id else 0.0
	if effect is PickpocketEffect:
		return _pickpocket_value(effect as PickpocketEffect, combat_round.players[target.player_id], caster)
	if effect is ProtectFieldEffect:
		return (effect as ProtectFieldEffect).duration * PROTECTION_VALUE_PER_SECOND
	return _unknown_value(card, target, field, caster)


## Effet que le bot ne sait pas estimer : une valeur moyenne, mais seulement dans le bon sens
## (une carte d'aide sur son camp, une carte offensive ailleurs que sur son propre camp).
static func _unknown_value(card: CardData, target: CardTarget, field: Field, caster: PlayerState) -> float:
	var on_own_heroes: bool = field.owner_id == caster.id and (target.unit == null or target.unit.side == CombatUnit.Side.HERO)
	if card.is_beneficial != on_own_heroes:
		return 0.0
	return card.cost * DEFAULT_VALUE_PER_MANA / maxf(card.effects.size(), 1.0)


static func _damage_value(effect: DamageEffect, target: CardTarget, field: Field, caster: PlayerState) -> float:
	var total: float = 0.0
	for unit: CombatUnit in _damage_targets(effect, target, field, caster):
		var amount: float = effect.amount_against(unit) * effect.hits
		total += _single_damage_value(amount, unit, field, caster, effect.unblockable)
		if effect.status_on_hit:
			total += _status_value(effect.status_on_hit, unit, field, caster)
	return total


static func _damage_targets(effect: DamageEffect, target: CardTarget, field: Field, caster: PlayerState) -> Array[CombatUnit]:
	match effect.scope:
		DamageEffect.Scope.TARGET_SIDE:
			return field.get_side_of(target.unit) if target.unit else _no_units()
		DamageEffect.Scope.ENEMIES:
			return field.get_monster_side() if field.owner_id == caster.id else field.get_heroes()
	if target.unit:
		var units: Array[CombatUnit] = [target.unit]
		return units
	return field.get_all_units()


static func _chain_value(effect: ChainDamageEffect, target: CardTarget, field: Field, caster: PlayerState) -> float:
	if target.unit == null:
		return 0.0
	var chain: Array[CombatUnit] = [target.unit]
	for unit: CombatUnit in field.get_side_of(target.unit):
		if chain.size() < effect.max_targets and unit.is_alive() and not chain.has(unit):
			chain.append(unit)
	var total: float = 0.0
	var damage: float = effect.amount
	for unit: CombatUnit in chain:
		total += _single_damage_value(damage, unit, field, caster, false)
		damage *= CHAIN_FALLOFF
	return total


## Dégâts sur son propre monstre : pleine valeur (sans dépasser ses PV).
## Sur un adversaire : valeur réduite. Sur son propre camp ou celui d'un allié : négatif.
static func _single_damage_value(amount: float, unit: CombatUnit, field: Field, caster: PlayerState, unblockable: bool) -> float:
	if unit == null or not unit.is_alive():
		return 0.0
	var effective: float = amount if unblockable else amount * unit.statuses.damage_taken_multiplier()
	effective = minf(effective, unit.health)
	var own_field: bool = field.owner_id == caster.id
	if unit.side == CombatUnit.Side.MONSTER:
		return effective if own_field else -effective
	if own_field:
		return -effective
	return effective * HERO_DAMAGE_FACTOR + (_kill_value(unit) if effective >= unit.health else 0.0)


## Tuer le personnage d'un adversaire lui fait perdre RESPAWN_DELAY secondes de combat.
static func _kill_value(unit: CombatUnit) -> float:
	return _damage_per_second(unit) * CombatConfig.RESPAWN_DELAY * SABOTAGE_FACTOR


# --- Statuts ------------------------------------------------------------------

## Un statut est bon ou mauvais selon le camp qui le reçoit : on le compte du point de vue du lanceur.
static func _status_value(status: StatusData, unit: CombatUnit, field: Field, caster: PlayerState) -> float:
	if unit == null or not unit.is_alive():
		return 0.0
	var helps_holder: float = _benefit_to_holder(status, unit, field)
	var is_friendly: bool = field.owner_id == caster.id and unit.side == CombatUnit.Side.HERO
	var is_own_monster: bool = field.owner_id == caster.id and unit.side == CombatUnit.Side.MONSTER
	if is_friendly:
		return helps_holder
	if is_own_monster:
		return -helps_holder
	return -helps_holder * SABOTAGE_FACTOR


static func _side_status_value(status: StatusData, unit: CombatUnit, field: Field, caster: PlayerState) -> float:
	if unit == null:
		return 0.0
	var total: float = 0.0
	for member: CombatUnit in field.get_side_of(unit):
		total += _status_value(status, member, field, caster)
	return total


## Ce que le statut rapporte à celui qui le porte (négatif pour un débuff).
static func _benefit_to_holder(status: StatusData, unit: CombatUnit, field: Field) -> float:
	var duration: float = status.duration
	var own_dps: float = _damage_per_second(unit)
	var foe_dps: float = _opposing_damage_per_second(unit, field)
	var value: float = 0.0
	value += (status.damage_mult - 1.0) * own_dps * duration
	value += (status.attack_speed_mult - 1.0) * own_dps * duration
	value += status.crit_bonus * (CombatConfig.CRITICAL_MULTIPLIER - 1.0) * own_dps * duration
	value -= status.damage_per_second * duration
	value -= status.damage_on_expire
	value += _offense_flag_value(status, own_dps, duration)
	value += _defense_value(status, foe_dps, duration) * _danger(unit)
	if status.on_hit_status:
		var hits: float = duration / unit.get_attack_interval()
		value += hits * status.on_hit_status.damage_per_second * status.on_hit_status.duration
	return value


## Aveuglement, étourdissement : dégâts que le porteur ne fait plus.
static func _offense_flag_value(status: StatusData, own_dps: float, duration: float) -> float:
	if status.has_flag(StatusData.Flag.BLIND) or status.has_flag(StatusData.Flag.STUN):
		return -own_dps * duration * DEFENSIVE_FACTOR
	return 0.0


## Dégâts reçus en moins (ou en plus pour une marque) : réduction, bouclier, esquive, soins.
static func _defense_value(status: StatusData, foe_dps: float, duration: float) -> float:
	var value: float = (1.0 - status.damage_taken_mult) * foe_dps * duration
	value += status.shield_amount + status.heal_per_second * duration
	if status.has_flag(StatusData.Flag.DODGE_ALL) or status.has_flag(StatusData.Flag.DAMAGE_IMMUNE):
		value += foe_dps * duration * DEFENSIVE_FACTOR
	if status.has_flag(StatusData.Flag.DODGE_NEXT):
		value += foe_dps * DEFENSIVE_FACTOR + status.riposte_damage
	return value


## Un héros blessé tient plus à sa défense : ×0,5 en pleine forme, jusqu'à ×1,5 presque mort.
## Pour un monstre, la défense compte normalement.
static func _danger(unit: CombatUnit) -> float:
	if unit.side != CombatUnit.Side.HERO:
		return 1.0
	return clampf(1.5 - unit.get_health_ratio(), 0.5, 1.5)


## Soigner son camp : les PV manquants rendus. Soigner un adversaire l'aide : négatif.
static func _heal_value(effect: HealEffect, unit: CombatUnit, field: Field, caster: PlayerState) -> float:
	if unit == null or not unit.is_alive() or unit.side != CombatUnit.Side.HERO:
		return 0.0
	var healed: float = minf(effect.amount, unit.get_max_health() - unit.health)
	return healed if field.owner_id == caster.id else -healed


## Dissipation : utile sur son propre camp s'il porte des débuffs ; ailleurs, elle aiderait l'autre.
static func _purge_value(unit: CombatUnit, field: Field, caster: PlayerState) -> float:
	if unit == null or field.owner_id != caster.id or unit.side != CombatUnit.Side.HERO:
		return 0.0
	var removed: int = 0
	for instance: StatusInstance in unit.statuses.get_instances():
		if instance.data.category in PurgeEffect.PURGED_CATEGORIES:
			removed += 1
	return removed * PURGE_VALUE_PER_STATUS


## Cartes bloquées, et mana qui ne se recharge plus si la carte le gèle aussi.
static func _lock_value(effect: LockCardsEffect) -> float:
	var value: float = effect.duration * LOCK_VALUE_PER_SECOND
	if effect.freezes_mana:
		value += effect.duration * CombatConfig.MANA_PER_SECOND * STOLEN_MANA_VALUE
	return value


static func _pickpocket_value(effect: PickpocketEffect, target_player: PlayerState, caster: PlayerState) -> float:
	if target_player == caster:
		return 0.0
	var stolen: int = floori(target_player.mana)
	if stolen > 0:
		return stolen * STOLEN_MANA_VALUE
	return effect.fallback_damage * SABOTAGE_FACTOR


# --- Outils -----------------------------------------------------------------

static func _damage_per_second(unit: CombatUnit) -> float:
	return unit.data.attack_damage * unit.statuses.damage_multiplier() / unit.get_attack_interval()


## Dégâts par seconde de ce qui frappe l'unité : le monstre pour un héros, les héros pour un monstre.
static func _opposing_damage_per_second(unit: CombatUnit, field: Field) -> float:
	var opponents: Array[CombatUnit] = field.get_monster_side() if unit.side == CombatUnit.Side.HERO else field.get_heroes()
	var total: float = 0.0
	for opponent: CombatUnit in opponents:
		if opponent.is_alive():
			total += _damage_per_second(opponent)
	return total


## Sans unité ciblée (carte jouée sur son terrain), le statut va sur le personnage.
static func _status_holder(target: CardTarget, field: Field) -> CombatUnit:
	return target.unit if target.unit else field.character


static func _no_units() -> Array[CombatUnit]:
	var units: Array[CombatUnit] = []
	return units
