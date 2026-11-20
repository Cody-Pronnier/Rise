class_name DamageInfo
extends RefCounted
## Un coup en cours de résolution : montant et règles spéciales.

var amount: float
## Unité qui attaque. null pour les dégâts d'une carte.
var source: CombatUnit
var is_critical: bool = false
## Ignore les boucliers, l'immunité et la défense.
var unblockable: bool = false
## Ne peut pas être esquivé.
var undodgeable: bool = false
## Un coup déjà renvoyé ne peut pas l'être une seconde fois.
var reflectable: bool = true
var on_hit_statuses: Array[StatusData] = []


func _init(p_amount: float = 0.0, p_source: CombatUnit = null) -> void:
	amount = p_amount
	source = p_source


func can_be_reflected_by(defender: CombatUnit) -> bool:
	return reflectable and source != null and source != defender and source.is_alive()
