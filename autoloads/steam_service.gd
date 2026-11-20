extends Node
## Initialise l'API Steam et fait tourner ses callbacks.
## Ne sait rien des lobbies : il fournit l'état de Steam et l'identité des joueurs (nom, avatar).

signal avatar_loaded(steam_id: int, texture: Texture2D)

const INIT_RESULT_OK: int = 0
## EAvatarSize : 1 = petit (32 px), 2 = moyen (64 px), 3 = grand (184 px).
const AVATAR_SIZE_MEDIUM: int = 2
const BYTES_PER_PIXEL: int = 4
## EFriendFlags : k_EFriendFlagImmediate = amis « normaux ».
const FRIEND_FLAG_IMMEDIATE: int = 4
## EPersonaState : 0 = hors ligne.
const PERSONA_STATE_OFFLINE: int = 0

var is_ready: bool = false
var init_error: String = ""
var local_steam_id: int = 0
var local_persona_name: String = ""

var _avatars: Dictionary[int, Texture2D] = {}
var _pending_avatars: Dictionary[int, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_expose_app_id()
	_initialize_steam()
	Steam.avatar_loaded.connect(_on_avatar_loaded)


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func get_persona_name(steam_id: int) -> String:
	return Steam.getFriendPersonaName(steam_id)


## Amis connectés, ceux qui jouent déjà à Rise en premier, puis par ordre alphabétique.
func get_online_friends() -> Array[SteamFriend]:
	var friends: Array[SteamFriend] = []
	if not is_ready:
		return friends
	for index: int in Steam.getFriendCount(FRIEND_FLAG_IMMEDIATE):
		var steam_id: int = Steam.getFriendByIndex(index, FRIEND_FLAG_IMMEDIATE)
		if Steam.getFriendPersonaState(steam_id) != PERSONA_STATE_OFFLINE:
			friends.append(SteamFriend.new(steam_id, get_persona_name(steam_id), _is_playing_our_game(steam_id)))
	friends.sort_custom(_compare_friends)
	return friends


## Avatar déjà chargé, ou null. Appeler request_avatar() puis écouter avatar_loaded.
func get_avatar(steam_id: int) -> Texture2D:
	return _avatars.get(steam_id)


func request_avatar(steam_id: int) -> void:
	if not is_ready or _avatars.has(steam_id) or _pending_avatars.has(steam_id):
		return
	_pending_avatars[steam_id] = true
	Steam.getPlayerAvatar(AVATAR_SIZE_MEDIUM, steam_id)


func _is_playing_our_game(steam_id: int) -> bool:
	var game: Dictionary = Steam.getFriendGamePlayed(steam_id)
	return int(game.get("id", 0)) == GameConfig.STEAM_APP_ID


func _compare_friends(a: SteamFriend, b: SteamFriend) -> bool:
	if a.is_playing_game != b.is_playing_game:
		return a.is_playing_game
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0


## Steam renvoie les pixels en RGBA brut ; on en fait une texture mise en cache.
func _on_avatar_loaded(steam_id: int, size: int, data: Variant) -> void:
	_pending_avatars.erase(steam_id)
	var pixels := PackedByteArray(data)
	if size <= 0 or pixels.size() != size * size * BYTES_PER_PIXEL:
		return
	var texture := ImageTexture.create_from_image(Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, pixels))
	_avatars[steam_id] = texture
	avatar_loaded.emit(steam_id, texture)


func _expose_app_id() -> void:
	var app_id: String = str(GameConfig.STEAM_APP_ID)
	OS.set_environment("SteamAppId", app_id)
	OS.set_environment("SteamGameId", app_id)


func _initialize_steam() -> void:
	var result: Dictionary = Steam.steamInitEx()
	if result.get("status", -1) != INIT_RESULT_OK:
		_mark_as_failed(str(result.get("verbal", "erreur inconnue")))
		return
	_cache_local_user()
	is_ready = true


func _cache_local_user() -> void:
	local_steam_id = Steam.getSteamID()
	local_persona_name = Steam.getPersonaName()


func _mark_as_failed(reason: String) -> void:
	init_error = reason
	set_process(false)
	push_warning("Initialisation de Steam impossible : %s" % reason)
