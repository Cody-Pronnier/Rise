extends Node
## Envoi et réception de messages entre membres du salon via le P2P de Steam.
## Les messages sont des Dictionary sérialisés avec var_to_bytes (jamais d'objets).
## Canal fiable et ordonné : un message arrive une seule fois et dans l'ordre d'envoi.

signal message_received(sender_id: int, message: Dictionary)

const CHANNEL: int = 0
## EP2PSend : k_EP2PSendReliable.
const SEND_RELIABLE: int = 2
const MAX_PACKETS_PER_FRAME: int = 128


func _ready() -> void:
	Steam.p2p_session_request.connect(_on_session_request)
	Steam.p2p_session_connect_fail.connect(_on_session_connect_fail)


func _process(_delta: float) -> void:
	if SteamService.is_ready:
		_read_packets()


func send(target_id: int, message: Dictionary) -> void:
	Steam.sendP2PPacket(target_id, var_to_bytes(message), SEND_RELIABLE, CHANNEL)


## À tous les autres membres du salon.
func broadcast(message: Dictionary) -> void:
	var data: PackedByteArray = var_to_bytes(message)
	for member_id: int in LobbyService.get_member_ids():
		if member_id != SteamService.local_steam_id:
			Steam.sendP2PPacket(member_id, data, SEND_RELIABLE, CHANNEL)


func close_all_sessions() -> void:
	for member_id: int in LobbyService.get_member_ids():
		if member_id != SteamService.local_steam_id:
			Steam.closeP2PSessionWithUser(member_id)


func _read_packets() -> void:
	for _index: int in MAX_PACKETS_PER_FRAME:
		var size: int = Steam.getAvailableP2PPacketSize(CHANNEL)
		if size <= 0:
			return
		_handle_packet(Steam.readP2PPacket(size, CHANNEL))


## Selon la version de GodotSteam, l'expéditeur s'appelle remote_steam_id ou steam_id_remote.
func _handle_packet(packet: Dictionary) -> void:
	var sender_id: int = packet.get("remote_steam_id", packet.get("steam_id_remote", 0))
	var data: PackedByteArray = packet.get("data", PackedByteArray())
	if sender_id == 0 or data.is_empty():
		return
	var message: Variant = bytes_to_var(data)
	if message is Dictionary:
		message_received.emit(sender_id, message)


## On n'accepte les connexions que des membres du salon courant.
func _on_session_request(remote_id: int) -> void:
	if LobbyService.is_member(remote_id):
		Steam.acceptP2PSessionWithUser(remote_id)


func _on_session_connect_fail(steam_id: int, session_error: int) -> void:
	push_warning("Connexion P2P impossible avec %d (erreur %d)." % [steam_id, session_error])
