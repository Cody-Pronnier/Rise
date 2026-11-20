class_name DeckList
extends RefCounted
## Un deck enregistré par le joueur : son nom, sa classe et ses cartes (ids, doublons compris).

var name: String
var class_id: StringName
var card_ids: Array[StringName] = []


func _init(p_name: String = "", p_class_id: StringName = &"", p_card_ids: Array[StringName] = []) -> void:
	name = p_name
	class_id = p_class_id
	card_ids = p_card_ids.duplicate()


func count_of(card_id: StringName) -> int:
	return card_ids.count(card_id)


func is_valid() -> bool:
	var class_data: ClassData = ClassCatalog.find(class_id)
	return class_data != null and DeckRules.is_valid(class_data, card_ids)
