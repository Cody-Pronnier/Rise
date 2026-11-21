class_name CombatRound
extends RefCounted
## Une manche : un terrain par joueur, simulés en parallèle.
## Elle se termine quand tous les joueurs sauf un ont tué leurs 3 monstres.
## Logique pure : c'est MatchService qui appelle tick(). Plus tard, seul l'hôte la simulera.

signal player_finished(player_id: int, rank: int)
signal card_played(caster_id: int, card: CardData, target: CardTarget)
signal ability_used(player_id: int)
signal preparation_finished
signal round_finished(results: Array[RoundResult])

var round_index: int
## Famille de monstres de la manche (la même sur tous les terrains).
var monster_family: MonsterRoster.Family
var players: Dictionary[int, PlayerState] = {}
var fields: Dictionary[int, Field] = {}
var is_over: bool = false
var alliances := AllianceRegistry.new()
var trades: TradeDesk
## Secondes restantes avant le début des combats (0 = les combats ont commencé).
var preparation_left: float = 0.0

var _finish_order: Array[int] = []


func _init(p_round_index: int, p_players: Array[PlayerState]) -> void:
	round_index = p_round_index
	monster_family = MonsterRoster.pick_family()
	preparation_left = _preparation_duration()
	for player: PlayerState in p_players:
		_register_player(player)
	trades = TradeDesk.new(players, fields, alliances)


func tick(delta: float) -> void:
	if is_over:
		return
	trades.tick(delta)
	if is_preparing():
		_tick_preparation(delta)
		return
	var combat_delta: float = delta * CombatConfig.GAME_SPEED
	for player: PlayerState in players.values():
		player.tick(combat_delta)
	for field: Field in fields.values():
		field.tick(combat_delta)
		if is_over:
			return


## Pendant la préparation, les terrains sont figés : seules les alliances et les échanges sont possibles.
func is_preparing() -> bool:
	return preparation_left > 0.0


## Renvoie "" si la carte a été jouée, sinon la raison du refus.
func play_card(caster_id: int, card: CardData, target: CardTarget) -> String:
	var error: String = CardPlayService.get_play_error(self, caster_id, card, target)
	if not error.is_empty():
		return error
	CardPlayService.resolve(self, caster_id, card, target)
	trades.cancel_offers_using_card(caster_id, card)
	card_played.emit(caster_id, card, target)
	return ""


## Capacité active de la classe du joueur, sur son propre terrain.
## Renvoie "" si elle a été utilisée, sinon la raison du refus.
func use_ability(player_id: int) -> String:
	var field: Field = fields.get(player_id)
	if is_over or field == null:
		return "La manche est terminée."
	if is_preparing():
		return "Les combats n'ont pas encore commencé."
	if field.is_finished():
		return "Tu as déjà terminé ta manche."
	var error: String = field.passive.get_ability_error()
	if not error.is_empty():
		return error
	field.passive.use_ability()
	ability_used.emit(player_id)
	return ""


## Rompt l'alliance du joueur : il donne ALLIANCE_BREAK_COST points à son allié.
## Renvoie "" si c'est fait, sinon la raison du refus.
func break_alliance(player_id: int) -> String:
	if is_over:
		return "La manche est terminée."
	var ally_id: int = alliances.ally_of(player_id)
	if ally_id == -1:
		return "Tu n'as pas d'alliance."
	players[player_id].add_points(-CombatConfig.ALLIANCE_BREAK_COST)
	players[ally_id].add_points(CombatConfig.ALLIANCE_BREAK_COST)
	alliances.break_alliance(player_id)
	return ""


func get_rank(player_id: int) -> int:
	return _finish_order.find(player_id) + 1


## Les joueurs dans leur ordre d'arrivée, limités aux `count` premiers.
func get_top_finishers(count: int) -> Array[int]:
	return _finish_order.slice(0, count)


func _preparation_duration() -> float:
	if round_index > 0 and not CombatConfig.PREPARATION_EVERY_ROUND:
		return 0.0
	return CombatConfig.PREPARATION_DURATION


func _tick_preparation(delta: float) -> void:
	preparation_left = maxf(preparation_left - delta, 0.0)
	if not is_preparing():
		preparation_finished.emit()


func _register_player(player: PlayerState) -> void:
	players[player.id] = player
	player.deal_deck()
	var field := Field.new(player.id, player.class_data.character, MonsterRoster.build_for_round(round_index, monster_family), player.class_data.create_passive())
	field.finished.connect(_on_field_finished.bind(player.id))
	fields[player.id] = field


func _required_finishers() -> int:
	return maxi(players.size() - 1, 1)


func _on_field_finished(player_id: int) -> void:
	_finish_order.append(player_id)
	trades.cancel_offers_to(player_id, "Ce joueur a terminé ses combats.")
	player_finished.emit(player_id, _finish_order.size())
	if _finish_order.size() >= _required_finishers():
		_end_round()


func _end_round() -> void:
	is_over = true
	trades.cancel_all("La manche est terminée.")
	var results: Array[RoundResult] = RoundScoring.compute(players.keys(), _finish_order)
	alliances.share_points(results)
	_award_points(results)
	round_finished.emit(results)


func _award_points(results: Array[RoundResult]) -> void:
	for result: RoundResult in results:
		players[result.player_id].add_points(result.points)
