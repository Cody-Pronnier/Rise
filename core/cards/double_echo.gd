class_name DoubleEcho
extends RefCounted
## Le double du Mage (Dédoublement) répète les cartes de son maître tant qu'il est en vie :
## - dégâts et soins rejoués à ECHO_POWER (50 %) sur la même cible, sans les statuts qu'ils posent ;
## - un buff joué sur le personnage est aussi posé sur le double (bouclier réduit de moitié) ;
## - les autres effets (contrôles, blocage, vol, invocations…) et les ultimes ne sont pas copiés.
## Fonctions statiques sans état, appelées par CombatRound après chaque carte jouée.

const ECHO_POWER: float = 0.5


## Le double vivant sur ce terrain, ou null.
static func find_double(field: Field) -> CombatUnit:
	for companion: CombatUnit in field.get_companions_tagged(SummonDoubleEffect.TAG):
		if companion.is_alive():
			return companion
	return null


static func echo(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> void:
	var own_field: Field = combat_round.fields[caster_id]
	var double: CombatUnit = find_double(own_field)
	if double == null or card.is_ultimate:
		return
	_copy_buffs(card, target, own_field, double)
	var echo_card: CardData = _damage_and_heal_copy(card)
	if echo_card:
		CardPlayService.resolve_echo(combat_round, caster_id, echo_card, target, ECHO_POWER)


## Les buffs joués sur le personnage du lanceur vont aussi sur le double.
static func _copy_buffs(card: CardData, target: CardTarget, own_field: Field, double: CombatUnit) -> void:
	if target.player_id != own_field.owner_id or target.unit != own_field.character:
		return
	for effect: CardEffect in card.effects:
		var status_effect := effect as ApplyStatusEffect
		if status_effect and status_effect.status.category == StatusData.Category.BUFF:
			double.apply_status(_halved_shield(status_effect.status))


static func _halved_shield(status: StatusData) -> StatusData:
	if status.shield_amount <= 0.0:
		return status
	var copy := status.duplicate() as StatusData
	copy.shield_amount *= ECHO_POWER
	return copy


## Une copie de la carte qui ne garde que ses dégâts et ses soins (null s'il n'y en a pas).
## Les dégâts sont réduits par la puissance de l'écho ; les soins, qui l'ignorent, sont réduits ici.
static func _damage_and_heal_copy(card: CardData) -> CardData:
	var effects: Array[CardEffect] = []
	for effect: CardEffect in card.effects:
		if effect is DamageEffect:
			effects.append(_without_status(effect as DamageEffect))
		elif effect is ChainDamageEffect or effect is DelayedDamageEffect:
			effects.append(effect)
		elif effect is HealEffect:
			var heal := (effect as HealEffect).duplicate() as HealEffect
			heal.amount *= ECHO_POWER
			effects.append(heal)
	if effects.is_empty():
		return null
	var copy := card.duplicate() as CardData
	copy.effects = effects
	return copy


## Les dégâts sont copiés, pas le statut qu'ils posent (brûlure, givre…).
static func _without_status(effect: DamageEffect) -> DamageEffect:
	if effect.status_on_hit == null:
		return effect
	var copy := effect.duplicate() as DamageEffect
	copy.status_on_hit = null
	return copy
