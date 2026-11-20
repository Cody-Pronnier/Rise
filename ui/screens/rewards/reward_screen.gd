extends Screen
## Entre deux manches :
## - « Garde 2 cartes » : 5 cartes tirées de la suite de son deck, on en garde 2, le reste est défaussé ;
## - « Boutique » : quelques cartes à acheter avec ses points (MAX_SHOP_PURCHASES sur toute la partie) ;
## - « Podium » : le draft des cartes uniques (1er, puis 2e, le 3e reçoit la dernière), visible
##   seulement par les joueurs du podium. On ne voit jamais ce que prennent les autres :
##   avant son tour rien, pendant son tour les cartes restantes, après son tour seulement la sienne ;
## - « Prêt ! » (une fois les 2 cartes choisies) : la manche suivante démarre quand tout le monde
##   est prêt (géré par MatchService).

## Taille des cartes : la plus grande qui tient à l'écran, sans dépasser MAX_CARD_SCALE.
## Les 8 cartes du haut (5 du deck + 3 en boutique) doivent tenir en largeur ; avec le draft du podium,
## deux rangées doivent aussi tenir en hauteur.
const MAX_CARD_SCALE: float = 1.0
const MIN_CARD_SCALE: float = 0.45
const TOP_ROW_CARDS: int = 8
## Largeur prise par tout sauf les cartes : marges de l'écran et des cadres, espaces entre cartes.
const HORIZONTAL_CHROME: float = 340.0
## Hauteur prise par tout sauf les cartes : titre, en-têtes, légendes, marges, bouton « Prêt ».
const VERTICAL_CHROME_WITH_PODIUM: float = 420.0
const VERTICAL_CHROME_WITHOUT_PODIUM: float = 300.0
const YOUR_TURN_COLOR := Color(1.0, 0.85, 0.3)
const RANK_LABELS: Array[String] = ["1er", "2e", "3e"]

@onready var _title_label: Label = %TitleLabel
@onready var _top_row: HBoxContainer = %TopRow
@onready var _unlocked_panel: PanelContainer = %UnlockedPanel
@onready var _unlocked_status_label: Label = %UnlockedStatusLabel
@onready var _unlocked_row: HBoxContainer = %UnlockedRow
@onready var _shop_panel: PanelContainer = %ShopPanel
@onready var _shop_status_label: Label = %ShopStatusLabel
@onready var _shop_row: HBoxContainer = %ShopRow
@onready var _draft_panel: PanelContainer = %DraftPanel
@onready var _draft_status_label: Label = %DraftStatusLabel
@onready var _draft_row: HBoxContainer = %DraftRow
@onready var _ready_status_label: Label = %ReadyStatusLabel
@onready var _ready_button: Button = %ReadyButton

var _phase: RewardPhase
var _local_id: int
var _shop_slots: Array[RewardCardSlot] = []
var _deck_slots: Array[RewardCardSlot] = []
var _kept_indices: Array[int] = []
var _is_sending_ready: bool = false


func _ready() -> void:
	_phase = MatchService.current_rewards
	_local_id = MatchService.local_player_id
	_apply_styles()
	_title_label.text = "Prépare la manche %d" % (MatchService.round_index + 2)
	_apply_layout()
	_build_unlocked_row()
	_build_shop_row()
	_connect_ui()
	_refresh_shop()
	_refresh_draft_section()
	_refresh_ready()


# --- Mise en place ----------------------------------------------------------

func _apply_styles() -> void:
	for panel: PanelContainer in [_unlocked_panel, _shop_panel, _draft_panel]:
		panel.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	UiStyle.style_button(_ready_button, true)


## Hors podium, le draft n'est pas affiché : les cartes passent en grand et le bloc est centré.
func _apply_layout() -> void:
	_draft_panel.visible = _is_on_podium()
	if not _is_on_podium():
		_top_row.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER


func _card_scale() -> float:
	var screen: Vector2 = get_viewport_rect().size
	var card: Vector2 = HandLayout.CARD_SIZE
	var by_width: float = (screen.x - HORIZONTAL_CHROME) / (card.x * TOP_ROW_CARDS)
	var rows: int = 2 if _is_on_podium() else 1
	var chrome: float = VERTICAL_CHROME_WITH_PODIUM if _is_on_podium() else VERTICAL_CHROME_WITHOUT_PODIUM
	var by_height: float = (screen.y - chrome) / (card.y * rows)
	return clampf(minf(by_width, by_height), MIN_CARD_SCALE, MAX_CARD_SCALE)


func _connect_ui() -> void:
	_ready_button.pressed.connect(_on_ready_pressed)
	_phase.shop_changed.connect(_on_shop_changed)
	_phase.player_ready.connect(_on_player_ready)
	_phase.draft_turn_changed.connect(_refresh_draft_section.unbind(1))
	MatchService.action_failed.connect(_on_action_failed)


func _build_unlocked_row() -> void:
	var offer: Array[CardData] = _phase.get_deck_offer(_local_id)
	for index: int in offer.size():
		var slot: RewardCardSlot = _add_slot(_unlocked_row, offer[index])
		slot.pressed.connect(_on_deck_slot_pressed.bind(index))
		_deck_slots.append(slot)
	_refresh_deck_choice()


# --- Cartes du deck à garder ------------------------------------------------

func _refresh_deck_choice() -> void:
	var is_locked: bool = _phase.is_ready(_local_id) or _is_sending_ready
	for index: int in _deck_slots.size():
		var kept: bool = _kept_indices.has(index)
		_deck_slots[index].set_selected(kept)
		_deck_slots[index].set_interactive(not is_locked)
		_deck_slots[index].set_taken(is_locked and not kept)
		_deck_slots[index].set_caption("Gardée" if kept else ("Défaussée" if is_locked else ""), YOUR_TURN_COLOR)
	_unlocked_status_label.text = "%d / %d choisies · le reste est défaussé" % [_kept_indices.size(), _phase.get_keep_count(_local_id)]
	_unlocked_status_label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)


func _toggle_kept(index: int) -> void:
	if _kept_indices.has(index):
		_kept_indices.erase(index)
	elif _kept_indices.size() < _phase.get_keep_count(_local_id):
		_kept_indices.append(index)


func _build_shop_row() -> void:
	var offer: Array[CardData] = _phase.get_shop_offer(_local_id)
	for index: int in offer.size():
		var slot: RewardCardSlot = _add_slot(_shop_row, offer[index])
		slot.pressed.connect(_on_shop_slot_pressed.bind(index))
		_shop_slots.append(slot)


func _is_on_podium() -> bool:
	return _phase.draft.get_pick_order().has(_local_id)


func _add_slot(row: HBoxContainer, card: CardData) -> RewardCardSlot:
	var slot := RewardCardSlot.new(_card_scale())
	row.add_child(slot)
	slot.display(card)
	return slot


# --- Boutique ---------------------------------------------------------------

func _refresh_shop() -> void:
	var player: PlayerState = _phase.get_player(_local_id)
	_shop_status_label.text = "Tes points : %d · Achats : %d / %d" % [player.points, player.purchases, CombatConfig.MAX_SHOP_PURCHASES]
	_shop_status_label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	for index: int in _shop_slots.size():
		_refresh_shop_slot(_shop_slots[index], index)


func _refresh_shop_slot(slot: RewardCardSlot, index: int) -> void:
	if _phase.is_bought(_local_id, index):
		slot.set_caption("Achetée", YOUR_TURN_COLOR)
		slot.set_taken(false)
		slot.set_interactive(false)
		return
	var error: String = _phase.get_buy_error(_local_id, index)
	slot.set_caption("%d points" % CombatConfig.SHOP_CARD_COST, UiStyle.BUTTON_TEXT if error.is_empty() else UiStyle.TEXT_DIM)
	slot.set_taken(not error.is_empty())
	slot.set_interactive(error.is_empty())
	slot.tooltip_text = error


# --- Prêt -------------------------------------------------------------------

func _refresh_ready() -> void:
	var is_ready: bool = _phase.is_ready(_local_id)
	var missing: int = _phase.get_keep_count(_local_id) - _kept_indices.size()
	_ready_button.disabled = is_ready or _is_sending_ready or missing > 0
	if is_ready:
		_ready_button.text = "Prêt ✓"
	elif missing > 0:
		_ready_button.text = "Garde encore %d carte%s" % [missing, "s" if missing > 1 else ""]
	else:
		_ready_button.text = "Prêt !"
	if is_ready:
		_ready_status_label.text = "En attente des autres joueurs…"
	_ready_status_label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)


# --- Draft du podium --------------------------------------------------------

func _refresh_draft_section() -> void:
	if not _is_on_podium():
		return
	var picker_id: int = _phase.draft.current_picker_id()
	_rebuild_draft_row(picker_id)
	_draft_status_label.text = _describe_draft_status(picker_id)
	_draft_status_label.add_theme_color_override("font_color", YOUR_TURN_COLOR if picker_id == _local_id else UiStyle.TEXT_DIM)


func _rebuild_draft_row(picker_id: int) -> void:
	for child: Node in _draft_row.get_children():
		_draft_row.remove_child(child)
		child.queue_free()
	if _is_waiting_for_turn():
		_draft_row.add_child(_create_waiting_label())
		return
	for card: CardData in _visible_draft_cards():
		var slot: RewardCardSlot = _add_slot(_draft_row, card)
		slot.pressed.connect(MatchService.draft_podium_card)
		_refresh_draft_slot(slot, picker_id)


## Tant qu'un joueur mieux classé choisit, on ne montre rien : voir les cartes disparaître
## révélerait son choix.
func _is_waiting_for_turn() -> bool:
	return _current_picker_index() < _my_pick_index()


## Pendant son tour : les cartes restantes. Après : seulement la sienne (voir les autres disparaître,
## ou celle qui reste au dernier, révélerait le choix des suivants).
func _visible_draft_cards() -> Array[CardData]:
	var visible: Array[CardData] = []
	var has_picked: bool = _current_picker_index() > _my_pick_index()
	for card: CardData in _phase.draft.get_offer():
		var taker_id: int = _phase.draft.taker_of(card)
		if taker_id == _local_id or (not has_picked and taker_id == -1):
			visible.append(card)
	return visible


func _my_pick_index() -> int:
	return _phase.draft.get_pick_order().find(_local_id)


## Position du joueur qui choisit dans l'ordre du draft (taille de l'ordre si c'est fini).
func _current_picker_index() -> int:
	var picker_id: int = _phase.draft.current_picker_id()
	var order: Array[int] = _phase.draft.get_pick_order()
	return order.size() if picker_id == -1 else order.find(picker_id)


func _create_waiting_label() -> Label:
	var label := Label.new()
	label.text = "Les joueurs mieux classés choisissent d'abord.\nTes cartes s'afficheront à ton tour."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 150.0
	label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	label.add_theme_font_size_override("font_size", 16)
	return label


func _refresh_draft_slot(slot: RewardCardSlot, picker_id: int) -> void:
	var taker_id: int = _phase.draft.taker_of(slot.get_card())
	var is_taken: bool = taker_id != -1
	slot.set_taken(is_taken)
	slot.set_interactive(not is_taken and picker_id == _local_id)
	slot.set_caption(_describe_taker(taker_id), YOUR_TURN_COLOR if taker_id == _local_id else UiStyle.TEXT_DIM)


func _describe_draft_status(picker_id: int) -> String:
	if picker_id == -1:
		return "Cartes attribuées"
	if picker_id == _local_id:
		return "À toi de choisir !"
	return "%s (%s) choisit…" % [_player_name(picker_id), _rank_label(picker_id)]


func _describe_taker(taker_id: int) -> String:
	if taker_id == -1:
		return ""
	return "%s (%s)" % ["Toi" if taker_id == _local_id else _player_name(taker_id), _rank_label(taker_id)]


func _rank_label(player_id: int) -> String:
	var index: int = _phase.draft.get_pick_order().find(player_id)
	return RANK_LABELS[index] if index >= 0 and index < RANK_LABELS.size() else "#%d" % (index + 1)


func _player_name(player_id: int) -> String:
	return _phase.get_player(player_id).display_name


# --- Réactions --------------------------------------------------------------

func _on_deck_slot_pressed(_card: CardData, index: int) -> void:
	_toggle_kept(index)
	_refresh_deck_choice()
	_refresh_ready()


func _on_shop_slot_pressed(_card: CardData, index: int) -> void:
	MatchService.buy_shop_card(index)


## Envoi asynchrone : confirmé par player_ready, refusé par MatchService.action_failed.
func _on_ready_pressed() -> void:
	_is_sending_ready = true
	_refresh_ready()
	_refresh_deck_choice()
	MatchService.set_rewards_ready(_kept_indices)


func _on_shop_changed(player_id: int) -> void:
	if player_id == _local_id:
		_refresh_shop()


func _on_player_ready(player_id: int) -> void:
	if player_id == _local_id:
		_is_sending_ready = false
		_refresh_shop()
		_refresh_deck_choice()
		_refresh_ready()


func _on_action_failed(message: String) -> void:
	_is_sending_ready = false
	_refresh_deck_choice()
	_refresh_ready()
	_ready_status_label.text = message
