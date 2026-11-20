class_name RoundScoring
extends RefCounted
## Classement et points de fin de manche. Fonctions pures.

static func compute(player_ids: Array, finish_order: Array[int]) -> Array[RoundResult]:
	var results: Array[RoundResult] = []
	for index: int in finish_order.size():
		var rank: int = index + 1
		results.append(RoundResult.new(finish_order[index], rank, points_for_rank(rank), true))
	for player_id: int in player_ids:
		if not finish_order.has(player_id):
			results.append(RoundResult.new(player_id, finish_order.size() + 1, 0, false))
	return results


static func points_for_rank(rank: int) -> int:
	var index: int = rank - 1
	if index < 0 or index >= CombatConfig.POINTS_BY_RANK.size():
		return 0
	return CombatConfig.POINTS_BY_RANK[index]
