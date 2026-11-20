class_name LobbyMember
extends RefCounted
## Données d'un joueur présent dans le salon courant.

var steam_id: int
var display_name: String
var is_host: bool
var is_ready: bool


func _init(p_steam_id: int, p_display_name: String, p_is_host: bool, p_is_ready: bool) -> void:
	steam_id = p_steam_id
	display_name = p_display_name
	is_host = p_is_host
	is_ready = p_is_ready
