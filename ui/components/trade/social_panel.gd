class_name SocialPanel
extends Control
## Chef d'orchestre « social » du combat, sans interface propre :
## - le clic droit sur un onglet ouvre le menu d'actions (PlayerActionMenu) :
##   sur un autre joueur → voir son terrain, échanger, alliance, rompre, annuler son offre ;
##   sur soi → voir son terrain, afficher ou masquer le classement en direct ;
## - les offres reçues apparaissent en tuiles (TradeInbox), un clic ouvre leur détail (TradeOfferPopup) ;
## - les nouvelles (offre envoyée, échange conclu, alliance rompue…) passent par message_requested.
## Il relie ces composants à MatchService ; l'écran lui fournit seulement le contexte.

signal message_requested(text: String)
signal alliances_changed
## « Voir son terrain » choisi dans le menu d'un joueur.
signal view_requested(player_id: int)
## « Classement en direct » choisi dans son propre menu.
signal standings_toggle_requested

var _round: CombatRound
var _local_player: PlayerState
var _trade_dialog: TradeDialog
var _offer_popup: TradeOfferPopup
var _inbox: TradeInbox
var _action_menu := PlayerActionMenu.new()


func setup(combat_round: CombatRound, local_player: PlayerState, trade_dialog: TradeDialog, offer_popup: TradeOfferPopup, inbox: TradeInbox) -> void:
	_round = combat_round
	_local_player = local_player
	_trade_dialog = trade_dialog
	_offer_popup = offer_popup
	_inbox = inbox
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_action_menu)
	_connect_ui()
	_connect_round()


## Menu d'actions à la position de la souris (clic droit sur l'onglet du joueur).
func open_player_menu(player_id: int) -> void:
	if _round.is_over:
		return
	if player_id == _local_player.id:
		_fill_own_menu()
	else:
		_fill_player_menu(player_id)
	_action_menu.show_at(get_global_mouse_position())


## Fin de manche : on ferme tout ce qui est en cours.
func close_all() -> void:
	_trade_dialog.hide()
	_offer_popup.close()
	_action_menu.hide()
	_inbox.clear()


# --- Mise en place ----------------------------------------------------------

func _connect_ui() -> void:
	_action_menu.action_chosen.connect(_on_action_chosen)
	_trade_dialog.submitted.connect(_on_trade_submitted)
	_offer_popup.accept_pressed.connect(MatchService.accept_trade)
	_offer_popup.decline_pressed.connect(MatchService.decline_trade)
	_inbox.offer_selected.connect(_on_inbox_offer_selected)


func _connect_round() -> void:
	_round.trades.offer_proposed.connect(_on_offer_proposed)
	_round.trades.offer_resolved.connect(_on_offer_resolved)
	_round.alliances.alliance_formed.connect(alliances_changed.emit.unbind(2))
	_round.alliances.alliance_broken.connect(_on_alliance_broken)


# --- Contenu des menus ------------------------------------------------------

func _fill_own_menu() -> void:
	_action_menu.begin(_local_player.id, "Toi")
	_action_menu.add_action(PlayerActionMenu.Action.VIEW_FIELD, "Voir mon terrain")
	_action_menu.add_action(PlayerActionMenu.Action.STANDINGS, "Classement en direct (Tab)")


func _fill_player_menu(player_id: int) -> void:
	_action_menu.begin(player_id, _player_name(player_id))
	_action_menu.add_action(PlayerActionMenu.Action.VIEW_FIELD, "Voir son terrain")
	_action_menu.add_action(PlayerActionMenu.Action.TRADE, "Proposer un échange…", _trade_error(player_id))
	_add_alliance_action(player_id)
	_add_cancel_action(player_id)


func _add_alliance_action(player_id: int) -> void:
	if _round.alliances.are_allied(_local_player.id, player_id):
		_action_menu.add_action(PlayerActionMenu.Action.BREAK_ALLIANCE, "Rompre l'alliance (-%d pts)" % CombatConfig.ALLIANCE_BREAK_COST)
		return
	var error: String = _trade_error(player_id)
	if error.is_empty():
		error = _alliance_block_reason(player_id)
	_action_menu.add_action(PlayerActionMenu.Action.ALLIANCE, "Proposer une alliance", error)


## Raison courte pour laquelle on ne peut pas s'allier à ce joueur ("" si c'est possible).
## Une alliance rompue reste grisée jusqu'à la fin de la manche.
func _alliance_block_reason(player_id: int) -> String:
	var alliances: AllianceRegistry = _round.alliances
	var my_ally: int = alliances.ally_of(_local_player.id)
	if my_ally != -1:
		return "allié avec %s" % _short_name(my_ally)
	if alliances.had_alliance(_local_player.id):
		return "alliance rompue"
	var their_ally: int = alliances.ally_of(player_id)
	if their_ally != -1:
		return "allié avec %s" % _short_name(their_ally)
	if alliances.had_alliance(player_id):
		return "alliance déjà utilisée"
	return ""


## Nom sans la classe entre parenthèses (« Bot 4 » plutôt que « Bot 4 (Archer) »).
func _short_name(player_id: int) -> String:
	var player: PlayerState = _round.players[player_id]
	return player.display_name.trim_suffix(" (%s)" % player.class_data.display_name)


func _add_cancel_action(player_id: int) -> void:
	var offer: TradeOffer = _round.trades.outgoing_offer_of(_local_player.id)
	if offer and offer.to_id == player_id:
		_action_menu.add_action(PlayerActionMenu.Action.CANCEL_OFFER, _describe_cancel(offer))


func _describe_cancel(offer: TradeOffer) -> String:
	var is_alliance_only: bool = offer.proposes_alliance and offer.given_cards.is_empty() and offer.requested_cards.is_empty() \
		and offer.given_points == 0 and offer.requested_points == 0
	return "Annuler ma demande d'alliance" if is_alliance_only else "Annuler mon offre"


## "" si on peut faire une offre à ce joueur, sinon la raison courte affichée dans le menu.
func _trade_error(player_id: int) -> String:
	if _round.fields[player_id].is_finished():
		return "a terminé"
	if _round.trades.outgoing_offer_of(_local_player.id):
		return "offre déjà en attente"
	return ""


# --- Textes -----------------------------------------------------------------

func _player_name(player_id: int) -> String:
	return _round.players[player_id].display_name


func _other_party(offer: TradeOffer) -> int:
	return offer.to_id if offer.from_id == _local_player.id else offer.from_id


func _describe_resolution(offer: TradeOffer, accepted: bool, reason: String) -> String:
	var other_name: String = _player_name(_other_party(offer))
	if not accepted:
		return "%s (%s)" % [reason, other_name]
	if offer.proposes_alliance:
		return "Échange conclu : tu es maintenant allié avec %s !" % other_name
	return "Échange conclu avec %s." % other_name


# --- Réactions --------------------------------------------------------------

func _on_action_chosen(action: PlayerActionMenu.Action, player_id: int) -> void:
	match action:
		PlayerActionMenu.Action.VIEW_FIELD:
			view_requested.emit(player_id)
		PlayerActionMenu.Action.STANDINGS:
			standings_toggle_requested.emit()
		PlayerActionMenu.Action.TRADE:
			_open_trade_dialog(player_id)
		PlayerActionMenu.Action.ALLIANCE:
			_propose_alliance(player_id)
		PlayerActionMenu.Action.BREAK_ALLIANCE:
			MatchService.break_alliance()
		PlayerActionMenu.Action.CANCEL_OFFER:
			_cancel_outgoing_offer()


## Alliance seule, envoyée tout de suite : l'autre joueur la reçoit en notification.
func _propose_alliance(player_id: int) -> void:
	var offer := TradeOffer.new()
	offer.from_id = _local_player.id
	offer.to_id = player_id
	offer.proposes_alliance = true
	MatchService.propose_trade(offer)


func _open_trade_dialog(player_id: int) -> void:
	var target: PlayerState = _round.players[player_id]
	_trade_dialog.open(_local_player, target, _round.alliances.get_formation_error(_local_player.id, target.id))


func _cancel_outgoing_offer() -> void:
	var offer: TradeOffer = _round.trades.outgoing_offer_of(_local_player.id)
	if offer:
		MatchService.cancel_trade(offer.id)


## Envoi asynchrone : la confirmation arrive par offer_proposed, un refus par MatchService.action_failed.
func _on_trade_submitted(offer: TradeOffer) -> void:
	if offer.is_empty():
		_trade_dialog.show_error("L'offre est vide.")
		return
	MatchService.propose_trade(offer)
	_trade_dialog.hide()


func _on_offer_proposed(offer: TradeOffer) -> void:
	if offer.to_id == _local_player.id:
		_inbox.add_offer(offer, _round.players[offer.from_id])
	elif offer.from_id == _local_player.id:
		message_requested.emit("Offre envoyée à %s. Clic droit sur son onglet pour l'annuler." % _player_name(offer.to_id))


func _on_offer_resolved(offer: TradeOffer, accepted: bool, reason: String) -> void:
	_inbox.remove_offer(offer.id)
	_offer_popup.close_if_showing(offer.id)
	if offer.involves(_local_player.id) and not _round.is_over:
		message_requested.emit(_describe_resolution(offer, accepted, reason))


func _on_inbox_offer_selected(offer: TradeOffer) -> void:
	_offer_popup.show_offer(offer, _round.players[offer.from_id])


func _on_alliance_broken(breaker_id: int, ally_id: int) -> void:
	if breaker_id == _local_player.id:
		message_requested.emit("Alliance rompue : %d points donnés à %s." % [CombatConfig.ALLIANCE_BREAK_COST, _player_name(ally_id)])
	elif ally_id == _local_player.id:
		message_requested.emit("%s a rompu votre alliance et te donne %d points." % [_player_name(breaker_id), CombatConfig.ALLIANCE_BREAK_COST])
	alliances_changed.emit()
