class_name TradeOfferPopup
extends PanelContainer
## Détail d'une offre reçue, ouvert en cliquant sur sa tuile (TradeInbox) :
## ce qu'on reçoit et ce qu'on donne (avec l'effet de chaque carte), le temps restant,
## Accepter / Refuser, ou × pour refermer sans répondre.

signal accept_pressed(offer_id: int)
signal decline_pressed(offer_id: int)

const ALLIANCE_COLOR := Color(0.5, 0.85, 1.0)
const RECEIVE_COLOR := Color(0.55, 0.95, 0.6)
const GIVE_COLOR := Color(1.0, 0.6, 0.5)
const SECTION_FONT_SIZE: int = 15
## Largeur du texte = largeur de la fenêtre (440) moins ses marges intérieures.
const CONTENT_WIDTH: float = 400.0

@onready var _title_label: Label = %TitleLabel
@onready var _details_list: VBoxContainer = %DetailsList
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _decline_button: Button = %DeclineButton
@onready var _accept_button: Button = %AcceptButton
@onready var _close_button: Button = %CloseButton

var _offer: TradeOffer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.96), 14, ALLIANCE_COLOR, 2), UiStyle.SHADOW, 14), 18.0, 14.0))
	_timer_bar.add_theme_stylebox_override("background", UiStyle.box(Color(0, 0, 0, 0.5), 3))
	_timer_bar.add_theme_stylebox_override("fill", UiStyle.box(ALLIANCE_COLOR, 3))
	UiStyle.style_button(_decline_button, false)
	UiStyle.style_button(_accept_button, true)
	_decline_button.pressed.connect(_on_decline_pressed)
	_accept_button.pressed.connect(_on_accept_pressed)
	_close_button.pressed.connect(close)
	_close_button.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	_close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	hide()


func _process(_delta: float) -> void:
	if _offer:
		_timer_bar.value = _offer.remaining_time / CombatConfig.TRADE_OFFER_TIMEOUT


func show_offer(offer: TradeOffer, sender: PlayerState) -> void:
	_offer = offer
	_display(offer, sender)
	show()
	set_process(true)


func close() -> void:
	_offer = null
	hide()
	set_process(false)


## L'offre affichée a été acceptée, refusée ou a expiré.
func close_if_showing(offer_id: int) -> void:
	if _offer and _offer.id == offer_id:
		close()


func _display(offer: TradeOffer, sender: PlayerState) -> void:
	_title_label.text = "%s te propose" % sender.display_name
	_timer_bar.max_value = 1.0
	_clear_details()
	_add_goods_section("Tu reçois", RECEIVE_COLOR, offer.given_cards, offer.given_points)
	_add_goods_section("Tu donnes", GIVE_COLOR, offer.requested_cards, offer.requested_points)
	if offer.proposes_alliance:
		_details_list.add_child(_create_section_label("Une alliance pour la manche (protection, points partagés, vision)", ALLIANCE_COLOR))
	_shrink_to_content.call_deferred()


## Les anciennes lignes sont retirées tout de suite (queue_free seul les laisserait compter
## dans la taille jusqu'à la fin de l'image).
func _clear_details() -> void:
	for child: Node in _details_list.get_children():
		_details_list.remove_child(child)
		child.queue_free()


## Une fois le contenu mis en page (on attend une image), on ramène la hauteur au strict
## nécessaire : un Control ne rétrécit jamais tout seul, il ne fait que grandir.
func _shrink_to_content() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		size = Vector2(size.x, 0.0)


func _add_goods_section(title: String, color: Color, cards: Array[CardData], points: int) -> void:
	if cards.is_empty() and points <= 0:
		return
	_details_list.add_child(_create_section_label(title, color))
	for card: CardData in cards:
		_details_list.add_child(CardInfo.create(card, CONTENT_WIDTH))
	if points > 0:
		_details_list.add_child(_create_section_label("%d point%s" % [points, "s" if points > 1 else ""], Color.WHITE))


func _create_section_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = CONTENT_WIDTH
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _on_accept_pressed() -> void:
	if _offer:
		accept_pressed.emit(_offer.id)


func _on_decline_pressed() -> void:
	if _offer:
		decline_pressed.emit(_offer.id)
