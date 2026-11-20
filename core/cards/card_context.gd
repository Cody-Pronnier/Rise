class_name CardContext
extends RefCounted
## Tout ce dont un effet a besoin au moment où une carte est résolue.

var caster: PlayerState
var target_player: PlayerState
var target_field: Field
## Unités touchées : la cible pour UNIT, tout le terrain pour FIELD, les héros sinon.
var target_units: Array[CombatUnit] = []
## La manche en cours (alliances, joueurs…) pour les effets qui agissent au-delà d'un terrain.
var combat_round: CombatRound
## Multiplicateur de puissance (bonus de rattrapage, voir CatchUpBoost) : 1.0 = normal.
var power: float = 1.0


func _init(p_caster: PlayerState, p_target_player: PlayerState, p_target_field: Field, p_target_units: Array[CombatUnit], p_round: CombatRound = null) -> void:
	caster = p_caster
	target_player = p_target_player
	target_field = p_target_field
	target_units = p_target_units
	combat_round = p_round
