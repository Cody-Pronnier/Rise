class_name LiveStandingsPanel
extends PanelContainer
## Classement en direct pendant la manche : points de la partie, puis avancement de la manche.
## Sert à repérer qui mène pour savoir qui viser. Une progression cachée (Invisibilité) reste
## « ??? » sauf pour soi et son allié, et ne compte pas dans le tri.

const REFRESH_INTERVAL: float = 0.5
const ICON_SIZE := Vector2(24, 24)
const ROW_FONT_SIZE: int = 14
const LOCAL_COLOR := Color(1.0, 0.85, 0.3)
const ALLY_COLOR := Color(0.5, 0.85, 1.0)
const HIDDEN_TEXT: String = "???"

@onready var _rows: VBoxContainer = %Rows

var _round: CombatRound
var _viewer_id: int
var _elapsed: float = 0.0


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.94), 14, Color(UiStyle.GOLD, 0.5), 2), UiStyle.SHADOW, 14), 16.0, 12.0))
	hide()


func setup(combat_round: CombatRound, viewer_id: int) -> void:
	_round = combat_round
	_viewer_id = viewer_id


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _process(delta: float) -> void:
	if not visible or _round == null:
		return
	_elapsed += delta
	if _elapsed >= REFRESH_INTERVAL:
		_elapsed = 0.0
		_refresh()


# --- Contenu ----------------------------------------------------------------

func _refresh() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var standings: Array[PlayerState] = _sorted_players()
	for index: int in standings.size():
		_rows.add_child(_create_row(index + 1, standings[index]))


## Tri : points de la partie, puis manche en cours (arrivés d'abord, puis avancement).
func _sorted_players() -> Array[PlayerState]:
	var players: Array[PlayerState] = []
	players.assign(_round.players.values())
	players.sort_custom(func(a: PlayerState, b: PlayerState) -> bool:
		if a.points != b.points:
			return a.points > b.points
		return _round_score(a) > _round_score(b))
	return players


func _round_score(player: PlayerState) -> float:
	var rank: int = _round.get_rank(player.id)
	if rank > 0:
		return 100.0 - rank
	if not _can_see(player):
		return -1.0
	return _round.fields[player.id].get_progress()


func _can_see(player: PlayerState) -> bool:
	var field: Field = _round.fields[player.id]
	return not field.hides_progress() or player.id == _viewer_id or _round.alliances.are_allied(_viewer_id, player.id)


func _describe_round(player: PlayerState) -> String:
	var rank: int = _round.get_rank(player.id)
	if rank > 0:
		return "Terminé #%d" % rank
	if not _can_see(player):
		return HIDDEN_TEXT
	var field: Field = _round.fields[player.id]
	return "Monstre %d/%d · %d%%" % [
		mini(field.kills + 1, field.total_monsters),
		field.total_monsters,
		roundi(field.get_progress() / field.total_monsters * 100.0),
	]


# --- Lignes -----------------------------------------------------------------

func _create_row(position_in_list: int, player: PlayerState) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var color: Color = _row_color(player)
	row.add_child(_create_label("%d." % position_in_list, 24.0, color, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_create_icon(player))
	row.add_child(_create_label(_describe_name(player), 150.0, color, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(_create_label(_describe_round(player), 130.0, UiStyle.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(_create_label("%d pts" % player.points, 56.0, color, HORIZONTAL_ALIGNMENT_RIGHT))
	return row


func _row_color(player: PlayerState) -> Color:
	if player.id == _viewer_id:
		return LOCAL_COLOR
	if _round.alliances.are_allied(_viewer_id, player.id):
		return ALLY_COLOR
	return Color.WHITE


func _describe_name(player: PlayerState) -> String:
	if player.id == _viewer_id:
		return "Toi"
	return "%s (allié)" % player.display_name if _round.alliances.are_allied(_viewer_id, player.id) else player.display_name


func _create_icon(player: PlayerState) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = ClassIcons.for_class(player.class_data.id)
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = player.class_data.display_name
	return icon


func _create_label(text: String, width: float, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.horizontal_alignment = alignment
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
