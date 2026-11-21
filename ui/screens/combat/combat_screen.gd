extends Screen
## Écran de manche : onglets des terrains en haut, terrain observé au centre, main de cartes en bas.
## Relie les composants entre eux et transmet les cartes jouées à MatchService.
## Les actions sont asynchrones : la réussite arrive par card_played, un refus par action_failed.

const MESSAGE_DURATION: float = 2.5
const BOOST_REFRESH_INTERVAL: float = 0.5
## Raccourcis des onglets de terrain : la rangée de chiffres, par position physique
## (& é " ' ( - è _ sur un clavier AZERTY, 1 à 8 sur un QWERTY).
const FIELD_SHORTCUTS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]

@onready var _tab_bar: FieldTabBar = %FieldTabBar
@onready var _arena: ArenaView = %ArenaView
@onready var _hand: HandView = %HandView
@onready var _message_label: Label = %MessageLabel
@onready var _lock_label: Label = %CardLockLabel
@onready var _result_panel: RoundResultPanel = %RoundResultPanel
@onready var _message_timer: Timer = %MessageTimer
@onready var _targeting_arrow: TargetingArrow = %TargetingArrow
@onready var _social_panel: SocialPanel = %SocialPanel
@onready var _trade_dialog: TradeDialog = %TradeDialog
@onready var _offer_popup: TradeOfferPopup = %TradeOfferPopup
@onready var _trade_inbox: TradeInbox = %TradeInbox
@onready var _standings_panel: LiveStandingsPanel = %LiveStandingsPanel
@onready var _ability_panel: ClassAbilityPanel = %ClassAbilityPanel
@onready var _history_panel: HistoryPanel = %HistoryPanel
@onready var _game_menu: GameMenu = %GameMenu
@onready var _preparation_banner: PreparationBanner = %PreparationBanner
@onready var _mana_bar: ManaBar = %ManaBar

var _round: CombatRound
var _local_player: PlayerState
var _viewed_player_id: int
var _targeting := CardTargeting.new()
var _is_showing_final_results: bool = false
var _boost_refresh_left: float = 0.0
## La souris est sur le personnage du terrain affiché (le bonus ne s'affiche qu'en le visant).
var _is_hovering_character: bool = false


func _ready() -> void:
	_round = MatchService.current_round
	_local_player = MatchService.get_local_player()
	_connect_ui()
	_connect_match()
	_build_views()
	_view_field(_local_player.id)
	_show_message("Manche %d / %d · %s" % [MatchService.round_index + 1, CombatConfig.MAX_ROUNDS, MonsterRoster.family_name(_round.monster_family)])


## Le classement bouge en permanence : les valeurs renforcées des cartes sont rafraîchies régulièrement.
func _process(delta: float) -> void:
	_boost_refresh_left -= delta
	if _boost_refresh_left <= 0.0:
		_refresh_card_powers()


func _unhandled_input(event: InputEvent) -> void:
	var shortcut_index: int = _field_shortcut_index(event)
	if shortcut_index != -1:
		_on_field_shortcut(shortcut_index)
		get_viewport().set_input_as_handled()
		return
	if _is_standings_shortcut(event):
		_standings_panel.toggle()
		get_viewport().set_input_as_handled()
		return
	if _targeting.is_active() and UiInput.is_cancel(event):
		_cancel_targeting()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_game_menu.toggle()
		get_viewport().set_input_as_handled()


# --- Mise en place ----------------------------------------------------------

func _connect_ui() -> void:
	_tab_bar.field_selected.connect(_view_field)
	_arena.character_hover_changed.connect(_on_character_hover_changed)
	_tab_bar.player_menu_requested.connect(_social_panel.open_player_menu)
	_social_panel.view_requested.connect(_view_field)
	_arena.unit_clicked.connect(_on_unit_clicked)
	_arena.arena_clicked.connect(_on_arena_clicked)
	_hand.card_selected.connect(_on_card_selected)
	_game_menu.leave_confirmed.connect(MatchService.leave_match)
	_result_panel.continue_pressed.connect(_on_result_continue_pressed)
	_message_timer.timeout.connect(_message_label.hide)
	_social_panel.message_requested.connect(_show_message)
	_social_panel.alliances_changed.connect(_on_alliances_changed)
	_social_panel.standings_toggle_requested.connect(_standings_panel.toggle)


func _connect_match() -> void:
	MatchService.action_failed.connect(_show_message)
	MatchService.match_finished.connect(_on_match_finished)
	_round.card_played.connect(_on_card_played)
	_local_player.hand_changed.connect(_refresh_hand)
	_local_player.card_lock_changed.connect(_on_card_lock_changed)
	_local_player.mana_changed.connect(_hand.set_mana)
	_round.round_finished.connect(_on_round_finished)
	_round.preparation_finished.connect(_on_preparation_finished)


func _build_views() -> void:
	_tab_bar.build(_round, _local_player.id)
	_social_panel.setup(_round, _local_player, _trade_dialog, _offer_popup, _trade_inbox)
	_standings_panel.setup(_round, _local_player.id)
	_ability_panel.setup(_round.fields[_local_player.id].passive)
	_history_panel.setup(_round, _local_player.id)
	_preparation_banner.setup(_round)
	_mana_bar.setup(_local_player)
	_hand.set_mana(_local_player.mana)
	_result_panel.hide()
	_lock_label.text = ""
	_refresh_hand_lock()
	_message_label.hide()
	_refresh_hand()


# --- Affichage --------------------------------------------------------------

func _view_field(player_id: int) -> void:
	_viewed_player_id = player_id
	var is_own: bool = player_id == _local_player.id
	var is_ally: bool = _round.alliances.are_allied(_local_player.id, player_id)
	_arena.show_field(_round.fields[player_id], _field_title(_round.players[player_id], is_own, is_ally), is_own or is_ally)
	_arena.set_targeting(_targeting.expects_unit())
	_tab_bar.set_active(player_id)
	_refresh_card_powers()


func _field_title(player: PlayerState, is_own: bool, is_ally: bool) -> String:
	if is_own:
		return "Ton terrain"
	return "Terrain de %s%s" % [player.display_name, " (allié)" if is_ally else ""]


func _refresh_hand() -> void:
	_hand.display(_local_player.hand)
	_hand.set_selected(_targeting.card)


func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.show()
	_message_timer.start(MESSAGE_DURATION)


# --- Ciblage ----------------------------------------------------------------

func _begin_targeting(card: CardData) -> void:
	_targeting.begin(card)
	_hand.set_selected(card)
	_arena.set_targeting(_targeting.expects_unit())
	_targeting_arrow.start(_hand.get_card_anchor.bind(card))
	_show_message(_targeting.describe_hint())
	_refresh_card_powers()


func _cancel_targeting() -> void:
	_targeting.cancel()
	_hand.set_selected(null)
	_arena.set_targeting(false)
	_targeting_arrow.stop()
	_refresh_card_powers()


## Quand la souris est sur le personnage d'un adversaire mieux classé, les cartes offensives de la main
## affichent leurs valeurs renforcées (bonus de rattrapage), comme dans Slay the Spire.
## Les cartes qui visent un joueur (ex : Chaîne) les affichent dès qu'on regarde son terrain.
## Rien n'est affiché si sa progression est cachée (ça trahirait sa place).
func _refresh_card_powers() -> void:
	_boost_refresh_left = BOOST_REFRESH_INTERVAL
	_hand.apply_power(_card_power)


func _card_power(card: CardData) -> float:
	if _viewed_player_id == _local_player.id or _round.is_over:
		return 1.0
	var field: Field = _round.fields[_viewed_player_id]
	if field.hides_progress() and not _round.alliances.are_allied(_local_player.id, _viewed_player_id):
		return 1.0
	var target := CardTarget.for_player(_viewed_player_id)
	if card.target_mode == CardData.TargetMode.UNIT:
		if not _is_hovering_character:
			return 1.0
		target = CardTarget.for_unit(_viewed_player_id, field.character)
	return 1.0 + CatchUpBoost.bonus_for(_round, _local_player.id, card, target)


func _on_character_hover_changed(is_hovered: bool) -> void:
	_is_hovering_character = is_hovered
	_refresh_card_powers()


func _play_card(card: CardData, target: CardTarget) -> void:
	_cancel_targeting()
	MatchService.play_card(card, target)


# --- Réactions --------------------------------------------------------------

func _on_card_selected(card: CardData) -> void:
	if _targeting.is_selecting(card):
		_cancel_targeting()
	elif not _local_player.can_afford(card):
		_show_message("Pas assez de mana (%d / %d)." % [floori(_local_player.mana), card.cost])
	elif card.is_played_without_target():
		_play_card(card, CardTarget.for_player(_local_player.id))
	else:
		_begin_targeting(card)


func _on_unit_clicked(unit: CombatUnit) -> void:
	if _targeting.expects_unit():
		_play_card(_targeting.card, CardTarget.for_unit(_viewed_player_id, unit))


func _on_arena_clicked() -> void:
	if _targeting.expects_field():
		_play_card(_targeting.card, CardTarget.for_player(_viewed_player_id))


func _on_card_lock_changed(is_locked: bool) -> void:
	_refresh_hand_lock()
	_lock_label.text = "Cartes bloquées !" if is_locked else ""
	if is_locked:
		_cancel_targeting()


## Main grisée tant que les cartes sont bloquées ou que les combats n'ont pas commencé
## (on peut toujours survoler les cartes pour les lire).
func _refresh_hand_lock() -> void:
	_hand.set_locked(_local_player.is_card_locked() or _round.is_preparing())


func _on_preparation_finished() -> void:
	_refresh_hand_lock()
	_show_message("Que les combats commencent !")


## Les cartes ont un z_index (éventail) et passeraient devant le panneau de résultats : on les retire.
func _hide_round_controls() -> void:
	_hand.hide()
	_social_panel.hide()
	_standings_panel.hide()
	_ability_panel.hide()
	_mana_bar.hide()
	_history_panel.hide()
	_trade_inbox.hide()
	_lock_label.hide()


func _is_viewed_field_hit(caster_id: int, card: CardData, target: CardTarget) -> bool:
	if card.target_mode == CardData.TargetMode.ALL_FIELDS:
		return CardPlayService.affected_field_ids(_round, caster_id, card).has(_viewed_player_id)
	return target.player_id == _viewed_player_id


func _is_standings_shortcut(event: InputEvent) -> bool:
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo and key.keycode == KEY_TAB and not _round.is_over


## Position de l'onglet visé par la touche, -1 si ce n'est pas un raccourci de terrain.
func _field_shortcut_index(event: InputEvent) -> int:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _round.is_over:
		return -1
	return FIELD_SHORTCUTS.find(key.physical_keycode)


func _on_field_shortcut(index: int) -> void:
	var player_id: int = _tab_bar.player_id_at(index)
	if player_id != -1:
		_view_field(player_id)


func _on_alliances_changed() -> void:
	_view_field(_viewed_player_id)


func _on_round_finished(results: Array[RoundResult]) -> void:
	_cancel_targeting()
	_social_panel.close_all()
	_hide_round_controls()
	_result_panel.display_round(MatchService.round_index + 1, results, _round.players, _local_player.id, MatchService.has_authority(), MatchService.is_last_round())


## Après la dernière manche, on passe par le classement final avant de quitter.
## Hôte et entraînement : passe à la suite. Après le classement final : retour au menu.
func _on_result_continue_pressed() -> void:
	if _is_showing_final_results:
		MatchService.leave_match()
	else:
		MatchService.continue_after_round()


func _on_match_finished() -> void:
	_is_showing_final_results = true
	_result_panel.display_final(_round.players, _local_player.id)


## Effet visuel si la carte touche le terrain affiché, et confirmation pour nos propres cartes.
func _on_card_played(caster_id: int, card: CardData, target: CardTarget) -> void:
	if _is_viewed_field_hit(caster_id, card, target):
		_arena.play_card_effect(card, target)
	if caster_id == _local_player.id:
		_show_message("%s jouée." % card.display_name)
