class_name CardTarget
extends RefCounted
## La cible choisie pour une carte : un terrain (désigné par son joueur) et éventuellement une unité.

var player_id: int
var unit: CombatUnit


func _init(p_player_id: int = -1, p_unit: CombatUnit = null) -> void:
	player_id = p_player_id
	unit = p_unit


static func for_player(p_player_id: int) -> CardTarget:
	return CardTarget.new(p_player_id)


static func for_unit(p_player_id: int, p_unit: CombatUnit) -> CardTarget:
	return CardTarget.new(p_player_id, p_unit)
