class_name CardTargeting
extends RefCounted
## État du choix de cible : quelle carte est en main et quel type de clic elle attend.

var card: CardData


func begin(p_card: CardData) -> void:
	card = p_card


func cancel() -> void:
	card = null


func is_active() -> bool:
	return card != null


func is_selecting(p_card: CardData) -> bool:
	return card == p_card


func expects_unit() -> bool:
	return is_active() and card.target_mode == CardData.TargetMode.UNIT


func expects_field() -> bool:
	return is_active() and card.target_mode in [CardData.TargetMode.PLAYER, CardData.TargetMode.FIELD]


func describe_hint() -> String:
	if expects_unit():
		return "Choisis une unité (personnage, compagnon ou monstre). Clic droit pour annuler."
	if expects_field():
		return "Clique sur le terrain à cibler (change d'onglet pour viser un adversaire). Clic droit pour annuler."
	return ""
