class_name StatusContainer
extends RefCounted
## Liste des statuts actifs d'une unité et calcul de leurs modificateurs cumulés.
## Les statuts se cumulent : le même statut peut être présent plusieurs fois.

signal changed

var _instances: Array[StatusInstance] = []


func get_instances() -> Array[StatusInstance]:
	return _instances


## Chaque application ajoute une instance indépendante, avec sa propre durée :
## deux Gigantisme = deux effets cumulés (les multiplicateurs se multiplient, les dégâts sur la durée
## s'additionnent). Renvoie false si le statut a été bloqué (immunité aux contrôles).
func add(status: StatusData) -> bool:
	if status.is_control() and has_flag(StatusData.Flag.CC_IMMUNE):
		return false
	_instances.append(StatusInstance.new(status))
	changed.emit()
	return true


func tick(delta: float) -> void:
	for instance: StatusInstance in _instances:
		instance.tick(delta)
	_remove_where(func(instance: StatusInstance) -> bool: return instance.is_expired())


func remove_categories(categories: Array[int]) -> void:
	_remove_where(func(instance: StatusInstance) -> bool: return instance.data.category in categories)


func clear() -> void:
	_remove_where(func(_instance: StatusInstance) -> bool: return true)


func has_flag(flag: int) -> bool:
	return _instances.any(func(instance: StatusInstance) -> bool: return instance.data.has_flag(flag))


## Retire le premier statut portant ce drapeau. Renvoie true s'il y en avait un.
func consume_flag(flag: int) -> bool:
	for instance: StatusInstance in _instances:
		if instance.data.has_flag(flag):
			_remove_instance(instance)
			return true
	return false


## Retire le premier soin d'urgence disponible et renvoie sa valeur (0 si aucun).
func consume_emergency_heal() -> float:
	for instance: StatusInstance in _instances:
		if instance.data.emergency_heal > 0.0:
			_remove_instance(instance)
			return instance.data.emergency_heal
	return 0.0


func on_hit_statuses() -> Array[StatusData]:
	var statuses: Array[StatusData] = []
	for instance: StatusInstance in _instances:
		if instance.data.on_hit_status:
			statuses.append(instance.data.on_hit_status)
	return statuses


func damage_multiplier() -> float:
	return _product(&"damage_mult")


func attack_speed_multiplier() -> float:
	return _product(&"attack_speed_mult")


func damage_taken_multiplier() -> float:
	return _product(&"damage_taken_mult")


func heal_received_multiplier() -> float:
	return _product(&"heal_received_mult")


func max_health_multiplier() -> float:
	return _product(&"max_health_mult")


func crit_bonus() -> float:
	return _sum(&"crit_bonus")


func damage_per_second() -> float:
	return _sum(&"damage_per_second")


func heal_per_second() -> float:
	return _sum(&"heal_per_second")


func _product(property: StringName) -> float:
	var result: float = 1.0
	for instance: StatusInstance in _instances:
		result *= instance.data.get(property)
	return result


func _sum(property: StringName) -> float:
	var result: float = 0.0
	for instance: StatusInstance in _instances:
		result += instance.data.get(property)
	return result


func _remove_instance(instance: StatusInstance) -> void:
	_instances.erase(instance)
	changed.emit()


func _remove_where(predicate: Callable) -> void:
	var kept: Array[StatusInstance] = []
	kept.assign(_instances.filter(func(instance: StatusInstance) -> bool: return not predicate.call(instance)))
	if kept.size() == _instances.size():
		return
	_instances = kept
	changed.emit()
