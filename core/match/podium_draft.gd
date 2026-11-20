class_name PodiumDraft
extends RefCounted
## Draft des cartes de podium (uniques) : le 1er choisit parmi toutes, le 2e parmi les restantes…
## Quand il ne reste qu'une carte pour le dernier joueur, elle lui est attribuée automatiquement.

signal picked(player_id: int, card: CardData)

var _order: Array[int] = []
var _offer: Array[CardData] = []
var _available: Array[CardData] = []
var _taken_by: Dictionary[CardData, int] = {}
var _turn: int = 0


func _init(pick_order: Array[int], cards: Array[CardData]) -> void:
	_order = pick_order
	_offer = cards
	_available = cards.duplicate()


## À appeler après avoir connecté les signaux (déclenche l'attribution automatique éventuelle).
func start() -> void:
	_auto_assign_last_card()


func get_offer() -> Array[CardData]:
	return _offer


func get_available() -> Array[CardData]:
	return _available


func get_pick_order() -> Array[int]:
	return _order


## Joueur qui doit choisir maintenant, ou -1 si le draft est terminé.
func current_picker_id() -> int:
	if _turn >= _order.size() or _available.is_empty():
		return -1
	return _order[_turn]


func is_complete() -> bool:
	return current_picker_id() == -1


## Joueur qui a pris cette carte, ou -1 si elle est encore disponible.
func taker_of(card: CardData) -> int:
	return _taken_by.get(card, -1)


## Renvoie "" si le choix est accepté, sinon la raison du refus.
func pick(player_id: int, card: CardData) -> String:
	if current_picker_id() != player_id:
		return "Ce n'est pas ton tour de choisir."
	if not _available.has(card):
		return "Cette carte a déjà été prise."
	_take(card)
	return ""


func _take(card: CardData) -> void:
	var player_id: int = current_picker_id()
	_available.erase(card)
	_taken_by[card] = player_id
	_turn += 1
	picked.emit(player_id, card)
	_auto_assign_last_card()


func _auto_assign_last_card() -> void:
	var is_last_picker: bool = _turn == _order.size() - 1
	if is_last_picker and _available.size() == 1:
		_take(_available[0])
