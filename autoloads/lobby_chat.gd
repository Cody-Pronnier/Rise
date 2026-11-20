extends Node
## Messages texte du salon courant.

signal message_received(sender_name: String, message: String)


func _ready() -> void:
	Steam.lobby_message.connect(_on_lobby_message)


func send_message(text: String) -> void:
	var message: String = text.strip_edges()
	if message.is_empty() or not LobbyService.is_in_lobby():
		return
	Steam.sendLobbyChatMsg(LobbyService.current_lobby_id, message)


## Steam renvoie aussi nos propres messages : pas besoin de les afficher localement à l'envoi.
func _on_lobby_message(lobby_id: int, sender_id: int, message: String, _chat_type: int) -> void:
	if lobby_id != LobbyService.current_lobby_id:
		return
	message_received.emit(SteamService.get_persona_name(sender_id), message)
