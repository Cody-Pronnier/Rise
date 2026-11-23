class_name ClassCatalog
extends RefCounted
## Point d'accès unique aux classes jouables. Construites une seule fois.

## Scripts chargés par chemin plutôt que par class_name : ne dépend pas du cache
## des classes globales de l'éditeur, qui n'est pas toujours à jour après un ajout de fichiers.
const PRIEST := preload("res://core/classes/priest_class.gd")
const MAGE := preload("res://core/classes/mage_class.gd")
const ARCHER := preload("res://core/classes/archer_class.gd")
const ROGUE := preload("res://core/classes/rogue_class.gd")
const DRUID := preload("res://core/classes/druid_class.gd")
const WARRIOR := preload("res://core/classes/warrior_class.gd")
const NECROMANCER := preload("res://core/classes/necromancer_class.gd")
const MERCHANT := preload("res://core/classes/merchant_class.gd")

## Classes activées : passe une classe à false pour la retirer du jeu (sélection, tirage
## des bots, codex, decks, menu). Une classe absente de la liste est activée.
const ENABLED: Dictionary[StringName, bool] = {
	&"priest": false,
	&"mage": true,
	&"archer": true,
	&"rogue": true,
	&"druid": false,
	&"warrior": true,
	&"necromancer": false,
	&"merchant": false,
}

static var _classes: Array[ClassData] = []
static var _enabled_classes: Array[ClassData] = []


## Classes jouables (activées uniquement).
static func get_all() -> Array[ClassData]:
	if _enabled_classes.is_empty():
		_enabled_classes = _build_enabled()
	return _enabled_classes


## Cherche aussi parmi les classes désactivées : les cartes et les anciens decks
## d'une classe désactivée restent lisibles.
static func find(class_id: StringName) -> ClassData:
	for class_data: ClassData in _get_every_class():
		if class_data.id == class_id:
			return class_data
	return null


static func is_enabled(class_id: StringName) -> bool:
	return ENABLED.get(class_id, true)


static func pick_random() -> ClassData:
	return get_all().pick_random()


static func _get_every_class() -> Array[ClassData]:
	if _classes.is_empty():
		_classes = _build_all()
	return _classes


## Si toutes les classes sont désactivées par erreur, on les garde toutes pour que le jeu reste jouable.
static func _build_enabled() -> Array[ClassData]:
	var enabled: Array[ClassData] = _get_every_class().filter(func(class_data: ClassData) -> bool: return is_enabled(class_data.id))
	if enabled.is_empty():
		push_warning("ClassCatalog : toutes les classes sont désactivées, elles sont toutes réactivées.")
		return _get_every_class()
	return enabled


static func _build_all() -> Array[ClassData]:
	var classes: Array[ClassData] = [
		PRIEST.build(),
		MAGE.build(),
		ARCHER.build(),
		ROGUE.build(),
		DRUID.build(),
		WARRIOR.build(),
		NECROMANCER.build(),
		MERCHANT.build(),
	]
	return classes
