class_name MemberList
extends VBoxContainer
## Toutes les places du salon : joueurs, puis bots, puis places libres.
## L'hôte peut ajouter un bot dans une place libre ou retirer un bot.

signal add_bot_requested
signal remove_bot_requested

const MEMBER_ROW_SCENE: PackedScene = preload("res://ui/components/member_list/member_row.tscn")


func display(members: Array[LobbyMember], bot_count: int, slot_count: int, is_host: bool) -> void:
	_clear_rows()
	for member: LobbyMember in members:
		_add_row().display(member)
	for bot_index: int in range(1, bot_count + 1):
		var bot_row: MemberRow = _add_row()
		bot_row.display_bot("Bot %d" % bot_index, is_host)
		bot_row.action_pressed.connect(remove_bot_requested.emit)
	for _open_slot: int in maxi(slot_count - members.size() - bot_count, 0):
		var open_row: MemberRow = _add_row()
		open_row.display_open(is_host)
		open_row.action_pressed.connect(add_bot_requested.emit)


func _clear_rows() -> void:
	for row: Node in get_children():
		row.queue_free()


func _add_row() -> MemberRow:
	var row: MemberRow = MEMBER_ROW_SCENE.instantiate()
	add_child(row)
	return row
