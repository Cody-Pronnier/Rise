class_name TradeDialog
extends PanelContainer
## Fenêtre pour composer une offre : cartes et points donnés, cartes et points demandés, alliance.
## Chaque carte affiche son effet sous son nom.
## Elle ne fait que construire un TradeOffer ; l'envoi est fait par l'écran.

signal submitted(offer: TradeOffer)
signal cancelled

const CARD_FONT_SIZE: int = 15

@onready var _title_label: Label = %TitleLabel
@onready var _give_cards: VBoxContainer = %GiveCards
@onready var _ask_cards: VBoxContainer = %AskCards
@onready var _give_points: SpinBox = %GivePoints
@onready var _ask_points: SpinBox = %AskPoints
@onready var _alliance_check: CheckBox = %AllianceCheck
@onready var _error_label: Label = %ErrorLabel
@onready var _cancel_button: Button = %CancelButton
@onready var _send_button: Button = %SendButton

var _target_id: int = -1
var _give_checks: Dictionary[CheckBox, CardData] = {}
var _ask_checks: Dictionary[CheckBox, CardData] = {}


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.menu_panel())
	UiStyle.style_button(_cancel_button, false)
	UiStyle.style_button(_send_button, true)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_send_button.pressed.connect(_on_send_pressed)
	hide()


## alliance_error : "" si l'alliance est possible, sinon la raison affichée en infobulle.
## propose_alliance : coche d'avance la case alliance (si elle est possible).
func open(local_player: PlayerState, target: PlayerState, alliance_error: String, propose_alliance: bool = false) -> void:
	_target_id = target.id
	_title_label.text = "Échange avec %s" % target.display_name
	_fill_card_list(_give_cards, local_player.hand, _give_checks)
	_fill_card_list(_ask_cards, target.hand, _ask_checks)
	_reset_points(_give_points, local_player.points)
	_reset_points(_ask_points, target.points)
	_reset_alliance_check(alliance_error)
	_alliance_check.button_pressed = propose_alliance and alliance_error.is_empty()
	_error_label.text = ""
	show()


func show_error(message: String) -> void:
	_error_label.text = message


# --- Construction -----------------------------------------------------------

func _fill_card_list(container: VBoxContainer, cards: Array[CardData], checks: Dictionary[CheckBox, CardData]) -> void:
	for child: Node in container.get_children():
		child.queue_free()
	checks.clear()
	for card: CardData in cards:
		var check: CheckBox = _create_card_check(card)
		container.add_child(check)
		container.add_child(CardInfo.create_description(card))
		checks[check] = card


func _create_card_check(card: CardData) -> CheckBox:
	var check := CheckBox.new()
	check.text = CardInfo.display_name(card)
	check.focus_mode = Control.FOCUS_NONE
	check.add_theme_font_size_override("font_size", CARD_FONT_SIZE)
	check.add_theme_color_override("font_color", CardPalette.class_color(card).lightened(0.35))
	return check


func _reset_points(spin_box: SpinBox, available: int) -> void:
	spin_box.min_value = 0
	spin_box.max_value = maxi(available, 0)
	spin_box.value = 0
	spin_box.editable = available > 0


func _reset_alliance_check(alliance_error: String) -> void:
	_alliance_check.button_pressed = false
	_alliance_check.disabled = not alliance_error.is_empty()
	_alliance_check.tooltip_text = alliance_error if not alliance_error.is_empty() else \
		"Protection mutuelle, points de manche partagés et vision partagée."


func _build_offer() -> TradeOffer:
	var offer := TradeOffer.new()
	offer.to_id = _target_id
	offer.given_cards = _checked_cards(_give_checks)
	offer.requested_cards = _checked_cards(_ask_checks)
	offer.given_points = int(_give_points.value)
	offer.requested_points = int(_ask_points.value)
	offer.proposes_alliance = _alliance_check.button_pressed
	return offer


func _checked_cards(checks: Dictionary[CheckBox, CardData]) -> Array[CardData]:
	var cards: Array[CardData] = []
	for check: CheckBox in checks:
		if check.button_pressed:
			cards.append(checks[check])
	return cards


# --- Réactions --------------------------------------------------------------

func _on_send_pressed() -> void:
	submitted.emit(_build_offer())


func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
