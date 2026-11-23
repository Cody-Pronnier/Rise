class_name CardPlayService
extends RefCounted
## Règles pour jouer une carte : vérification de la cible puis résolution.
## Fonctions statiques sans état, appelées par CombatRound.play_card().
## Une carte ALL_FIELDS est résolue une fois par terrain touché.


static func get_play_error(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> String:
	if combat_round.is_over:
		return "La manche est terminée."
	if combat_round.is_preparing():
		return "Les combats n'ont pas encore commencé."
	var caster: PlayerState = combat_round.players.get(caster_id)
	if caster == null or not caster.has_card(card):
		return "Tu n'as plus cette carte."
	if caster.is_card_locked():
		return "Tes cartes sont bloquées."
	if not caster.can_afford(card):
		return "Pas assez de mana (%d / %d)." % [floori(caster.mana), card.cost]
	if card.target_mode == CardData.TargetMode.ALL_FIELDS:
		return ""
	var error: String = _get_target_error(combat_round, caster_id, card, target)
	return error if not error.is_empty() else _get_effects_error(combat_round, caster_id, card, target)


## Certains effets ont leurs propres conditions (ex : le joueur ciblé doit avoir un allié).
static func _get_effects_error(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> String:
	var context: CardContext = _build_context(combat_round, caster_id, card, target)
	for effect: CardEffect in card.effects:
		var error: String = effect.get_play_error(context)
		if not error.is_empty():
			return error
	return ""


static func resolve(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> void:
	combat_round.players[caster_id].spend_mana(card.cost)
	combat_round.players[caster_id].consume_card(card)
	_apply_effects(combat_round, caster_id, card, target, 1.0)


## Carte rejouée sans coût ni carte consommée, avec une puissance réduite (ex : le double du Mage).
static func resolve_echo(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget, power_factor: float) -> void:
	_apply_effects(combat_round, caster_id, card, target, power_factor)


static func _apply_effects(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget, power_factor: float) -> void:
	if card.target_mode == CardData.TargetMode.ALL_FIELDS:
		for field_id: int in affected_field_ids(combat_round, caster_id, card):
			card.resolve(_build_context(combat_round, caster_id, card, CardTarget.for_player(field_id), power_factor))
	else:
		card.resolve(_build_context(combat_round, caster_id, card, target, power_factor))


## Terrains touchés par une carte ALL_FIELDS : tous ceux encore en combat, sauf les terrains
## protégés des autres joueurs (Invisibilité, Duel) et, pour une carte offensive, celui de son allié.
static func affected_field_ids(combat_round: CombatRound, caster_id: int, card: CardData) -> Array[int]:
	var ids: Array[int] = []
	for field_id: int in combat_round.fields:
		var field: Field = combat_round.fields[field_id]
		if field.is_finished():
			continue
		if field_id != caster_id and field.is_protected():
			continue
		if not card.is_beneficial and combat_round.alliances.are_allied(caster_id, field_id):
			continue
		ids.append(field_id)
	return ids


static func _get_target_error(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> String:
	var field: Field = combat_round.fields.get(target.player_id)
	if field == null:
		return "Cible invalide."
	if card.target_mode == CardData.TargetMode.SELF and target.player_id != caster_id:
		return "Cette carte se joue uniquement sur ton terrain."
	if target.player_id != caster_id and field.is_protected():
		return "Ce terrain est protégé."
	if not card.is_beneficial and combat_round.alliances.are_allied(caster_id, target.player_id):
		return "Tu ne peux pas attaquer ton allié."
	if field.is_finished():
		return "Ce joueur a déjà terminé sa manche."
	if card.target_mode == CardData.TargetMode.UNIT and not _is_valid_unit(field, target.unit):
		return "Choisis une unité vivante."
	if _is_shielded_character(caster_id, card, target, field):
		return "Son mercenaire le protège : vise une autre unité."
	return ""


## Personnage intouchable par les cartes des autres joueurs (Marchand avec mercenaire).
static func _is_shielded_character(caster_id: int, card: CardData, target: CardTarget, field: Field) -> bool:
	return card.target_mode == CardData.TargetMode.UNIT and target.player_id != caster_id \
		and target.unit == field.character and field.is_character_shielded()


static func _is_valid_unit(field: Field, unit: CombatUnit) -> bool:
	return unit != null and unit.is_alive() and field.contains(unit)


static func _build_context(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget, power_factor: float = 1.0) -> CardContext:
	var field: Field = combat_round.fields[target.player_id]
	var context := CardContext.new(
		combat_round.players[caster_id],
		combat_round.players[target.player_id],
		field,
		_resolve_units(card, target, field),
		combat_round
	)
	context.power = (1.0 + CatchUpBoost.bonus_for(combat_round, caster_id, card, target)) * power_factor
	return context


static func _resolve_units(card: CardData, target: CardTarget, field: Field) -> Array[CombatUnit]:
	match card.target_mode:
		CardData.TargetMode.UNIT:
			var units: Array[CombatUnit] = [target.unit]
			return units
		CardData.TargetMode.FIELD, CardData.TargetMode.ALL_FIELDS:
			return field.get_all_units()
		_:
			return field.get_heroes()
