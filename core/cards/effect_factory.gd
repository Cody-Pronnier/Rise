class_name EffectFactory
extends RefCounted
## Raccourcis pour écrire les cartes des classes de façon lisible.


static func damage(amount: float, hits: int = 1, status_on_hit: StatusData = null) -> DamageEffect:
	var effect := DamageEffect.new()
	effect.amount = amount
	effect.hits = hits
	effect.status_on_hit = status_on_hit
	return effect


static func true_damage(amount: float) -> DamageEffect:
	var effect: DamageEffect = damage(amount)
	effect.unblockable = true
	effect.undodgeable = true
	return effect


static func piercing_damage(amount: float) -> DamageEffect:
	var effect: DamageEffect = damage(amount)
	effect.undodgeable = true
	return effect


## Dégâts à l'unité ciblée et à tout son camp.
static func side_damage(amount: float, status_on_hit: StatusData = null) -> DamageEffect:
	var effect: DamageEffect = damage(amount, 1, status_on_hit)
	effect.scope = DamageEffect.Scope.TARGET_SIDE
	return effect


## Dégâts aux ennemis uniquement : le monstre de ton terrain, les héros des autres terrains.
static func enemy_damage(amount: float) -> DamageEffect:
	var effect: DamageEffect = damage(amount)
	effect.scope = DamageEffect.Scope.ENEMIES
	return effect


## Dégâts multipliés si la cible porte un des statuts donnés.
static func damage_bonus_if(effect: DamageEffect, statuses: Array[StringName], multiplier: float) -> DamageEffect:
	effect.bonus_if_statuses = statuses
	effect.bonus_multiplier = multiplier
	return effect


## Dégâts augmentés pour chaque type de dégâts sur la durée présent sur la cible.
static func damage_per_damage_over_time(amount: float, bonus: float) -> DamageEffect:
	var effect: DamageEffect = damage(amount)
	effect.bonus_per_damage_over_time = bonus
	return effect


static func delayed_damage(amount: float, delay: float) -> DelayedDamageEffect:
	var effect := DelayedDamageEffect.new()
	effect.amount = amount
	effect.delay = delay
	return effect


static func pickpocket(points: int, fallback_damage: float) -> PickpocketEffect:
	var effect := PickpocketEffect.new()
	effect.stolen_points = points
	effect.fallback_damage = fallback_damage
	return effect


static func heal(amount: float) -> HealEffect:
	var effect := HealEffect.new()
	effect.amount = amount
	return effect


## Soin qui épargne les monstres (pour les cartes de zone).
static func heal_heroes(amount: float) -> HealEffect:
	var effect: HealEffect = heal(amount)
	effect.heroes_only = true
	return effect


static func status(status_data: StatusData) -> ApplyStatusEffect:
	var effect := ApplyStatusEffect.new()
	effect.status = status_data
	return effect


static func purge() -> PurgeEffect:
	return PurgeEffect.new()


static func chain_damage(amount: float, max_targets: int) -> ChainDamageEffect:
	var effect := ChainDamageEffect.new()
	effect.amount = amount
	effect.max_targets = max_targets
	return effect


static func lock_cards(duration: float) -> LockCardsEffect:
	var effect := LockCardsEffect.new()
	effect.duration = duration
	return effect


static func protect_field(duration: float, hides_progress: bool) -> ProtectFieldEffect:
	var effect := ProtectFieldEffect.new()
	effect.duration = duration
	effect.hides_progress = hides_progress
	return effect


static func summon(companion: UnitData) -> SummonCompanionEffect:
	var effect := SummonCompanionEffect.new()
	effect.companion = companion
	return effect


## Invoque `count` unités aux côtés de l'unité ciblée (camp des héros ou du monstre).
static func summon_on_field(companion: UnitData, count: int = 1) -> SummonOnFieldEffect:
	var effect := SummonOnFieldEffect.new()
	effect.companion = companion
	effect.count = count
	return effect


## Statut pour l'unité ciblée et tout son camp.
static func status_to_side(status_data: StatusData) -> ApplyStatusToSideEffect:
	var effect := ApplyStatusToSideEffect.new()
	effect.status = status_data
	return effect


static func fuse_minions(base: UnitData, bonus: float) -> FuseMinionsEffect:
	var effect := FuseMinionsEffect.new()
	effect.base = base
	effect.bonus = bonus
	return effect


static func recruit(mercenary: UnitData) -> RecruitEffect:
	var effect := RecruitEffect.new()
	effect.mercenary = mercenary
	return effect


static func gain_gold(amount: int) -> GainGoldEffect:
	var effect := GainGoldEffect.new()
	effect.amount = amount
	return effect
