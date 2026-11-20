class_name StatusInstance
extends RefCounted
## Un statut actif sur une unité, avec son temps restant.

var data: StatusData
var remaining: float


func _init(p_data: StatusData) -> void:
	data = p_data
	remaining = p_data.duration


func refresh() -> void:
	remaining = data.duration


func tick(delta: float) -> void:
	remaining -= delta


func is_expired() -> bool:
	return remaining <= 0.0
