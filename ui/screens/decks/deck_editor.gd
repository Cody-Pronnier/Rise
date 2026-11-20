class_name DeckEditor
extends VBoxContainer
## Éditeur d'un deck, façon jeu de cartes à collectionner :
## - à gauche, toutes les cartes autorisées (classe + neutres) : un clic ajoute un exemplaire ;
## - à droite, la liste du deck (exemplaires) : « − » retire un exemplaire ;
## - en haut, le nom, le compteur 16/16, la règle non respectée, et les boutons.
## Un deck incomplet peut être enregistré, mais seul un deck valide peut être choisi en partie.
## Construit entièrement en code ; prévient l'écran par saved / cancelled.

signal saved(slot: int, deck: DeckList)
signal cancelled

const POOL_CARD_SCALE: float = 0.62
const VALID_COLOR := Color(0.55, 0.95, 0.6)
const ERROR_COLOR := Color(1.0, 0.6, 0.5)

var _class_data: ClassData
var _slot: int = 0
var _card_ids: Array[StringName] = []
var _pool_slots: Dictionary[StringName, RewardCardSlot] = {}

var _name_edit := LineEdit.new()
var _count_label := Label.new()
var _status_label := Label.new()
var _pool_flow := HFlowContainer.new()
var _deck_list := VBoxContainer.new()


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(_build_header())
	add_child(_build_status_line())
	add_child(_build_body())


## deck null = nouveau deck, prérempli avec le deck de base.
func open(class_data: ClassData, slot: int, deck: DeckList) -> void:
	_class_data = class_data
	_slot = slot
	_name_edit.text = deck.name if deck else "%s %d" % [class_data.display_name, slot + 1]
	_card_ids = deck.card_ids.duplicate() if deck else DeckRules.default_deck_ids(class_data)
	_build_pool()
	_refresh()


# --- Construction -----------------------------------------------------------

func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_name_edit.custom_minimum_size.x = 260.0
	_name_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_edit.max_length = DeckLibrary.MAX_NAME_LENGTH
	_name_edit.placeholder_text = "Nom du deck"
	UiStyle.style_line_edit(_name_edit)
	header.add_child(_name_edit)
	_count_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_count_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_create_button("Deck de base", false, _reset_to_default))
	header.add_child(_create_button("Vider", false, _clear_deck))
	header.add_child(_create_button("Annuler", false, cancelled.emit))
	header.add_child(_create_button("Enregistrer", true, _on_save_pressed))
	return header


## Ligne à part : un texte qui revient à la ligne dans la rangée de boutons
## n'aurait aucune largeur et étirerait toute la rangée en hauteur.
func _build_status_line() -> Label:
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	return _status_label


func _build_body() -> HBoxContainer:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	body.add_child(_build_pool_column())
	body.add_child(_build_deck_column())
	return body


func _build_pool_column() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pool_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_flow.add_theme_constant_override("h_separation", 10)
	_pool_flow.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_pool_flow)
	return scroll


func _build_deck_column() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 300.0
	panel.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.box(Color(0.03, 0.03, 0.05, 0.7), 10), 12.0, 10.0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Ton deck"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_deck_list)
	column.add_child(scroll)
	panel.add_child(column)
	return panel


func _build_pool() -> void:
	for child: Node in _pool_flow.get_children():
		_pool_flow.remove_child(child)
		child.queue_free()
	_pool_slots.clear()
	for card: CardData in DeckRules.pool(_class_data):
		var slot := RewardCardSlot.new(POOL_CARD_SCALE)
		_pool_flow.add_child(slot)
		slot.display(card)
		slot.pressed.connect(_add_card)
		_pool_slots[card.id] = slot


func _create_button(text: String, primary: bool, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(button, primary)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(action)
	return button


# --- Affichage --------------------------------------------------------------

func _refresh() -> void:
	_refresh_pool()
	_refresh_deck_list()
	_refresh_status()


## Légende « 2 / 3 » sous chaque carte ; une carte au maximum n'est plus cliquable.
func _refresh_pool() -> void:
	for card: CardData in DeckRules.pool(_class_data):
		var slot: RewardCardSlot = _pool_slots[card.id]
		var count: int = _card_ids.count(card.id)
		var can_add: bool = _can_add(card)
		slot.set_caption("%d / %d" % [count, DeckRules.max_copies_of(card)], UiStyle.GOLD if count > 0 else UiStyle.TEXT_DIM)
		slot.set_interactive(can_add)
		slot.set_taken(not can_add)


func _refresh_deck_list() -> void:
	for child: Node in _deck_list.get_children():
		_deck_list.remove_child(child)
		child.queue_free()
	var counts: Dictionary = DeckRules.count_ids(_card_ids)
	for card: CardData in DeckRules.pool(_class_data):
		if counts.has(card.id):
			_deck_list.add_child(_create_deck_row(card, counts[card.id]))


func _create_deck_row(card: CardData, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = ClassIcons.for_class(card.class_id)
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := Label.new()
	label.text = "%d×  %s%s" % [count, card.display_name, "  ★" if card.is_ultimate else ""]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", UiStyle.GOLD if card.is_ultimate else UiStyle.BUTTON_TEXT)
	row.add_child(label)
	var remove := _create_button("−", false, _remove_card.bind(card.id))
	remove.custom_minimum_size = Vector2(36, 30)
	row.add_child(remove)
	return row


func _refresh_status() -> void:
	_count_label.text = "%d / %d" % [_card_ids.size(), DeckRules.DECK_SIZE]
	var error: String = DeckRules.get_error(_class_data, _card_ids)
	_count_label.add_theme_color_override("font_color", VALID_COLOR if error.is_empty() else ERROR_COLOR)
	_status_label.text = "Deck valide !" if error.is_empty() else error
	_status_label.add_theme_color_override("font_color", VALID_COLOR if error.is_empty() else UiStyle.TEXT_DIM)


# --- Règles d'ajout ---------------------------------------------------------

func _can_add(card: CardData) -> bool:
	if _card_ids.size() >= DeckRules.DECK_SIZE:
		return false
	if _card_ids.count(card.id) >= DeckRules.max_copies_of(card):
		return false
	return not card.is_ultimate or _ultimate_count() < DeckRules.MAX_ULTIMATES


func _ultimate_count() -> int:
	var count: int = 0
	for card: CardData in DeckRules.pool(_class_data):
		if card.is_ultimate:
			count += _card_ids.count(card.id)
	return count


# --- Réactions --------------------------------------------------------------

func _add_card(card: CardData) -> void:
	if _can_add(card):
		_card_ids.append(card.id)
		_refresh()


func _remove_card(card_id: StringName) -> void:
	_card_ids.erase(card_id)
	_refresh()


func _reset_to_default() -> void:
	_card_ids = DeckRules.default_deck_ids(_class_data)
	_refresh()


func _clear_deck() -> void:
	_card_ids.clear()
	_refresh()


func _on_save_pressed() -> void:
	var deck := DeckList.new(DeckLibrary.sanitize_name(_name_edit.text, _slot), _class_data.id, _card_ids)
	DeckLibrary.save_deck(_slot, deck)
	saved.emit(_slot, deck)
