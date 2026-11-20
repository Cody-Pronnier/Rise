class_name HistoryPanel
extends HBoxContainer
## Historique de la manche, sur le bord gauche de l'écran : une languette (icône de parchemin) ouvre
## ou ferme la liste des actions des joueurs (cartes jouées, échanges et alliances proposés,
## alliances conclues ou rompues, joueurs qui terminent…).
## Le contenu des échanges reste secret : on voit qui propose quoi à qui, jamais les cartes.
## Lecture seule : il écoute les signaux de la manche.

const PANEL_SIZE := Vector2(320, 340)
const MAX_ENTRIES: int = 80
const FONT_SIZE: int = 13
const HANDLE_ICON: Texture2D = preload("res://assets/icons/ui/history.svg")
const HANDLE_ICON_SIZE: int = 36
const BADGE_COLOR := Color(0.86, 0.2, 0.2)
const BADGE_SIZE: float = 22.0
const BADGE_POP_SCALE: float = 1.35
const TIME_COLOR := "#8a86a0"
const LOCAL_COLOR := "#ffc84d"
const PLAYER_COLOR := "#f4ecd8"
const CARD_COLOR := "#ffffff"
const TRADE_COLOR := "#ffd27a"
const ALLIANCE_COLOR := "#80d8ff"
const BREAK_COLOR := "#ff8a80"
const FINISH_COLOR := "#8cf09a"
const MONSTER_COLOR := "#ff9a7a"
const COMPANION_COLOR := "#a8e0b0"

var _round: CombatRound
var _local_id: int
var _elapsed: float = 0.0
var _unread: int = 0
var _panel := PanelContainer.new()
var _scroll := ScrollContainer.new()
var _entries := VBoxContainer.new()
var _handle := Button.new()
## Bulle rouge en haut à droite de l'icône : nombre de nouvelles actions non lues.
var _badge := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel()
	_build_handle()
	_panel.hide()
	_refresh_handle()


func _process(delta: float) -> void:
	_elapsed += delta


func setup(combat_round: CombatRound, local_id: int) -> void:
	_round = combat_round
	_local_id = local_id
	_round.card_played.connect(_on_card_played)
	_round.ability_used.connect(_on_ability_used)
	_round.player_finished.connect(_on_player_finished)
	_round.trades.offer_proposed.connect(_on_offer_proposed)
	_round.trades.offer_resolved.connect(_on_offer_resolved)
	_round.alliances.alliance_broken.connect(_on_alliance_broken)


func toggle() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		_unread = 0
		_scroll_to_bottom.call_deferred()
	_refresh_handle()


# --- Construction -----------------------------------------------------------

func _build_panel() -> void:
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.with_shadow(UiStyle.box(Color(UiStyle.PANEL_DARK, 0.9), 10, Color(UiStyle.GOLD, 0.4), 1), UiStyle.SHADOW, 8), 10.0, 8.0))
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entries.add_theme_constant_override("separation", 4)
	_scroll.add_child(_entries)
	_panel.add_child(_scroll)
	add_child(_panel)


func _build_handle() -> void:
	_handle.focus_mode = Control.FOCUS_NONE
	_handle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_handle.custom_minimum_size = Vector2(52, 56)
	_handle.tooltip_text = "Historique de la manche"
	_handle.icon = HANDLE_ICON
	_handle.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_handle.expand_icon = true
	UiStyle.style_button(_handle, false)
	_handle.add_theme_constant_override("icon_max_width", HANDLE_ICON_SIZE)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBox = _handle.get_theme_stylebox(state).duplicate()
		style.content_margin_left = 6.0
		style.content_margin_right = 6.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		_handle.add_theme_stylebox_override(state, style)
	_handle.pressed.connect(toggle)
	_build_badge()
	add_child(_handle)


func _build_badge() -> void:
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.custom_minimum_size = Vector2(BADGE_SIZE, BADGE_SIZE)
	_badge.add_theme_font_size_override("font_size", 12)
	_badge.add_theme_color_override("font_color", Color.WHITE)
	_badge.add_theme_stylebox_override("normal", UiStyle.with_margins(UiStyle.box(BADGE_COLOR, int(BADGE_SIZE / 2.0), Color(0.15, 0.02, 0.02), 2), 5.0, 0.0))
	## Ancrée en haut à droite ; elle s'élargit vers la gauche au-delà de 9.
	_badge.anchor_left = 1.0
	_badge.anchor_right = 1.0
	_badge.offset_left = -BADGE_SIZE + 6.0
	_badge.offset_right = 6.0
	_badge.offset_top = -6.0
	_badge.offset_bottom = BADGE_SIZE - 6.0
	_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_badge.hide()
	_handle.add_child(_badge)


## Bulle rouge avec le nombre de nouvelles entrées non lues (cachée quand tout est lu).
func _refresh_handle() -> void:
	var has_unread: bool = _unread > 0 and not _panel.visible
	_badge.visible = has_unread
	_badge.text = "99+" if _unread > 99 else str(_unread)


## Petit rebond de la bulle à chaque nouvelle entrée.
func _pop_badge() -> void:
	_badge.pivot_offset = _badge.size / 2.0
	var tween: Tween = _badge.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_badge.scale = Vector2.ONE * BADGE_POP_SCALE
	tween.tween_property(_badge, "scale", Vector2.ONE, 0.25)


# --- Entrées ----------------------------------------------------------------

func _add_entry(bbcode: String) -> void:
	var entry := RichTextLabel.new()
	entry.bbcode_enabled = true
	entry.fit_content = true
	entry.scroll_active = false
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	entry.text = "[color=%s]%s[/color]  %s" % [TIME_COLOR, _format_time(), bbcode]
	_entries.add_child(entry)
	_trim_entries()
	if _panel.visible:
		_scroll_to_bottom.call_deferred()
	else:
		_unread += 1
		_refresh_handle()
		_pop_badge()


func _trim_entries() -> void:
	while _entries.get_child_count() > MAX_ENTRIES:
		var oldest: Node = _entries.get_child(0)
		_entries.remove_child(oldest)
		oldest.queue_free()


func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _format_time() -> String:
	var seconds: int = floori(_elapsed)
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _name(player_id: int) -> String:
	if player_id == _local_id:
		return "[color=%s]Toi[/color]" % LOCAL_COLOR
	var player: PlayerState = _round.players[player_id]
	var short_name: String = player.display_name.trim_suffix(" (%s)" % player.class_data.display_name)
	return "[color=%s]%s[/color]" % [PLAYER_COLOR, short_name]


func _colored(text: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, text]


# --- Réactions --------------------------------------------------------------

func _on_card_played(caster_id: int, card: CardData, target: CardTarget) -> void:
	var card_name: String = _colored(card.display_name, CARD_COLOR)
	var destination: String = _describe_destination(caster_id, card, target)
	_add_entry("%s joue %s%s" % [_name(caster_id), card_name, destination])


## Précise la cible : le personnage, un compagnon ou le monstre, et sur quel terrain.
func _describe_destination(caster_id: int, card: CardData, target: CardTarget) -> String:
	var is_own_field: bool = target.player_id == caster_id
	match card.target_mode:
		CardData.TargetMode.ALL_FIELDS:
			return " sur tous les terrains"
		CardData.TargetMode.SELF:
			return ""
		CardData.TargetMode.FIELD:
			return " sur tout son terrain" if is_own_field else " sur tout le terrain de %s" % _name(target.player_id)
		CardData.TargetMode.UNIT:
			return _describe_unit_target(caster_id, target)
		_:
			return " sur %s" % _name(target.player_id)


func _describe_unit_target(caster_id: int, target: CardTarget) -> String:
	var unit: CombatUnit = target.unit
	if unit == null:
		return ""
	var is_own_field: bool = target.player_id == caster_id
	if unit == _round.fields[target.player_id].character:
		if is_own_field:
			return " sur toi-même" if caster_id == _local_id else " sur lui-même"
		return " sur %s" % _name(target.player_id)
	var unit_name: String = _colored(unit.data.display_name, MONSTER_COLOR if unit.side == CombatUnit.Side.MONSTER else COMPANION_COLOR)
	if is_own_field:
		return " sur %s (son terrain)" % unit_name if caster_id != _local_id else " sur %s (ton terrain)" % unit_name
	return " sur %s de %s" % [unit_name, _name(target.player_id)]


func _on_ability_used(player_id: int) -> void:
	_add_entry("%s %s" % [_name(player_id), _round.fields[player_id].passive.describe_ability_use()])


func _on_player_finished(player_id: int, rank: int) -> void:
	_add_entry(_colored("%s termine sa manche (#%d)" % [_name(player_id), rank], FINISH_COLOR))


## Le contenu reste secret : seulement « échange » ou « alliance ».
func _on_offer_proposed(offer: TradeOffer) -> void:
	if offer.is_alliance_only():
		_add_entry("%s %s à %s" % [_name(offer.from_id), _colored("propose une alliance", ALLIANCE_COLOR), _name(offer.to_id)])
	else:
		_add_entry("%s %s à %s" % [_name(offer.from_id), _colored("propose un échange", TRADE_COLOR), _name(offer.to_id)])


func _on_offer_resolved(offer: TradeOffer, accepted: bool, reason: String) -> void:
	if accepted and offer.proposes_alliance:
		_add_entry("%s et %s %s" % [_name(offer.from_id), _name(offer.to_id), _colored("sont maintenant alliés", ALLIANCE_COLOR)])
	elif accepted:
		_add_entry("%s et %s %s" % [_name(offer.from_id), _name(offer.to_id), _colored("ont conclu un échange", TRADE_COLOR)])
	elif reason == "Offre refusée.":
		_add_entry("%s refuse l'offre de %s" % [_name(offer.to_id), _name(offer.from_id)])


func _on_alliance_broken(breaker_id: int, ally_id: int) -> void:
	_add_entry("%s %s avec %s" % [_name(breaker_id), _colored("rompt son alliance", BREAK_COLOR), _name(ally_id)])
