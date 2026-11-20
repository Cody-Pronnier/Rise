class_name ClassData
extends Resource
## Une classe jouable : les stats de son personnage et ses 6 cartes.

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var character: UnitData
@export var cards: Array[CardData] = []
## Mécanique unique de la classe, affichée dans le codex ("" si aucune).
@export var passive_description: String = ""
## Crée un ClassPassive neuf pour chaque terrain. Vide = aucune règle spéciale.
var passive_factory: Callable


static func create(
	p_id: StringName,
	p_display_name: String,
	p_description: String,
	p_character: UnitData,
	p_cards: Array[CardData]
) -> ClassData:
	var data := ClassData.new()
	data.id = p_id
	data.display_name = p_display_name
	data.description = p_description
	data.character = p_character
	data.cards = p_cards
	data._tag_cards()
	return data


## Ajoute une mécanique unique à la classe (voir ClassPassive).
func with_passive(factory: Callable, description: String) -> ClassData:
	passive_factory = factory
	passive_description = description
	return self


func create_passive() -> ClassPassive:
	return passive_factory.call() if passive_factory.is_valid() else ClassPassive.new()


func _tag_cards() -> void:
	for card: CardData in cards:
		card.class_id = id
