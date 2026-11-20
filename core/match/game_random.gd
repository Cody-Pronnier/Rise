class_name GameRandom
extends RefCounted
## Hasard de la simulation (coups critiques, récompenses…).
## En ligne, toutes les machines reçoivent la même graine au début de la partie :
## elles tirent donc exactement les mêmes nombres, dans le même ordre.
## Ne pas l'utiliser pour l'interface ni pour les décisions des bots (réservées à l'hôte).

static var _rng := RandomNumberGenerator.new()


static func set_seed(value: int) -> void:
	_rng.seed = value


## Nombre entre 0 et 1.
static func float_value() -> float:
	return _rng.randf()


static func pick(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[_rng.randi_range(0, values.size() - 1)]


## Mélange de Fisher-Yates, sur place.
static func shuffle(values: Array) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var other: int = _rng.randi_range(0, index)
		var temp: Variant = values[index]
		values[index] = values[other]
		values[other] = temp
