extends Screen
## Codex : consulter chaque classe (portrait, description, stats, cartes) et les cartes neutres.
## Un onglet par classe à gauche, plus un onglet « Cartes neutres ». Lecture seule.

const CARD_SLOT_SCALE: float = 1.0
const TAB_ICON_SIZE: int = 30
const TAB_HEIGHT: float = 44.0
const ULTIMATE_CAPTION: String = "Carte ultime"
const NEUTRAL_TITLE: String = "Cartes neutres"
const NEUTRAL_DESCRIPTION: String = "Cartes sans classe : n'importe quelle classe peut les mettre dans son deck (3 exemplaires au plus)."
const PODIUM_TITLE: String = "Cartes de podium"
const PODIUM_DESCRIPTION: String = "Cartes uniques, impossibles à mettre dans un deck. À la fin de chaque manche, les 3 premiers en choisissent une à tour de rôle (le 1er choisit en premier)."
const PODIUM_CARDS_TITLE: String = "Toutes les cartes de podium"
const CLASS_CARDS_TITLE: String = "Cartes de la classe"
const NEUTRAL_CARDS_TITLE: String = "Toutes les cartes neutres"

@onready var _panel_sidebar: PanelContainer = %Sidebar
@onready var _panel_content: PanelContainer = %Content
@onready var _tab_list: VBoxContainer = %TabList
@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _cards_title: Label = %CardsTitle
@onready var _card_grid: HFlowContainer = %CardGrid
@onready var _scroll: ScrollContainer = %Scroll
@onready var _back_button: Button = %BackButton

var _tab_group := ButtonGroup.new()


func _ready() -> void:
	_apply_styles()
	_build_tabs()
	_back_button.pressed.connect(navigation_requested.emit.bind(Screen.Id.MAIN_MENU))
	_select_first_tab()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		navigation_requested.emit(Screen.Id.MAIN_MENU)
		get_viewport().set_input_as_handled()


# --- Mise en place ----------------------------------------------------------

func _apply_styles() -> void:
	_panel_sidebar.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.menu_panel(), 14.0, 14.0))
	_panel_content.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	UiStyle.style_button(_back_button, false)


func _build_tabs() -> void:
	for class_data: ClassData in ClassCatalog.get_all():
		_add_tab(class_data.display_name, ClassIcons.for_class(class_data.id), _show_class.bind(class_data))
	_add_tab(NEUTRAL_TITLE, ClassIcons.for_class(NeutralCards.CLASS_ID), _show_card_set.bind(NEUTRAL_TITLE, NEUTRAL_DESCRIPTION, NEUTRAL_CARDS_TITLE, NeutralCards.get_all()))
	_add_tab(PODIUM_TITLE, ClassIcons.for_class(PodiumCards.CLASS_ID), _show_card_set.bind(PODIUM_TITLE, PODIUM_DESCRIPTION, PODIUM_CARDS_TITLE, PodiumCards.get_all()))


func _add_tab(title: String, icon: Texture2D, on_selected: Callable) -> void:
	var tab := Button.new()
	tab.text = title
	tab.icon = icon
	tab.toggle_mode = true
	tab.button_group = _tab_group
	tab.focus_mode = Control.FOCUS_NONE
	tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tab.custom_minimum_size = Vector2(0.0, TAB_HEIGHT)
	_style_tab(tab)
	tab.toggled.connect(_on_tab_toggled.bind(on_selected))
	_tab_list.add_child(tab)


func _style_tab(tab: Button) -> void:
	UiStyle.style_button(tab, false)
	var selected: StyleBoxFlat = UiStyle.with_margins(UiStyle.box(UiStyle.PRIMARY_BUTTON, 10, UiStyle.GOLD, 2), 16.0, 8.0)
	tab.add_theme_stylebox_override("pressed", selected)
	tab.add_theme_stylebox_override("hover_pressed", selected)
	tab.add_theme_color_override("font_pressed_color", Color.WHITE)
	tab.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	tab.add_theme_constant_override("icon_max_width", TAB_ICON_SIZE)
	tab.add_theme_constant_override("h_separation", 10)
	tab.add_theme_font_size_override("font_size", 16)


func _select_first_tab() -> void:
	var first: Button = _tab_list.get_child(0) as Button
	first.button_pressed = true


# --- Affichage --------------------------------------------------------------

func _show_class(class_data: ClassData) -> void:
	_name_label.text = class_data.display_name
	_description_label.text = _describe_class(class_data)
	_portrait.texture = class_data.character.portrait
	_portrait.flip_h = class_data.character.portrait_faces_left
	_portrait.visible = _portrait.texture != null
	_stats_label.text = _describe_stats(class_data)
	_stats_label.show()
	_cards_title.text = "%s (%d)" % [CLASS_CARDS_TITLE, class_data.cards.size()]
	_display_cards(class_data.cards)


## Un ensemble de cartes sans classe (neutres, podium) : pas de portrait ni de stats.
func _show_card_set(title: String, description: String, cards_title: String, cards: Array[CardData]) -> void:
	_name_label.text = title
	_description_label.text = description
	_portrait.hide()
	_stats_label.hide()
	_cards_title.text = "%s (%d)" % [cards_title, cards.size()]
	_display_cards(cards)

func _describe_class(class_data: ClassData) -> String:
	if class_data.passive_description.is_empty():
		return class_data.description
	return "%s\n\nMécanique unique : %s" % [class_data.description, class_data.passive_description]


func _describe_stats(class_data: ClassData) -> String:
	var parts: PackedStringArray = []
	for stat: ClassStatSummary.Stat in ClassStatSummary.build(class_data):
		parts.append("%s : %s" % [stat.label, stat.value_text])
	return "   ·   ".join(parts)


## Cartes normales d'abord, ultime en dernier.
func _display_cards(cards: Array[CardData]) -> void:
	_clear_cards()
	var ordered: Array[CardData] = cards.duplicate()
	ordered.sort_custom(func(a: CardData, b: CardData) -> bool: return not a.is_ultimate and b.is_ultimate)
	for card: CardData in ordered:
		_add_card(card)
	_scroll.scroll_vertical = 0


func _add_card(card: CardData) -> void:
	var slot := RewardCardSlot.new(CARD_SLOT_SCALE)
	_card_grid.add_child(slot)
	slot.display(card)
	slot.set_interactive(false)
	if card.is_ultimate:
		slot.set_caption(ULTIMATE_CAPTION, UiStyle.GOLD)


func _clear_cards() -> void:
	for slot: Node in _card_grid.get_children():
		_card_grid.remove_child(slot)
		slot.queue_free()


# --- Réactions --------------------------------------------------------------

func _on_tab_toggled(pressed: bool, on_selected: Callable) -> void:
	if pressed:
		on_selected.call()
