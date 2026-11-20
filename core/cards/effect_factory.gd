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
