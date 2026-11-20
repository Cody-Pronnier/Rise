extends Screen
## Choix de la classe.
## - Entraînement : un clic sélectionne une fiche, « Combattre » lance la partie contre des bots.
## - En ligne : choix secret avec chrono. « Valider mon choix » l'envoie à l'hôte (définitif) ;
##   sans choix à la fin du chrono, l'hôte attribue une classe au hasard.
## Le deck se choisit à côté du bouton : deck de base ou un des decks enregistrés pour la classe.
## La navigation vers le combat est faite par Main quand MatchService émet round_started.

const CLASS_CARD_SCENE: PackedScene = preload("res://ui/screens/class_select/class_choice_card.tscn")
const NO_CLASS: StringName = &""
const TIMER_WARNING_SECONDS: float = 10.0
const TIMER_WARNING_COLOR := Color(1.0, 0.5, 0.45)
const MAX_COLUMNS: int = 4
const MIN_COLUMNS: int = 2
## Marge pour le grossissement des fiches au survol.
const HOVER_MARGIN: float = 30.0

@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _class_grid: GridContainer = %ClassGrid
@onready var _scroll: ScrollContainer = %Scroll
@onready var _selection_label: Label = %SelectionLabel
@onready var _back_button: Button = %BackButton
@onready var _start_button: Button = %StartButton
@onready var _deck_option: OptionButton = %DeckOption

var _cards: Array[ClassChoiceCard] = []
var _selected_class_id: StringName = NO_CLASS
## Decks proposés dans la liste, dans l'ordre (index 0 = deck de base, null).
var _deck_choices: Array[DeckList] = []
var _is_online: bool = false
var _is_locked: bool = false
var _time_left: float = 0.0


func _ready() -> void:
	_is_online = MatchService.is_online() and MatchService.session.phase == MatchSession.Phase.CLASS_SELECTION
	_connect_buttons()
	_build_class_cards()
	_scroll.resized.connect(_update_columns)
	_update_columns.call_deferred()
	_configure_mode()
	_refresh_selection()


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_refresh_online_status()


# --- Mise en place ----------------------------------------------------------

func _connect_buttons() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_start_button.pressed.connect(_on_start_pressed)


func _configure_mode() -> void:
	set_process(_is_online)
	if not _is_online:
		return
	_time_left = MatchService.session.selection_duration
	_start_button.text = "Valider mon choix"
	_back_button.text = "Quitter la partie"
	MatchService.session.class_locked.connect(_on_class_locked)


func _build_class_cards() -> void:
	for class_data: ClassData in ClassCatalog.get_all():
		_cards.append(_create_class_card(class_data))


## Autant de colonnes que la largeur le permet (8 classes : 4 colonnes sur un grand écran).
func _update_columns() -> void:
	if _cards.is_empty():
		return
	var card_width: float = _cards[0].get_combined_minimum_size().x + _class_grid.get_theme_constant("h_separation")
	var fitting: int = floori((_scroll.size.x - HOVER_MARGIN) / card_width)
	_class_grid.columns = clampi(fitting, MIN_COLUMNS, MAX_COLUMNS)


func _create_class_card(class_data: ClassData) -> ClassChoiceCard:
	var card: ClassChoiceCard = CLASS_CARD_SCENE.instantiate()
	_class_grid.add_child(card)
	card.display(class_data, ClassStatSummary.build(class_data))
	card.pressed.connect(_on_class_pressed)
	return card


# --- Affichage --------------------------------------------------------------

func _refresh_selection() -> void:
	for card: ClassChoiceCard in _cards:
		card.set_selected(card.get_class_id() == _selected_class_id)
	_start_button.disabled = _selected_class_id == NO_CLASS or _is_locked
	_deck_option.disabled = _selected_class_id == NO_CLASS or _is_locked
	_selection_label.text = _describe_selection()


func _describe_selection() -> String:
	var class_data: ClassData = ClassCatalog.find(_selected_class_id)
	if class_data == null:
		return "Sélectionne une classe"
	if _is_locked:
		return "Choix validé : %s" % class_data.display_name
	return "Tu joueras %s" % class_data.display_name


## Sous-titre en ligne : temps restant et nombre de joueurs ayant choisi.
func _refresh_online_status() -> void:
	var session: MatchSession = MatchService.session
	if session == null:
		return
	var timer_text: String = "Temps restant : %d s" % ceili(_time_left) if _time_left > 0.0 else "Attribution des classes…"
	_subtitle_label.text = "Choix secret · %s · %d / %d joueurs ont choisi" % [timer_text, session.locked_count(), session.selection_players.size()]
	_subtitle_label.add_theme_color_override("font_color", TIMER_WARNING_COLOR if _time_left <= TIMER_WARNING_SECONDS else UiStyle.TEXT_DIM)


# --- Réactions --------------------------------------------------------------

func _on_class_pressed(class_id: StringName) -> void:
	if _is_locked:
		return
	_selected_class_id = class_id
	_fill_deck_option()
	_refresh_selection()


## « Deck de base » puis les decks complets enregistrés pour cette classe (le dernier est présélectionné).
func _fill_deck_option() -> void:
	_deck_option.clear()
	_deck_choices = [null]
	_deck_option.add_item("Deck de base")
	for deck: DeckList in DeckLibrary.get_playable_decks(_selected_class_id):
		_deck_choices.append(deck)
		_deck_option.add_item(deck.name)
	_deck_option.select(_deck_choices.size() - 1)


func _selected_deck_ids() -> Array[StringName]:
	var deck: DeckList = _deck_choices[_deck_option.selected] if _deck_option.selected >= 0 and _deck_option.selected < _deck_choices.size() else null
	var ids: Array[StringName] = []
	if deck:
		ids = deck.card_ids.duplicate()
	return ids


func _on_start_pressed() -> void:
	if _is_online:
		_is_locked = true
		MatchService.choose_class(_selected_class_id, _selected_deck_ids())
		_refresh_selection()
	else:
		MatchService.start_local_match(_selected_class_id, _selected_deck_ids())


func _on_class_locked(_player_id: int) -> void:
	_refresh_online_status()


func _on_back_pressed() -> void:
	if _is_online:
		MatchService.leave_match()
	else:
		navigation_requested.emit(Screen.Id.MAIN_MENU)
