class_name RoundResult
extends RefCounted
## Résultat d'un joueur en fin de manche.

var player_id: int
var rank: int
var points: int
var has_finished: bool
## Allié avec qui les points ont été partagés, ou -1.
var ally_id: int = -1


func _init(p_player_id: int, p_rank: int, p_points: int, p_has_finished: bool) -> void:
	player_id = p_player_id
	rank = p_rank
	points = p_points
	has_finished = p_has_finished
