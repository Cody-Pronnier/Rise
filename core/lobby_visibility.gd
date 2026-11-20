class_name LobbyVisibility
extends RefCounted
## Qui peut voir et rejoindre le salon.
## - PUBLIC : visible dans la recherche de partie.
## - FRIENDS : invisible dans la recherche ; les amis Steam le rejoignent depuis leur liste d'amis.
## - PRIVATE : uniquement sur invitation.

enum Type { PUBLIC, FRIENDS, PRIVATE }

const LABELS: Dictionary[Type, String] = {
	Type.PUBLIC: "Public",
	Type.FRIENDS: "Amis seulement",
	Type.PRIVATE: "Sur invitation",
}


static func label(type: Type) -> String:
	return LABELS.get(type, LABELS[Type.PUBLIC])


static func from_string(value: String) -> Type:
	var number: int = value.to_int()
	return number as Type if LABELS.has(number as Type) else Type.PUBLIC


## Remplit un OptionButton avec les trois visibilités (l'id de chaque entrée est le Type).
static func fill_option(option: OptionButton, selected: Type) -> void:
	option.clear()
	for type: Type in LABELS:
		option.add_item(LABELS[type], type)
	option.select(option.get_item_index(selected))


static func selected_in(option: OptionButton) -> Type:
	return option.get_selected_id() as Type
