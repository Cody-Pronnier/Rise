class_name CardPalette
extends RefCounted
## Couleurs, textures et libellés d'une carte, déduits de sa classe.

const NEUTRAL_COLOR := Color(0.62, 0.64, 0.72)
const PODIUM_COLOR := Color(1.0, 0.78, 0.3)
const NEUTRAL_INITIAL: String = "N"
const ART_PATH: String = "res://assets/cards/%s.svg"
## Sujet détouré des cartes ultimes, qui déborde du cadre (« overframe »).
const OVERFRAME_PATH: String = "res://assets/cards/%s_pop.svg"

static var _art_cache: Dictionary[StringName, GradientTexture2D] = {}


static func class_color(card: CardData) -> Color:
	if card.class_id == PodiumCards.CLASS_ID:
		return PODIUM_COLOR
	var class_data: ClassData = ClassCatalog.find(card.class_id)
	return class_data.character.color if class_data else NEUTRAL_COLOR


static func class_initial(card: CardData) -> String:
	var class_data: ClassData = ClassCatalog.find(card.class_id)
	return class_data.display_name.left(1) if class_data else NEUTRAL_INITIAL


static func kind_label(card: CardData) -> String:
	var kind: String = "Soutien" if card.is_beneficial else "Offensive"
	if card.class_id == NeutralCards.CLASS_ID:
		return "Neutre · %s" % kind
	if card.class_id == PodiumCards.CLASS_ID:
		return "Podium · Unique"
	return "Ultime · %s" % kind if card.is_ultimate else kind


## Illustration de la carte (res://assets/cards/<id>.svg) ; à défaut, dégradé aux couleurs de la classe.
static func art_texture(card: CardData) -> Texture2D:
	var path: String = ART_PATH % card.id
	if ResourceLoader.exists(path):
		return load(path)
	return _fallback_art(card)


## null si la carte n'a pas de calque qui déborde du cadre.
static func overframe_texture(card: CardData) -> Texture2D:
	var path: String = OVERFRAME_PATH % card.id
	return load(path) if ResourceLoader.exists(path) else null


static func _fallback_art(card: CardData) -> GradientTexture2D:
	if not _art_cache.has(card.class_id):
		_art_cache[card.class_id] = _build_art_texture(class_color(card))
	return _art_cache[card.class_id]


static func _build_art_texture(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, color.lightened(0.2))
	gradient.set_color(1, color.darkened(0.65))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.3)
	texture.fill_to = Vector2(1.0, 1.0)
	return texture
