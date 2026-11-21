class_name ClassData
extends Resource
## Une classe jouable : les stats de son personnage, ses cartes et son deck de départ.

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var character: UnitData
@export var cards: Array[CardData] = []
## Deck de départ : id de carte → nombre d'exemplaires. Vide = 3 exemplaires de chaque
## carte normale + l'ultime (voir DeckRules.default_deck_ids).
var starter_deck: Dictionary[StringName, int] = {}
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


## Deck de départ fixe, utile quand la classe a plus de cartes que n'en contient un deck.
func with_starter_deck(counts: Dictionary[StringName, int]) -> ClassData:
	starter_deck = counts
	return self


func create_passive() -> ClassPassive:
	return passive_factory.call() if passive_factory.is_valid() else ClassPassive.new()


func _tag_cards() -> void:
	for card: CardData in cards:
		card.class_id = id
