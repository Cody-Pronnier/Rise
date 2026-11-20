class_name AllianceRegistry
extends RefCounted
## Alliances de la manche en cours.
## Un joueur ne peut avoir qu'une seule alliance par manche, même après l'avoir rompue.

signal alliance_formed(first_id: int, second_id: int)
signal alliance_broken(breaker_id: int, ally_id: int)

var _ally_of: Dictionary[int, int] = {}
var _had_alliance: Dictionary[int, bool] = {}


func ally_of(player_id: int) -> int:
	return _ally_of.get(player_id, -1)


## Vrai si le joueur a déjà eu une alliance cette manche (même rompue depuis).
func had_alliance(player_id: int) -> bool:
	return _had_alliance.has(player_id)


func are_allied(first_id: int, second_id: int) -> bool:
	return first_id != second_id and ally_of(first_id) == second_id


## Renvoie "" si les deux joueurs peuvent s'allier, sinon la raison.
func get_formation_error(first_id: int, second_id: int) -> String:
	if first_id == second_id:
		return "Impossible de s'allier avec soi-même."
	if _had_alliance.has(first_id) or _had_alliance.has(second_id):
		return "Une alliance par joueur et par manche seulement."
	return ""


func form(first_id: int, second_id: int) -> void:
	_ally_of[first_id] = second_id
	_ally_of[second_id] = first_id
	_had_alliance[first_id] = true
	_had_alliance[second_id] = true
	alliance_formed.emit(first_id, second_id)


## Alliance imposée (carte « Pacte forcé ») : ignore la limite d'une alliance par manche
## et rompt l'alliance en cours du joueur ciblé. Le lanceur ne doit pas déjà avoir d'allié.
func get_forced_error(caster_id: int, target_id: int) -> String:
	if caster_id == target_id:
		return "Choisis un autre joueur."
	if are_allied(caster_id, target_id):
		return "Vous êtes déjà alliés."
	if ally_of(caster_id) != -1:
		return "Romps d'abord ton alliance actuelle."
	return ""


func force(caster_id: int, target_id: int) -> void:
	if ally_of(target_id) != -1:
		break_alliance(target_id)
	form(caster_id, target_id)


## Renvoie l'ancien allié, ou -1 s'il n'y avait pas d'alliance.
func break_alliance(breaker_id: int) -> int:
	var ally_id: int = ally_of(breaker_id)
	if ally_id == -1:
		return -1
	_ally_of.erase(breaker_id)
	_ally_of.erase(ally_id)
	alliance_broken.emit(breaker_id, ally_id)
	return ally_id


## Les alliés encore unis en fin de manche reçoivent chacun la moyenne de leurs points (arrondie au-dessus).
func share_points(results: Array[RoundResult]) -> void:
	var by_player: Dictionary[int, RoundResult] = {}
	for result: RoundResult in results:
		by_player[result.player_id] = result
	for player_id: int in _ally_of:
		var ally_id: int = _ally_of[player_id]
		if player_id < ally_id and by_player.has(player_id) and by_player.has(ally_id):
			_share_between(by_player[player_id], by_player[ally_id])


func _share_between(first: RoundResult, second: RoundResult) -> void:
	var shared: int = ceili((first.points + second.points) / 2.0)
	first.points = shared
	second.points = shared
	first.ally_id = second.player_id
	second.ally_id = first.player_id
