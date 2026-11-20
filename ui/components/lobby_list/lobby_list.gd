class_name LobbyList
extends VBoxContainer
## Affiche une liste de salons et relaie la demande pour en rejoindre un.

signal join_requested(lobby_id: int)

const LOBBY_ROW_SCENE: PackedScene = preload("res://ui/components/lobby_list/lobby_row.tscn")


func display(lobbies: Array[LobbyInfo]) -> void:
	_clear_rows()
	for lobby: LobbyInfo in lobbies:
		_add_row(lobby)


func set_join_enabled(enabled: bool) -> void:
	for row: LobbyRow in _get_rows():
		row.set_join_enabled(enabled)


func _get_rows() -> Array[LobbyRow]:
	var rows: Array[LobbyRow] = []
	rows.assign(get_children().filter(func(child: Node) -> bool: return child is LobbyRow))
	return rows


func _clear_rows() -> void:
	for row: Node in get_children():
		row.queue_free()


func _add_row(lobby: LobbyInfo) -> void:
	var row: LobbyRow = LOBBY_ROW_SCENE.instantiate()
	add_child(row)
	row.display(lobby)
	row.join_pressed.connect(join_requested.emit)
