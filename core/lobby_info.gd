class_name LobbyInfo
extends RefCounted
## Données d'un salon affiché dans la liste de recherche.

var id: int
var name: String
## Joueurs humains présents.
var member_count: int
## Places totales choisies par l'hôte (humains + bots + places libres).
var max_members: int
var bot_count: int
## Un mot de passe est demandé pour entrer.
var is_locked: bool


func _init(p_id: int, p_name: String, p_member_count: int, p_max_members: int, p_bot_count: int = 0, p_is_locked: bool = false) -> void:
	id = p_id
	name = p_name
	member_count = p_member_count
	max_members = p_max_members
	bot_count = p_bot_count
	is_locked = p_is_locked


func is_full() -> bool:
	return member_count + bot_count >= max_members
