class_name CardView
extends Control
## Visuel d'une carte. Ne gère pas la souris : c'est HandView qui décide du survol et du clic,
## puis pousse une pose (position, rotation, échelle) que la carte rejoint en douceur.

const BACKGROUND_COLOR := Color(0.13, 0.12, 0.17)
const FRAME_RADIUS: int = 12
const FRAME_BORDER: int = 3
const GEM_RADIUS: int = 17
const MANA_COLOR := Color(0.25, 0.5, 1.0)
const COST_ORB_SIZE: float = 34.0
const UNAFFORDABLE_TINT := Color(0.62, 0.62, 0.72)
const UNAFFORDABLE_COST_COLOR := Color(1.0, 0.45, 0.45)

@onready var _glow: Panel = %Glow
@onready var _frame: Panel = %Frame
@onready var _banner: PanelContainer = %Banner
@onready var _name_label: Label = %NameLabel
@onready var _art: TextureRect = %Art
@onready var _kind_label: Label = %KindLabel
@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _target_label: Label = %TargetLabel
@onready var _gem: Panel = %Gem
@onready var _gem_label: Label = %GemLabel
@onready var _gem_icon: TextureRect = %GemIcon
@onready var _vbox: VBoxContainer = %VBox
@onready var _overframe: TextureRect = %Overframe
@onready var _shine: ColorRect = %Shine

var _card: CardData
## Multiplicateur affiché dans le texte (bonus de rattrapage) : 1.0 = valeurs normales.
var _power: float = 1.0
var _breath_tween: Tween
## Pastille du coût en mana, en haut à droite (créée par le code).
var _cost_orb := Panel.new()
var _cost_label := Label.new()


func _ready() -> void:
	size = HandLayout.CARD_SIZE
	pivot_offset = size / 2.0
	_glow.add_theme_stylebox_override("panel", _build_glow_style())
	_glow.hide()
	_build_cost_orb()


## À appeler après add_child() pour que les nœuds @onready soient prêts.
func display(card: CardData) -> void:
	_card = card
	_name_label.text = card.display_name
	_kind_label.text = CardPalette.kind_label(card)
	_description_label.text = CardText.describe(card, _power)
	_target_label.text = card.describe_target()
	_art.texture = CardPalette.art_texture(card)
	_display_gem()
	_cost_label.text = str(card.cost)
	_apply_class_styles()
	_apply_ultimate_layout()


func get_card() -> CardData:
	return _card


## Renforce les valeurs affichées (en vert) ; 1.0 les remet à la normale.
func set_power(power: float) -> void:
	if is_equal_approx(power, _power) or _card == null:
		_power = power
		return
	_power = power
	_description_label.text = CardText.describe(_card, _power)


## Carte trop chère pour le mana actuel : grisée, coût en rouge.
func set_affordable(affordable: bool) -> void:
	modulate = Color.WHITE if affordable else UNAFFORDABLE_TINT
	_cost_label.add_theme_color_override("font_color", Color.WHITE if affordable else UNAFFORDABLE_COST_COLOR)


func set_selected(selected: bool) -> void:
	_glow.visible = selected


## Rejoint la pose cible ; weight entre 0 (immobile) et 1 (instantané).
func follow_pose(pose: HandLayout.Pose, weight: float) -> void:
	position = position.lerp(pose.center - size / 2.0, weight)
	rotation = lerp_angle(rotation, pose.rotation, weight)
	scale = scale.lerp(Vector2.ONE * pose.scale, weight)
	z_index = pose.z_index


func snap_to(center: Vector2) -> void:
	position = center - size / 2.0


## Point haut-centre de la carte, en coordonnées globales (départ de la flèche de ciblage).
func get_global_anchor() -> Vector2:
	return get_global_transform() * Vector2(size.x / 2.0, 0.0)


func _apply_class_styles() -> void:
	var color: Color = CardPalette.class_color(_card)
	_frame.add_theme_stylebox_override("panel", _build_frame_style(color))
	_banner.add_theme_stylebox_override("panel", _build_banner_style(color))
	## L'icône de classe a déjà son propre cadre rond : la pastille colorée ne sert qu'aux cartes neutres.
	_gem.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if _gem_icon.texture else _build_gem_style(color))


## Icône de la classe dans le coin ; à défaut (cartes neutres), l'initiale dans une pastille.
func _display_gem() -> void:
	_gem_icon.texture = ClassIcons.for_class(_card.class_id)
	_gem_icon.visible = _gem_icon.texture != null
	_gem_label.text = CardPalette.class_initial(_card)
	_gem_label.visible = _gem_icon.texture == null


func _build_frame_style(color: Color) -> StyleBoxFlat:
	if _card.is_ultimate:
		return UltimateCardStyle.frame_style(FRAME_RADIUS)
	var style: StyleBoxFlat = UiStyle.box(BACKGROUND_COLOR, FRAME_RADIUS, color, FRAME_BORDER)
	return UiStyle.with_shadow(style, UiStyle.SHADOW, 10, Vector2(0, 6))


func _build_banner_style(color: Color) -> StyleBoxFlat:
	if _card.is_ultimate:
		return UltimateCardStyle.banner_style()
	return UiStyle.with_margins(UiStyle.box(color.darkened(0.35), 6, color.lightened(0.2), 1), 6.0, 3.0)


## Ultime : illustration en haut avec son sujet qui déborde du cadre, nom en dessous, reflet animé.
## Une carte normale garde le nom en haut. Une même CardView peut changer de carte : on remet tout.
func _apply_ultimate_layout() -> void:
	var is_ultimate: bool = _card.is_ultimate
	_vbox.move_child(_banner, 1 if is_ultimate else 0)
	_name_label.add_theme_color_override("font_color", UltimateCardStyle.NAME_COLOR if is_ultimate else Color.WHITE)
	_shine.material = UltimateCardStyle.shine_material() if is_ultimate else null
	_shine.visible = is_ultimate
	_overframe.texture = CardPalette.overframe_texture(_card) if is_ultimate else null
	_overframe.visible = _overframe.texture != null
	_refresh_breathing.call_deferred()


## Attendu une image : la taille du calque n'est connue qu'après la mise en page.
func _refresh_breathing() -> void:
	if _breath_tween:
		_breath_tween.kill()
		_breath_tween = null
	_overframe.scale = Vector2.ONE
	if _overframe.visible:
		_breath_tween = UltimateCardStyle.start_breathing(_overframe)


func _build_cost_orb() -> void:
	_cost_orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_orb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_cost_orb.offset_left = -COST_ORB_SIZE + 8.0
	_cost_orb.offset_right = 8.0
	_cost_orb.offset_top = -8.0
	_cost_orb.offset_bottom = COST_ORB_SIZE - 8.0
	_cost_orb.add_theme_stylebox_override("panel", UiStyle.with_shadow(UiStyle.box(MANA_COLOR, int(COST_ORB_SIZE / 2.0), Color(0.8, 0.9, 1.0), 2), UiStyle.SHADOW, 4))
	_cost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_size_override("font_size", 18)
	_cost_label.add_theme_constant_override("outline_size", 5)
	_cost_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_cost_orb.add_child(_cost_label)
	add_child(_cost_orb)


func _build_gem_style(color: Color) -> StyleBoxFlat:
	return UiStyle.box(color, GEM_RADIUS, UiStyle.GOLD, 2)


func _build_glow_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = UiStyle.box(Color(0, 0, 0, 0), FRAME_RADIUS + 4, UiStyle.CYAN, 3)
	return UiStyle.with_shadow(style, Color(UiStyle.CYAN, 0.6), 16)
