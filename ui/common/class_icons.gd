class_name ClassIcons
extends RefCounted
## Icônes rondes des classes (SVG dans res://assets/icons/classes/).

const ICONS: Dictionary[StringName, Texture2D] = {
	&"priest": preload("res://assets/icons/classes/priest.svg"),
	&"mage": preload("res://assets/icons/classes/mage.svg"),
	&"archer": preload("res://assets/icons/classes/archer.svg"),
	&"rogue": preload("res://assets/icons/classes/rogue.svg"),
	&"druid": preload("res://assets/icons/classes/druid.svg"),
	&"warrior": preload("res://assets/icons/classes/warrior.svg"),
	&"necromancer": preload("res://assets/icons/classes/necromancer.svg"),
	&"merchant": preload("res://assets/icons/classes/merchant.svg"),
	## Pas une classe : l'icône des cartes neutres (NeutralCards.CLASS_ID).
	&"neutral": preload("res://assets/icons/classes/neutral.svg"),
	&"podium": preload("res://assets/icons/classes/podium.svg"),
}


## null si la classe n'a pas encore d'icône.
static func for_class(class_id: StringName) -> Texture2D:
	return ICONS.get(class_id)
