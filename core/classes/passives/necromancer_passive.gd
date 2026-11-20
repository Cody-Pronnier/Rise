class_name NecromancerPassive
extends ClassPassive
## Le Nécromancien ne frappe jamais lui-même. Dès qu'il n'a plus aucune invocation,
## il relève un squelette après un court délai (et tout de suite au début de la manche).

const RAISE_DELAY: float = 2.5

var _skeleton: UnitData
var _raise_remaining: float = 0.0


func _init(skeleton: UnitData) -> void:
	_skeleton = skeleton


func character_can_attack() -> bool:
	return false


func tick(delta: float) -> void:
	if field.has_living_companions() or not field.character.is_alive():
		_raise_remaining = RAISE_DELAY
		return
	_raise_remaining -= delta
	if _raise_remaining <= 0.0:
		_raise_remaining = RAISE_DELAY
		field.add_companion(_skeleton)


func status_text() -> String:
	var minions: int = field.get_companions_tagged(&"minion").size()
	if minions > 0:
		return "Invocations : %d / %d" % [minions, CombatConfig.MAX_COMPANIONS]
	return "Squelette dans %.1f s" % get_raise_remaining()


## Secondes avant le prochain squelette (0 si une invocation est déjà là).
func get_raise_remaining() -> float:
	return 0.0 if field.has_living_companions() else maxf(_raise_remaining, 0.0)


func _on_attached() -> void:
	field.add_companion(_skeleton)
	_raise_remaining = RAISE_DELAY
