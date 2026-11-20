class_name FriendInviteRow
extends PanelContainer
## Ligne d'un ami connecté : avatar Steam, nom, statut et bouton « Inviter ».
## Construite entièrement en code ; prévient sa fenêtre par invite_pressed.

signal invite_pressed(friend_id: int)

const AVATAR_SIZE := Vector2(40, 40)
const PLAYING_COLOR := Color(0.55, 0.95, 0.6)
const INVITED_TEXT: String = "Invité ✓"

var _friend: SteamFriend
var _avatar := TextureRect.new()
var _invite_button := Button.new()


func _init(friend: SteamFriend) -> void:
	_friend = friend
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.box(UiStyle.PANEL_DARK, 10, Color(UiStyle.SECONDARY_BORDER, 0.5), 1), 12.0, 8.0))
	add_child(_build_content())


func _ready() -> void:
	SteamService.avatar_loaded.connect(_on_avatar_loaded)
	_avatar.texture = SteamService.get_avatar(_friend.steam_id)
	if _avatar.texture == null:
		SteamService.request_avatar(_friend.steam_id)


func mark_invited() -> void:
	_invite_button.text = INVITED_TEXT
	_invite_button.disabled = true


func _build_content() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_build_avatar())
	row.add_child(_build_labels())
	row.add_child(_build_invite_button())
	return row


func _build_avatar() -> TextureRect:
	_avatar.custom_minimum_size = AVATAR_SIZE
	_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return _avatar


func _build_labels() -> VBoxContainer:
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 0)
	labels.add_child(_create_label(_friend.display_name, 18, UiStyle.BUTTON_TEXT))
	labels.add_child(_create_label("Joue à Rise" if _friend.is_playing_game else "En ligne", 14, PLAYING_COLOR if _friend.is_playing_game else UiStyle.TEXT_DIM))
	return labels


func _build_invite_button() -> Button:
	_invite_button.text = "Inviter"
	_invite_button.focus_mode = Control.FOCUS_NONE
	_invite_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(_invite_button, true)
	_invite_button.add_theme_font_size_override("font_size", 15)
	_invite_button.pressed.connect(invite_pressed.emit.bind(_friend.steam_id))
	return _invite_button


func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_avatar_loaded(steam_id: int, texture: Texture2D) -> void:
	if steam_id == _friend.steam_id:
		_avatar.texture = texture
