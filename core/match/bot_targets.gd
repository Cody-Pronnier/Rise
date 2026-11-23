class_name BotTargets
extends RefCounted
## Cibles qu'un bot envisage pour une carte : son propre terrain (personnage, compagnons, monstre)
## et les adversaires les plus menaçants (le meneur et celui juste devant soi).
## Partagé par BotPlayer (jouer) et BotTrader (estimer la valeur d'une carte avant un échange).


## opponents : adversaires menaçants déjà calculés (vide = les calculer), pour éviter de refaire
## le classement pour chaque carte.
static func for_card(card: CardData, combat_round: CombatRound, player_id: int, opponents: Array[int] = []) -> Array[CardTarget]:
	if opponents.is_empty():
		opponents = threatening_opponents(combat_round, player_id)
	var targets: Array[CardTarget] = []
	match card.target_mode:
		CardData.TargetMode.SELF, CardData.TargetMode.ALL_FIELDS:
			targets.append(CardTarget.for_player(player_id))
		CardData.TargetMode.PLAYER, CardData.TargetMode.FIELD:
			targets.append(CardTarget.for_player(player_id))
			for opponent_id: int in opponents:
				targets.append(CardTarget.for_player(opponent_id))
		CardData.TargetMode.UNIT:
			for unit: CombatUnit in combat_round.fields[player_id].get_all_units():
				if unit.is_alive():
					targets.append(CardTarget.for_unit(player_id, unit))
			for opponent_id: int in opponents:
				var target: CardTarget = opponent_unit(combat_round, opponent_id)
				if target:
					targets.append(target)
	return targets


## Le meneur et l'adversaire juste devant soi (sans doublon), parmi ceux qu'on peut viser.
static func threatening_opponents(combat_round: CombatRound, player_id: int) -> Array[int]:
	var opponents: Array[int] = []
	var ahead_of_me: int = -1
	for other_id: int in RoundRanking.order(combat_round):
		if other_id == player_id:
			break
		if is_targetable_opponent(combat_round, player_id, other_id):
			if opponents.is_empty():
				opponents.append(other_id)
			ahead_of_me = other_id
	if ahead_of_me != -1 and not opponents.has(ahead_of_me):
		opponents.append(ahead_of_me)
	if opponents.is_empty():
		var fallback: int = _first_targetable(combat_round, player_id)
		if fallback != -1:
			opponents.append(fallback)
	return opponents


## Le personnage de l'adversaire, ou son mercenaire si le personnage est protégé.
static func opponent_unit(combat_round: CombatRound, opponent_id: int) -> CardTarget:
	var field: Field = combat_round.fields[opponent_id]
	if field.is_character_shielded():
		var shields: Array[CombatUnit] = field.get_companions_tagged(&"mercenary")
		return CardTarget.for_unit(opponent_id, shields[0]) if not shields.is_empty() else null
	return CardTarget.for_unit(opponent_id, field.character)


static func is_targetable_opponent(combat_round: CombatRound, player_id: int, other_id: int) -> bool:
	var field: Field = combat_round.fields[other_id]
	return other_id != player_id and not field.is_protected() and not field.is_finished() \
		and not combat_round.alliances.are_allied(player_id, other_id)


## Part de la manche faite par ce joueur (0 = début, 1 = terminé).
static func progress_ratio(combat_round: CombatRound, player_id: int) -> float:
	var field: Field = combat_round.fields[player_id]
	return field.get_progress() / maxf(field.total_monsters, 1.0)


## Si personne n'est devant soi (on mène), le suivant au classement.
static func _first_targetable(combat_round: CombatRound, player_id: int) -> int:
	for other_id: int in RoundRanking.order(combat_round):
		if is_targetable_opponent(combat_round, player_id, other_id):
			return other_id
	return -1
