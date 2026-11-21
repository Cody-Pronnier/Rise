class_name StatusInstance
extends RefCounted
## Un statut actif sur une unité, avec son temps restant.

var data: StatusData
var remaining: float
## Points de bouclier restants (0 si le statut n'est pas un bouclier).
var shield_left: float


func _init(p_data: StatusData) -> void:
	data = p_data
	remaining = p_data.duration
	shield_left = p_data.shield_amount


func refresh() -> void:
	remaining = data.duration


func tick(delta: float) -> void:
	remaining -= delta


func is_expired() -> bool:
	return remaining <= 0.0


## Absorbe une partie des dégâts et renvoie ce qui passe à travers.
func absorb(amount: float) -> float:
	var absorbed: float = minf(shield_left, amount)
	shield_left -= absorbed
	return amount - absorbed


func is_shield_broken() -> bool:
	return data.shield_amount > 0.0 and shield_left <= 0.0
