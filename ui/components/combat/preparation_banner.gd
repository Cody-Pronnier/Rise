class_name PreparationBanner
extends PanelContainer
## Compte à rebours du temps de préparation, au centre de l'arène.
## Pendant ce temps, les combats et les cartes attendent, mais alliances et échanges sont possibles.
## Lecture seule : le temps restant vient de CombatRound. Se cache quand les combats commencent.

const URGENT_SECONDS: int = 5
const URGENT_COLOR := Color(1.0, 0.45, 0.35)
const PULSE_SCALE: float = 1.25
const PULSE_DURATION: float = 0.35

var _round: CombatRound
var _countdown_label := Label.new()
var _shown_seconds: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.85), 12, Color(UiStyle.GOLD, 0.5), 1), UiStyle.SHADOW, 10), 20.0, 10.0))
	add_child(_build_content())
	hide()


func setup(combat_round: CombatRound) -> void:
	_round = combat_round
	visible = combat_round.is_preparing()
	combat_round.preparation_finished.connect(hide)
	_refresh()


func _process(_delta: float) -> void:
	if visible and _round:
		_refresh()


func _build_content() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	column.add_child(_make_label("Préparation", 20, UiStyle.GOLD))
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 46)
	column.add_child(_countdown_label)
	var hint: Label = _make_label("Regarde tes cartes, propose des alliances et des échanges.\nLes cartes se jouent dès le début des combats.", 14, Color(1, 1, 1, 0.8))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	return column


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Ne met à jour l'affichage que quand la seconde affichée change.
func _refresh() -> void:
	var seconds: int = ceili(_round.preparation_left)
	if seconds == _shown_seconds:
		return
	_shown_seconds = seconds
	_countdown_label.text = "%d s" % seconds
	var is_urgent: bool = seconds <= URGENT_SECONDS
	_countdown_label.add_theme_color_override("font_color", URGENT_COLOR if is_urgent else Color.WHITE)
	if is_urgent:
		_pulse()


func _pulse() -> void:
	_countdown_label.pivot_offset = _countdown_label.size / 2.0
	_countdown_label.scale = Vector2.ONE * PULSE_SCALE
	create_tween().tween_property(_countdown_label, "scale", Vector2.ONE, PULSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
