class_name ManaBar
extends PanelContainer
## Jauge de mana du joueur local, en bas à gauche : un cristal avec le mana entier
## et une barre segmentée (un segment par point) qui se remplit en continu.
## Elle pâlit quand le mana est gelé.
## Lecture seule : le mana vient de PlayerState.

const SEGMENT_SIZE := Vector2(18, 16)
const FILL_COLOR := Color(0.3, 0.55, 1.0)
const FULL_COLOR := Color(0.55, 0.8, 1.0)
## Mana gelé (Chaîne) : la jauge pâlit tant qu'il ne se recharge plus.
const FROZEN_TINT := Color(0.6, 0.65, 0.75)

var _player: PlayerState
var _count_label := Label.new()
var _segments: Array[ProgressBar] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.85), 10, Color(FILL_COLOR, 0.6), 1), UiStyle.SHADOW, 8), 10.0, 6.0))
	add_child(_build_content())


func setup(player: PlayerState) -> void:
	_player = player
	_refresh()


func _process(_delta: float) -> void:
	if _player and visible:
		_refresh()


func _build_content() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.custom_minimum_size = Vector2(52, 0)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 22)
	_count_label.add_theme_color_override("font_color", FULL_COLOR)
	_count_label.add_theme_constant_override("outline_size", 5)
	_count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	row.add_child(_count_label)
	row.add_child(_build_segments())
	return row


func _build_segments() -> HBoxContainer:
	var segments := HBoxContainer.new()
	segments.add_theme_constant_override("separation", 3)
	segments.alignment = BoxContainer.ALIGNMENT_CENTER
	for _index: int in int(CombatConfig.MANA_MAX):
		var segment := ProgressBar.new()
		segment.custom_minimum_size = SEGMENT_SIZE
		segment.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		segment.max_value = 1.0
		segment.step = 0.0
		segment.show_percentage = false
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.add_theme_stylebox_override("background", UiStyle.bar_background())
		segment.add_theme_stylebox_override("fill", UiStyle.bar_fill(FILL_COLOR))
		segments.add_child(segment)
		_segments.append(segment)
	return segments


## Chaque segment montre sa part du mana : plein, en cours de remplissage ou vide.
func _refresh() -> void:
	_count_label.text = "%d" % floori(_player.mana)
	modulate = FROZEN_TINT if _player.is_mana_frozen() else Color.WHITE
	for index: int in _segments.size():
		_segments[index].value = clampf(_player.mana - index, 0.0, 1.0)
