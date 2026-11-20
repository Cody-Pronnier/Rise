class_name RoundRanking
extends RefCounted
## Classement en direct de la manche : d'abord les joueurs qui ont terminé (dans leur ordre d'arrivée),
## puis les autres par progression (monstres tués + PV retirés). À égalité, l'id départage :
## le résultat est identique sur toutes les machines.


## Ids des joueurs, du premier au dernier.
static func order(combat_round: CombatRound) -> Array[int]:
	var ids: Array[int] = []
	ids.assign(combat_round.players.keys())
	ids.sort_custom(func(a: int, b: int) -> bool: return _is_ahead(combat_round, a, b))
	return ids


## Place du joueur dans la manche (1 = premier).
static func position_of(combat_round: CombatRound, player_id: int) -> int:
	return order(combat_round).find(player_id) + 1


static func _is_ahead(combat_round: CombatRound, a: int, b: int) -> bool:
	var rank_a: int = combat_round.get_rank(a)
	var rank_b: int = combat_round.get_rank(b)
	if rank_a > 0 or rank_b > 0:
		if rank_a > 0 and rank_b > 0:
			return rank_a < rank_b
		return rank_a > 0
	var progress_a: float = combat_round.fields[a].get_progress()
	var progress_b: float = combat_round.fields[b].get_progress()
	if not is_equal_approx(progress_a, progress_b):
		return progress_a > progress_b
	return a < b
