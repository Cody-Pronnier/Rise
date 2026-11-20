class_name ClassChoiceCard
extends PanelContainer
## Fiche d'une classe : emblème, description, stats et liste des cartes.
## Grossit au survol ; un clic émet « pressed », la sélection est décidée par l'écran.

signal pressed(class_id: StringName)

const HOVER_SCALE: float = 1.04
const RADIUS: int = 14
const STAT_LABEL_WIDTH: float = 78.0
const STAT_VALUE_WIDTH: float = 44.0
const STAT_BAR_HEIGHT: float = 10.0
const ULTIMATE_COLOR_HEX: String = "#ffc84d"

@onready var _emblem: TextureRect = %Emblem
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _stats_list: VBoxContainer = %StatsList
@onready var _cards_label: RichTextLabel = %CardsLabel

var _class_data: ClassData
var _is_hovered: bool = false
var _is_selected: bool = false


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	resized.connect(_update_pivot)


## À appeler après add_child() pour que les nœuds @onready soient prêts.
func display(class_data: ClassData, stats: Array[ClassStatSummary.Stat]) -> void:
	_class_data = class_data
	_name_label.text = class_data.display_name
	_description_label.text = class_data.description
	_emblem.texture = ClassIcons.for_class(class_data.id)
	_name_label.add_theme_color_override("font_color", _class_color().lightened(0.35))
	_cards_label.text = _build_cards_text()
	_build_stat_rows(stats)
	_refresh_style()


func get_class_id() -> StringName:
	return _class_data.id


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_refresh_style()


func _gui_input(event: InputEvent) -> void:
	if _class_data and UiInput.is_left_click(event):
		pressed.emit(_class_data.id)
		accept_event()


# --- Contenu ----------------------------------------------------------------

func _build_stat_rows(stats: Array[ClassStatSummary.Stat]) -> void:
	for stat: ClassStatSummary.Stat in stats:
		_stats_list.add_child(_create_stat_row(stat))


func _create_stat_row(stat: ClassStatSummary.Stat) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	row.add_child(_create_stat_label(stat.label, STAT_LABEL_WIDTH, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(_create_stat_bar(stat.ratio))
	row.add_child(_create_stat_label(stat.value_text, STAT_VALUE_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT))
	return row


func _create_stat_label(text: String, width: float, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	return label


func _create_stat_bar(ratio: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = ratio
	bar.custom_minimum_size.y = STAT_BAR_HEIGHT
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UiStyle.box(Color(0, 0, 0, 0.5), 4))
	bar.add_theme_stylebox_override("fill", UiStyle.box(_class_color(), 4))
	return bar


## Noms des cartes séparés par des points, l'ultime en doré.
func _build_cards_text() -> String:
	var names := PackedStringArray()
	for card: CardData in _class_data.cards:
		names.append(_format_card_name(card))
	return " · ".join(names)


func _format_card_name(card: CardData) -> String:
	if card.is_ultimate:
		return "[color=%s]★ %s[/color]" % [ULTIMATE_COLOR_HEX, card.display_name]
	return card.display_name


# --- Style ------------------------------------------------------------------

func _set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	_refresh_style()


func _refresh_style() -> void:
	add_theme_stylebox_override("panel", _build_panel_style())
	scale = Vector2.ONE * (HOVER_SCALE if _is_hovered or _is_selected else 1.0)
	z_index = 1 if _is_hovered or _is_selected else 0


func _build_panel_style() -> StyleBoxFlat:
	var border: Color = _current_border_color()
	var style: StyleBoxFlat = UiStyle.box(UiStyle.PANEL_DARK, RADIUS, border, 3 if _is_highlighted() else 2)
	var glow := Color(border, 0.45 if _is_highlighted() else 0.0)
	return UiStyle.with_margins(UiStyle.with_shadow(style, glow if _is_highlighted() else UiStyle.SHADOW, 14), 16.0, 12.0)


func _current_border_color() -> Color:
	if _is_selected:
		return UiStyle.GOLD
	if _is_hovered:
		return _class_color().lightened(0.3)
	return _class_color().darkened(0.2)


func _is_highlighted() -> bool:
	return _is_hovered or _is_selected


func _class_color() -> Color:
	return _class_data.character.color if _class_data else UiStyle.TEXT_DIM


func _update_pivot() -> void:
	pivot_offset = size / 2.0
