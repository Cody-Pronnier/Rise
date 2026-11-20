class_name TradeNotificationChip
extends Button
## Petite tuile d'offre reçue (même taille que la languette de l'historique) : icône de la classe
## de l'expéditeur, pastille du type d'offre en haut à droite (poignée de main bleue = alliance,
## flèches dorées = échange) et temps restant. Un clic ouvre le détail de l'offre.

const CHIP_SIZE := Vector2(52, 56)
const ALLIANCE_EMBLEM: Texture2D = preload("res://assets/icons/ui/alliance.svg")
const TRADE_EMBLEM: Texture2D = preload("res://assets/icons/ui/trade.svg")
const EMBLEM_SIZE: float = 24.0
const RADIUS: int = 12
const TRADE_COLOR := Color(1.0, 0.78, 0.3)
const ALLIANCE_COLOR := Color(0.5, 0.85, 1.0)
const PULSE_DURATION: float = 1.0
const BAR_HEIGHT: float = 5.0

var offer: TradeOffer

var _timer_bar: ProgressBar


func setup(p_offer: TradeOffer, sender: PlayerState) -> void:
	offer = p_offer
	custom_minimum_size = CHIP_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_END
	focus_mode = Control.FOCUS_NONE
	icon = ClassIcons.for_class(sender.class_data.id)
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_text = "%s te propose %s — clique pour voir" % [sender.display_name, _describe_kind()]
	add_theme_constant_override("icon_max_width", 34)
	_apply_styles()
	_create_timer_bar()
	_create_emblem()
	_start_pulse()


func _describe_kind() -> String:
	if offer.is_alliance_only():
		return "une alliance"
	return "un échange avec alliance" if offer.proposes_alliance else "un échange"


func _process(_delta: float) -> void:
	_timer_bar.value = offer.remaining_time / CombatConfig.TRADE_OFFER_TIMEOUT


## Bordure dorée pour un échange, cyan si l'offre contient une alliance.
func _apply_styles() -> void:
	var border: Color = ALLIANCE_COLOR if offer.is_alliance_only() else TRADE_COLOR
	add_theme_stylebox_override("normal", _build_style(UiStyle.PANEL_DARK, border, 0))
	add_theme_stylebox_override("hover", _build_style(UiStyle.PANEL_LIGHT, border.lightened(0.3), 12))
	add_theme_stylebox_override("pressed", _build_style(UiStyle.PANEL_LIGHT, border, 6))


func _build_style(bg: Color, border: Color, glow: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = UiStyle.with_shadow(UiStyle.box(Color(bg, 0.95), RADIUS, border, 2), Color(border, 0.5), glow)
	return UiStyle.with_margins(style, 6.0, 6.0)


func _create_timer_bar() -> void:
	_timer_bar = ProgressBar.new()
	_timer_bar.show_percentage = false
	_timer_bar.max_value = 1.0
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_bar.add_theme_stylebox_override("background", UiStyle.box(Color(0, 0, 0, 0.6), 2))
	_timer_bar.add_theme_stylebox_override("fill", UiStyle.box(ALLIANCE_COLOR if offer.is_alliance_only() else TRADE_COLOR, 2))
	add_child(_timer_bar)
	_timer_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_timer_bar.offset_left = 6.0
	_timer_bar.offset_right = -6.0
	_timer_bar.offset_top = -BAR_HEIGHT - 4.0
	_timer_bar.offset_bottom = -4.0


## Pastille qui dépasse en haut à droite, comme la bulle de l'historique.
func _create_emblem() -> void:
	var emblem := TextureRect.new()
	emblem.texture = ALLIANCE_EMBLEM if offer.is_alliance_only() else TRADE_EMBLEM
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(emblem)
	emblem.anchor_left = 1.0
	emblem.anchor_right = 1.0
	emblem.offset_left = -EMBLEM_SIZE + 8.0
	emblem.offset_right = 8.0
	emblem.offset_top = -8.0
	emblem.offset_bottom = EMBLEM_SIZE - 8.0


func _start_pulse() -> void:
	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate", Color(1.25, 1.25, 1.25), PULSE_DURATION / 2.0)
	tween.tween_property(self, "modulate", Color.WHITE, PULSE_DURATION / 2.0)
