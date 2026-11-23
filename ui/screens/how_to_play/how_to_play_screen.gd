extends Screen
## « Comment jouer » : règles, déroulement d'une partie et touches, pour les nouveaux joueurs.
## Un onglet par sujet à gauche, le texte de la page à droite. Lecture seule.
## Les textes sont dans how_to_play_content.gd : cet écran ne fait que les afficher.

const CONTENT := preload("res://ui/screens/how_to_play/how_to_play_content.gd")
const TAB_HEIGHT: float = 44.0
const TITLE_SIZE: int = 32
const BODY_SIZE: int = 18

@onready var _panel_sidebar: PanelContainer = %Sidebar
@onready var _panel_content: PanelContainer = %Content
@onready var _tab_list: VBoxContainer = %TabList
@onready var _page_title: Label = %PageTitle
@onready var _page_text: RichTextLabel = %PageText
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
	_panel_content.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.menu_panel(), 28.0, 22.0))
	UiStyle.style_button(_back_button, false)
	_page_title.add_theme_font_size_override("font_size", TITLE_SIZE)
	_page_text.add_theme_font_size_override("normal_font_size", BODY_SIZE)
	_page_text.add_theme_font_size_override("bold_font_size", BODY_SIZE)
	_page_text.add_theme_font_size_override("italics_font_size", BODY_SIZE)


func _build_tabs() -> void:
	for page: CONTENT.Page in CONTENT.build_pages():
		_add_tab(page)


func _add_tab(page: CONTENT.Page) -> void:
	var tab := Button.new()
	tab.text = page.title
	tab.toggle_mode = true
	tab.button_group = _tab_group
	tab.focus_mode = Control.FOCUS_NONE
	tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tab.custom_minimum_size = Vector2(0.0, TAB_HEIGHT)
	_style_tab(tab)
	tab.toggled.connect(_on_tab_toggled.bind(page))
	_tab_list.add_child(tab)


func _style_tab(tab: Button) -> void:
	UiStyle.style_button(tab, false)
	var selected: StyleBoxFlat = UiStyle.with_margins(UiStyle.box(UiStyle.PRIMARY_BUTTON, 10, UiStyle.GOLD, 2), 16.0, 8.0)
	tab.add_theme_stylebox_override("pressed", selected)
	tab.add_theme_stylebox_override("hover_pressed", selected)
	tab.add_theme_color_override("font_pressed_color", Color.WHITE)
	tab.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	tab.add_theme_font_size_override("font_size", 16)


func _select_first_tab() -> void:
	var first: Button = _tab_list.get_child(0) as Button
	first.button_pressed = true


# --- Affichage --------------------------------------------------------------

func _show_page(page: CONTENT.Page) -> void:
	_page_title.text = page.title
	_page_text.text = page.body
	_scroll.scroll_vertical = 0


# --- Réactions --------------------------------------------------------------

func _on_tab_toggled(pressed: bool, page: CONTENT.Page) -> void:
	if pressed:
		_show_page(page)
