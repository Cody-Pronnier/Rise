class_name RoundResultPanel
extends PanelContainer
## Classement affiché à la fin d'une manche, ou classement final après la dernière manche.

signal continue_pressed

const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.3)
const PODIUM_COLOR := Color(0.85, 0.8, 0.95)

@onready var _title_label: Label = %TitleLabel
@onready var _results_list: VBoxContainer = %ResultsList
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	UiStyle.style_button(_continue_button, true)
	_continue_button.pressed.connect(continue_pressed.emit)


## Résultats de la manche : rang, points gagnés et total.
## can_continue : seul l'hôte (ou le joueur en entraînement) fait passer à la suite ;
## sinon l'hôte enchaîne automatiquement après quelques secondes.
func display_round(round_number: int, results: Array[RoundResult], players: Dictionary[int, PlayerState], local_player_id: int, can_continue: bool, is_last_round: bool) -> void:
	_title_label.text = "Fin de la manche %d" % round_number
	_continue_button.disabled = not can_continue
	if not can_continue:
		_continue_button.text = "En attente de l'hôte…"
	else:
		_continue_button.text = "Classement final" if is_last_round else "Choisir mes récompenses"
	_clear()
	for result: RoundResult in results:
		_add_line(_describe_round_result(result, players[result.player_id]), result.player_id == local_player_id, result.rank <= CombatConfig.PODIUM_SIZE and result.has_finished)
	show()


## Classement final de la partie, trié par total de points.
func display_final(players: Dictionary[int, PlayerState], local_player_id: int) -> void:
	_title_label.text = "Fin de la partie"
	_continue_button.text = "Retour au menu"
	_continue_button.disabled = false
	_clear()
	var standings: Array[PlayerState] = _sorted_by_points(players)
	for index: int in standings.size():
		var player: PlayerState = standings[index]
		_add_line("#%d   %s   %d pts" % [index + 1, player.display_name, player.points], player.id == local_player_id, index < CombatConfig.PODIUM_SIZE)
	show()


func _clear() -> void:
	for child: Node in _results_list.get_children():
		child.queue_free()


func _add_line(text: String, is_local: bool, is_podium: bool) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	if is_local:
		label.add_theme_color_override("font_color", HIGHLIGHT_COLOR)
	elif is_podium:
		label.add_theme_color_override("font_color", PODIUM_COLOR)
	_results_list.add_child(label)


func _describe_round_result(result: RoundResult, player: PlayerState) -> String:
	var rank_text: String = "#%d" % result.rank if result.has_finished else "Non terminé"
	var line: String = "%s   %s   +%d pts (total %d)" % [rank_text, player.display_name, result.points, player.points]
	return line + "   · alliance (points partagés)" if result.ally_id != -1 else line


func _sorted_by_points(players: Dictionary[int, PlayerState]) -> Array[PlayerState]:
	var standings: Array[PlayerState] = []
	standings.assign(players.values())
	standings.sort_custom(func(a: PlayerState, b: PlayerState) -> bool: return a.points > b.points)
	return standings
