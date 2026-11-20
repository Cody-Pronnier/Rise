class_name HandView
extends Control
## La main en éventail en bas de l'écran.
## Elle gère elle-même le survol (d'après la position x de la souris, pour éviter le clignotement
## quand une carte se soulève) et le clic, puis anime chaque carte vers sa pose.

signal card_selected(card: CardData)

const CARD_VIEW_SCENE: PackedScene = preload("res://ui/components/combat/card_view.tscn")
const FOLLOW_SPEED: float = 14.0
const LOCKED_TINT := Color(0.45, 0.45, 0.5)
## Les nouvelles cartes arrivent depuis le bas de l'écran.
const SPAWN_OFFSET: float = 200.0

var _views: Array[CardView] = []
var _hovered_index: int = -1
var _selected_card: CardData
var _is_locked: bool = false


func _ready() -> void:
	mouse_exited.connect(_set_hovered_index.bind(-1))


func _process(delta: float) -> void:
	_animate_cards(1.0 - exp(-FOLLOW_SPEED * delta))


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion:
		_set_hovered_index(HandLayout.index_at(motion.position.x, _views.size(), size))
	elif UiInput.is_left_click(event) and _hovered_index != -1 and not _is_locked:
		card_selected.emit(_views[_hovered_index].get_card())
		accept_event()


# --- API publique -----------------------------------------------------------

## Synchronise la main avec la liste : les cartes déjà affichées glissent, les nouvelles arrivent.
func display(cards: Array[CardData]) -> void:
	_remove_missing_views(cards)
	_views = _build_ordered_views(cards)
	_set_hovered_index(-1)
	_refresh_selection()


## power_for(card) -> float : valeurs affichées de chaque carte (bonus de rattrapage selon la cible).
func apply_power(power_for: Callable) -> void:
	for view: CardView in _views:
		view.set_power(power_for.call(view.get_card()))


func set_selected(card: CardData) -> void:
	_selected_card = card
	_refresh_selection()


func set_locked(locked: bool) -> void:
	_is_locked = locked
	modulate = LOCKED_TINT if locked else Color.WHITE


func get_card_anchor(card: CardData) -> Vector2:
	var view: CardView = _find_view(card)
	return view.get_global_anchor() if view else get_global_rect().get_center()


# --- Interne ----------------------------------------------------------------

func _animate_cards(weight: float) -> void:
	var selected_index: int = _views.find(_find_view(_selected_card))
	for index: int in _views.size():
		var pose: HandLayout.Pose = HandLayout.pose_for(index, _views.size(), size, _hovered_index, selected_index)
		_views[index].follow_pose(pose, weight)


func _remove_missing_views(cards: Array[CardData]) -> void:
	var remaining: Array[CardData] = cards.duplicate()
	for view: CardView in _views:
		if remaining.has(view.get_card()):
			remaining.erase(view.get_card())
		else:
			view.queue_free()


func _build_ordered_views(cards: Array[CardData]) -> Array[CardView]:
	var available: Array[CardView] = []
	available.assign(_views.filter(func(view: CardView) -> bool: return not view.is_queued_for_deletion()))
	var ordered: Array[CardView] = []
	for card: CardData in cards:
		ordered.append(_take_view(available, card))
	return ordered


func _take_view(available: Array[CardView], card: CardData) -> CardView:
	for view: CardView in available:
		if view.get_card() == card:
			available.erase(view)
			return view
	return _create_view(card)


func _create_view(card: CardData) -> CardView:
	var view: CardView = CARD_VIEW_SCENE.instantiate()
	add_child(view)
	view.display(card)
	view.snap_to(Vector2(size.x / 2.0, size.y + SPAWN_OFFSET))
	return view


func _find_view(card: CardData) -> CardView:
	if card == null:
		return null
	for view: CardView in _views:
		if view.get_card() == card:
			return view
	return null


func _refresh_selection() -> void:
	for view: CardView in _views:
		view.set_selected(_selected_card != null and view.get_card() == _selected_card)


func _set_hovered_index(index: int) -> void:
	_hovered_index = index
