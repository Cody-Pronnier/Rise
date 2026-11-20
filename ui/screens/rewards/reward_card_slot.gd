class_name RewardCardSlot
extends Control
## Emplacement cliquable autour d'une CardView, en taille réduite.
## Au survol, la carte reprend sa taille réelle pour être lisible.
## Une légende sous la carte peut indiquer qui l'a prise.

signal pressed(card: CardData)

const CARD_VIEW_SCENE: PackedScene = preload("res://ui/components/combat/card_view.tscn")
const HOVER_SCALE: float = 1.05
const CAPTION_HEIGHT: float = 22.0
const TAKEN_TINT := Color(0.45, 0.45, 0.5)

var _card_scale: float
var _card: CardData
var _card_view: CardView
var _caption: Label
var _is_interactive: bool = true
var _is_hovered: bool = false


func _init(card_scale: float = 1.0) -> void:
	_card_scale = card_scale


func _ready() -> void:
	custom_minimum_size = HandLayout.CARD_SIZE * _card_scale + Vector2(0.0, CAPTION_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_card_view()
	_create_caption()
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	_refresh_scale()


## À appeler après add_child().
func display(card: CardData) -> void:
	_card = card
	_card_view.display(card)


func get_card() -> CardData:
	return _card


func set_selected(selected: bool) -> void:
	_card_view.set_selected(selected)


func set_interactive(interactive: bool) -> void:
	_is_interactive = interactive
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	_refresh_scale()


func set_taken(taken: bool) -> void:
	_card_view.modulate = TAKEN_TINT if taken else Color.WHITE


func set_caption(text: String, color: Color = UiStyle.TEXT_DIM) -> void:
	_caption.text = text
	_caption.add_theme_color_override("font_color", color)


func _gui_input(event: InputEvent) -> void:
	if _is_interactive and _card and UiInput.is_left_click(event):
		pressed.emit(_card)
		accept_event()


func _create_card_view() -> void:
	_card_view = CARD_VIEW_SCENE.instantiate()
	add_child(_card_view)
	_card_view.position = (HandLayout.CARD_SIZE * _card_scale - HandLayout.CARD_SIZE) / 2.0


func _create_caption() -> void:
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 13)
	_caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_caption)
	_caption.position = Vector2(0.0, HandLayout.CARD_SIZE.y * _card_scale + 2.0)
	_caption.size = Vector2(HandLayout.CARD_SIZE.x * _card_scale, CAPTION_HEIGHT)


func _set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	_refresh_scale()


## La CardView garde sa taille réelle et son pivot au centre : on ne joue que sur son échelle.
func _refresh_scale() -> void:
	var enlarged: bool = _is_hovered and _is_interactive
	_card_view.scale = Vector2.ONE * (HOVER_SCALE if enlarged else _card_scale)
	z_index = 10 if enlarged else 0
