class_name ChatPanel
extends VBoxContainer
## Chat texte du salon, avec les annonces d'arrivée et de départ des joueurs.

const MAX_MESSAGE_LENGTH: int = 200
const SENDER_COLOR := Color(1.0, 0.8, 0.4)
const SYSTEM_COLOR := Color(0.55, 0.53, 0.65)

@onready var _chat_log: RichTextLabel = %ChatLog
@onready var _message_input: LineEdit = %MessageInput
@onready var _send_button: Button = %SendButton


func _ready() -> void:
	_message_input.max_length = MAX_MESSAGE_LENGTH
	_apply_styles()
	_connect_ui()
	_connect_services()


func _apply_styles() -> void:
	_chat_log.add_theme_stylebox_override("normal", UiStyle.with_margins(UiStyle.box(Color(0.03, 0.03, 0.05, 0.7), 10), 12.0, 10.0))
	UiStyle.style_line_edit(_message_input)
	_message_input.add_theme_font_size_override("font_size", 15)
	UiStyle.style_button(_send_button, true)
	_send_button.add_theme_font_size_override("font_size", 15)


func _connect_ui() -> void:
	_send_button.pressed.connect(_send_current_message)
	_message_input.text_submitted.connect(_on_message_submitted)


func _connect_services() -> void:
	LobbyChat.message_received.connect(_on_message_received)
	LobbyService.member_joined.connect(_on_member_joined)
	LobbyService.member_left.connect(_on_member_left)


func _send_current_message() -> void:
	LobbyChat.send_message(_message_input.text)
	_message_input.clear()


## add_text() n'interprète pas le BBCode : un joueur ne peut pas injecter de mise en forme.
func _append_colored(text: String, color: Color) -> void:
	_chat_log.push_color(color)
	_chat_log.add_text(text)
	_chat_log.pop()


func _append_message(sender_name: String, message: String) -> void:
	_append_colored(sender_name, SENDER_COLOR)
	_chat_log.add_text(" : " + message)
	_chat_log.newline()


func _append_system(text: String) -> void:
	_append_colored("» " + text, SYSTEM_COLOR)
	_chat_log.newline()


func _on_message_submitted(_text: String) -> void:
	_send_current_message()


func _on_message_received(sender_name: String, message: String) -> void:
	_append_message(sender_name, message)


func _on_member_joined(member_name: String) -> void:
	_append_system("%s a rejoint le salon" % member_name)


func _on_member_left(member_name: String) -> void:
	_append_system("%s a quitté le salon" % member_name)
