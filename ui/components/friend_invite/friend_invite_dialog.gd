class_name FriendInviteDialog
extends Control
## Fenêtre « Inviter des amis » : liste des amis Steam connectés avec un bouton par ami,
## plus un raccourci vers la fenêtre d'invitation de l'overlay Steam.

@onready var _panel: PanelContainer = %Panel
@onready var _friend_list: VBoxContainer = %FriendList
@onready var _empty_label: Label = %EmptyLabel
@onready var _hint_label: Label = %HintLabel
@onready var _overlay_button: Button = %OverlayButton
@onready var _refresh_button: Button = %RefreshButton
@onready var _close_button: Button = %CloseButton

var _rows: Dictionary[int, FriendInviteRow] = {}
## Amis déjà invités tant que la fenêtre vit (le bouton reste « Invité ✓ » après actualisation).
var _invited_ids: Dictionary[int, bool] = {}


func _ready() -> void:
	_apply_styles()
	_overlay_button.pressed.connect(LobbyService.open_invite_overlay)
	_refresh_button.pressed.connect(_refresh)
	_close_button.pressed.connect(hide)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func open() -> void:
	_hint_label.text = _describe_password_rule()
	_refresh()
	show()


func _apply_styles() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	UiStyle.style_button(_overlay_button, false)
	UiStyle.style_button(_refresh_button, false)
	UiStyle.style_button(_close_button, false)
	for button: Button in [_overlay_button, _refresh_button, _close_button]:
		button.add_theme_font_size_override("font_size", 16)


func _refresh() -> void:
	_clear_rows()
	var friends: Array[SteamFriend] = SteamService.get_online_friends()
	for friend: SteamFriend in friends:
		_add_row(friend)
	_empty_label.visible = friends.is_empty()


func _add_row(friend: SteamFriend) -> void:
	var row := FriendInviteRow.new(friend)
	row.invite_pressed.connect(_on_invite_pressed)
	_friend_list.add_child(row)
	_rows[friend.steam_id] = row
	if _invited_ids.has(friend.steam_id):
		row.mark_invited()


func _clear_rows() -> void:
	for row: FriendInviteRow in _rows.values():
		_friend_list.remove_child(row)
		row.queue_free()
	_rows.clear()


func _describe_password_rule() -> String:
	if not LobbyService.has_password():
		return "Tes amis reçoivent l'invitation dans Steam."
	if LobbyService.is_local_host():
		return "Les amis que tu invites ici entrent sans mot de passe."
	return "Le salon est protégé : tes invités devront saisir le mot de passe."


func _on_invite_pressed(friend_id: int) -> void:
	if not LobbyService.invite_friend(friend_id):
		return
	_invited_ids[friend_id] = true
	_rows[friend_id].mark_invited()
