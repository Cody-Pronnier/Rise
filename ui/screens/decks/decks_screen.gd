extends Screen
## Mes decks : à gauche les classes ; à droite les emplacements de la classe choisie
## (DeckLibrary.SLOTS_PER_CLASS decks nommés), ou l'éditeur (DeckEditor) quand on en modifie un.
## Les decks sont enregistrés sur la machine du joueur et choisis à la sélection de classe.

const TAB_ICON_SIZE: int = 30
const TAB_HEIGHT: float = 44.0
const SLOT_ROW_HEIGHT: float = 64.0

@onready var _sidebar: PanelContainer = %Sidebar
@onready var _content: PanelContainer = %Content
@onready var _class_list: VBoxContainer = %ClassList
@onready var _slots_view: VBoxContainer = %SlotsView
@onready var _class_title: Label = %ClassTitle
@onready var _slot_rows: VBoxContainer = %SlotRows
@onready var _base_deck_label: Label = %BaseDeckLabel
@onready var _editor: DeckEditor = %DeckEditor
@onready var _back_button: Button = %BackButton

var _tab_group := ButtonGroup.new()
var _class_data: ClassData


func _ready() -> void:
	_apply_styles()
	_build_class_tabs()
	_back_button.pressed.connect(_on_back_pressed)
	_editor.saved.connect(_on_deck_saved)
	_editor.cancelled.connect(_show_slots)
	_select_first_class()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


# --- Mise en place ----------------------------------------------------------

func _apply_styles() -> void:
	_sidebar.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.menu_panel(), 14.0, 14.0))
	_content.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	UiStyle.style_button(_back_button, false)


func _build_class_tabs() -> void:
	for class_data: ClassData in ClassCatalog.get_all():
		var tab := Button.new()
		tab.text = class_data.display_name
		tab.icon = ClassIcons.for_class(class_data.id)
		tab.toggle_mode = true
		tab.button_group = _tab_group
		tab.focus_mode = Control.FOCUS_NONE
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.custom_minimum_size = Vector2(0.0, TAB_HEIGHT)
		_style_tab(tab)
		tab.toggled.connect(_on_class_toggled.bind(class_data))
		_class_list.add_child(tab)


func _style_tab(tab: Button) -> void:
	UiStyle.style_button(tab, false)
	var selected: StyleBoxFlat = UiStyle.with_margins(UiStyle.box(UiStyle.PRIMARY_BUTTON, 10, UiStyle.GOLD, 2), 16.0, 8.0)
	tab.add_theme_stylebox_override("pressed", selected)
	tab.add_theme_stylebox_override("hover_pressed", selected)
	tab.add_theme_color_override("font_pressed_color", Color.WHITE)
	tab.add_theme_constant_override("icon_max_width", TAB_ICON_SIZE)
	tab.add_theme_constant_override("h_separation", 10)
	tab.add_theme_font_size_override("font_size", 16)


func _select_first_class() -> void:
	(_class_list.get_child(0) as Button).button_pressed = true


# --- Emplacements -----------------------------------------------------------

func _show_slots() -> void:
	_editor.hide()
	_slots_view.show()
	_class_title.text = "Decks — %s" % _class_data.display_name
	_base_deck_label.text = "Sans deck personnalisé, tu joues le deck de base : 3 exemplaires de chaque carte de la classe + l'ultime (%d cartes)." % DeckRules.DECK_SIZE
	_rebuild_slot_rows()


func _rebuild_slot_rows() -> void:
	for child: Node in _slot_rows.get_children():
		_slot_rows.remove_child(child)
		child.queue_free()
	var decks: Array[DeckList] = DeckLibrary.get_decks(_class_data.id)
	for slot: int in decks.size():
		_slot_rows.add_child(_create_slot_row(slot, decks[slot]))


func _create_slot_row(slot: int, deck: DeckList) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = SLOT_ROW_HEIGHT
	panel.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.box(UiStyle.PANEL_LIGHT, 10, Color(UiStyle.GOLD, 0.35), 1), 16.0, 10.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_create_slot_label(slot, deck))
	if deck:
		row.add_child(_create_button("Modifier", true, _open_editor.bind(slot, deck)))
		row.add_child(_create_button("Supprimer", false, _delete_deck.bind(slot)))
	else:
		row.add_child(_create_button("Créer un deck", true, _open_editor.bind(slot, null)))
	panel.add_child(row)
	return panel


func _create_slot_label(slot: int, deck: DeckList) -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	if deck == null:
		label.text = "Emplacement %d — vide" % (slot + 1)
		label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	else:
		var state: String = "prêt à jouer" if deck.is_valid() else "incomplet"
		label.text = "%s  ·  %d / %d cartes  ·  %s" % [deck.name, deck.card_ids.size(), DeckRules.DECK_SIZE, state]
		label.add_theme_color_override("font_color", UiStyle.BUTTON_TEXT if deck.is_valid() else UiStyle.TEXT_DIM)
	return label


func _create_button(text: String, primary: bool, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(button, primary)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(action)
	return button


# --- Réactions --------------------------------------------------------------

func _on_class_toggled(pressed: bool, class_data: ClassData) -> void:
	if pressed:
		_class_data = class_data
		_show_slots()


func _open_editor(slot: int, deck: DeckList) -> void:
	_slots_view.hide()
	_editor.show()
	_editor.open(_class_data, slot, deck)


func _delete_deck(slot: int) -> void:
	DeckLibrary.delete_deck(_class_data.id, slot)
	_rebuild_slot_rows()


func _on_deck_saved(_slot: int, _deck: DeckList) -> void:
	_show_slots()


## Échap ou Retour : quitte l'éditeur d'abord, puis l'écran.
func _on_back_pressed() -> void:
	if _editor.visible:
		_show_slots()
	else:
		navigation_requested.emit(Screen.Id.MAIN_MENU)
