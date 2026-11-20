extends Node
## Recherche des salons publics de notre jeu.

signal lobbies_found(lobbies: Array[LobbyInfo])


func _ready() -> void:
	Steam.lobby_match_list.connect(_on_lobby_match_list)


func request_lobbies() -> void:
	if not SteamService.is_ready:
		var no_lobbies: Array[LobbyInfo] = []
		lobbies_found.emit(no_lobbies)
		return
	_apply_search_filters()
	Steam.requestLobbyList()


func _apply_search_filters() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter(
		GameConfig.LOBBY_GAME_TAG_KEY,
		GameConfig.LOBBY_GAME_TAG_VALUE,
		Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.addRequestLobbyListFilterSlotsAvailable(1)
	Steam.addRequestLobbyListResultCountFilter(GameConfig.MAX_LOBBY_RESULTS)


func _on_lobby_match_list(lobby_ids: Array) -> void:
	lobbies_found.emit(_build_lobby_infos(lobby_ids))


func _build_lobby_infos(lobby_ids: Array) -> Array[LobbyInfo]:
	var lobbies: Array[LobbyInfo] = []
	for lobby_id: int in lobby_ids:
		lobbies.append(_build_lobby_info(lobby_id))
	return lobbies


func _build_lobby_info(lobby_id: int) -> LobbyInfo:
	var max_players: int = Steam.getLobbyData(lobby_id, GameConfig.LOBBY_MAX_PLAYERS_KEY).to_int()
	return LobbyInfo.new(
		lobby_id,
		Steam.getLobbyData(lobby_id, GameConfig.LOBBY_NAME_KEY),
		Steam.getNumLobbyMembers(lobby_id),
		max_players if max_players > 0 else Steam.getLobbyMemberLimit(lobby_id),
		Steam.getLobbyData(lobby_id, GameConfig.LOBBY_BOTS_KEY).to_int(),
		Steam.getLobbyData(lobby_id, GameConfig.LOBBY_LOCKED_KEY) == "1"
	)
