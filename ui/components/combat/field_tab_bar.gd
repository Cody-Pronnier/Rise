class_name FieldTabBar
extends HBoxContainer
## Barre d'onglets en haut de l'écran : un onglet par joueur, le joueur local en premier.

signal field_selected(player_id: int)
## Clic droit sur l'onglet d'un joueur.
signal player_menu_requested(player_id: int)

var _tabs: Dictionary[int, FieldTab] = {}
var _button_group := ButtonGroup.new()


func build(combat_round: CombatRound, viewer_id: int) -> void:
	for player: PlayerState in _ordered_players(combat_round, viewer_id):
		_add_tab(player, combat_round.fields[player.id], viewer_id, combat_round.alliances)
	combat_round.player_finished.connect(_on_player_finished)


func set_active(player_id: int) -> void:
	for tab_player_id: int in _tabs:
		_tabs[tab_player_id].set_pressed_no_signal(tab_player_id == player_id)


func _add_tab(player: PlayerState, field: Field, viewer_id: int, alliances: AllianceRegistry) -> void:
	var tab := FieldTab.new()
	tab.button_group = _button_group
	add_child(tab)
	tab.setup(player, field, viewer_id, alliances)
	tab.pressed.connect(field_selected.emit.bind(player.id))
	tab.context_requested.connect(player_menu_requested.emit)
	_tabs[player.id] = tab


func _ordered_players(combat_round: CombatRound, viewer_id: int) -> Array[PlayerState]:
	var ordered: Array[PlayerState] = [combat_round.players[viewer_id]]
	for player: PlayerState in combat_round.players.values():
		if player.id != viewer_id:
			ordered.append(player)
	return ordered


func _on_player_finished(player_id: int, rank: int) -> void:
	_tabs[player_id].set_rank(rank)
