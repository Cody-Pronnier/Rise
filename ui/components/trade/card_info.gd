class_name CardInfo
extends RefCounted
## Petits blocs « nom de la carte + ce qu'elle fait », pour les joueurs qui ne connaissent pas
## encore les cartes par cœur (offres d'échange, fenêtre d'échange).

const NAME_FONT_SIZE: int = 15
const DESCRIPTION_FONT_SIZE: int = 12
const DESCRIPTION_INDENT: int = 28


## Nom (couleur de la classe) puis description en dessous.
## width : largeur fixe du texte ; sans elle, un texte à retour à la ligne automatique peut
## annoncer une hauteur énorme au premier calcul de mise en page.
static func create(card: CardData, width: float = 0.0) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	box.add_child(_create_name_label(card))
	box.add_child(create_description(card, 0, width))
	return box


## Description seule, décalée de `indent` pixels (pour se placer sous une case à cocher).
static func create_description(card: CardData, indent: int = DESCRIPTION_INDENT, width: float = 0.0) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", indent)
	var label := Label.new()
	label.text = "%s · %s" % [card.description, card.describe_target().to_lower()]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = maxf(width - indent, 0.0)
	label.add_theme_font_size_override("font_size", DESCRIPTION_FONT_SIZE)
	label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	margin.add_child(label)
	return margin


static func display_name(card: CardData) -> String:
	return card.display_name + (" (ultime)" if card.is_ultimate else "")


static func _create_name_label(card: CardData) -> Label:
	var label := Label.new()
	label.text = display_name(card)
	label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	label.add_theme_color_override("font_color", CardPalette.class_color(card).lightened(0.35))
	return label
