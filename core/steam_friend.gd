class_name SteamFriend
extends RefCounted
## Ami Steam connecté, proposé dans la fenêtre d'invitation.

var steam_id: int
var display_name: String
## L'ami a déjà Rise lancé : il peut rejoindre tout de suite.
var is_playing_game: bool


func _init(p_steam_id: int, p_display_name: String, p_is_playing_game: bool) -> void:
	steam_id = p_steam_id
	display_name = p_display_name
	is_playing_game = p_is_playing_game
