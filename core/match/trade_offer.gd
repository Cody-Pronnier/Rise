class_name TradeOffer
extends RefCounted
## Une proposition d'échange d'un joueur à un autre : cartes en main, points et/ou alliance.

var id: int = 0
var from_id: int = -1
var to_id: int = -1
var given_cards: Array[CardData] = []
var given_points: int = 0
var requested_cards: Array[CardData] = []
var requested_points: int = 0
var proposes_alliance: bool = false
## Secondes avant expiration (renseigné par TradeDesk à l'envoi).
var remaining_time: float = 0.0


func is_empty() -> bool:
	return given_cards.is_empty() and requested_cards.is_empty() \
		and given_points == 0 and requested_points == 0 and not proposes_alliance


## Simple demande d'alliance, sans carte ni point.
func is_alliance_only() -> bool:
	return proposes_alliance and given_cards.is_empty() and requested_cards.is_empty() \
		and given_points == 0 and requested_points == 0


func involves(player_id: int) -> bool:
	return from_id == player_id or to_id == player_id
