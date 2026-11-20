class_name SignalBinder
extends RefCounted
## Retient des connexions pour pouvoir toutes les couper d'un coup.
## Utile pour une vue qui change d'objet affiché (ex : passer d'un terrain à un autre).

var _bindings: Array[Dictionary] = []


func bind(source_signal: Signal, callable: Callable) -> void:
	source_signal.connect(callable)
	_bindings.append({ "signal": source_signal, "callable": callable })


func clear() -> void:
	for binding: Dictionary in _bindings:
		_disconnect(binding["signal"], binding["callable"])
	_bindings.clear()


func _disconnect(source_signal: Signal, callable: Callable) -> void:
	if is_instance_valid(source_signal.get_object()) and source_signal.is_connected(callable):
		source_signal.disconnect(callable)
