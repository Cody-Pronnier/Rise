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

static var _classes: Array[ClassData] = []


static func get_all() -> Array[ClassData]:
	if _classes.is_empty():
		_classes = _build_all()
	return _classes


static func find(class_id: StringName) -> ClassData:
	for class_data: ClassData in get_all():
		if class_data.id == class_id:
			return class_data
	return null


static func pick_random() -> ClassData:
	return get_all().pick_random()


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
