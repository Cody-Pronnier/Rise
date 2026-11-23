class_name MatchRecorder
extends RefCounted
## Observe une partie simulée et note ce qu'il faut pour l'équilibrage :
## - par joueur et par manche : place, points, temps pour finir, cartes jouées, mana dépensé et perdu, morts ;
## - par manche : famille de monstres, durée, écart entre le premier et le dernier ;
## - par joueur en fin de partie : points, place finale, part de victoire (partagée en cas d'égalité).
## Les temps sont en secondes réelles de combat (sans la préparation).

## Où une carte a été jouée : son terrain ou celui d'un adversaire, et sur quel camp.
const TARGET_KINDS: Array[String] = ["mon_monstre", "mon_camp", "mon_terrain", "monstre_adverse", "camp_adverse", "joueur_adverse"]

## Lignes prêtes pour les CSV.
var player_rows: Array[Dictionary] = []
var round_player_rows: Array[Dictionary] = []
var round_rows: Array[Dictionary] = []
## id de carte → nombre de fois jouée.
var card_plays: Dictionary[StringName, int] = {}
## id de carte → ids des joueurs qui l'ont jouée au moins une fois.
var card_players: Dictionary[StringName, Dictionary] = {}
## id de carte → { type de cible → nombre de fois } (voir TARGET_KINDS).
var card_targets: Dictionary[StringName, Dictionary] = {}
## player_id → { id de carte → exemplaires } : le deck de 16 cartes choisi en début de partie.
var player_decks: Dictionary[int, Dictionary] = {}

var _session: MatchSession
var _round: CombatRound
var _combat_time: float = 0.0
var _first_finish_time: float = -1.0
## player_id → { cards, mana_spent, mana_wasted, deaths, finish_time }
var _stats: Dictionary[int, Dictionary] = {}


func _init(session: MatchSession) -> void:
	_session = session
	_session.round_started.connect(_on_round_started)
	_session.match_finished.connect(_on_match_finished)


## À appeler à chaque pas de simulation, après session.step().
func step(delta: float) -> void:
	if _round == null or _round.is_over or _round.is_preparing():
		return
	_combat_time += delta
	_track_wasted_mana(delta)


## Mana perdu : le mana qui se serait rechargé pendant que la jauge était pleine.
func _track_wasted_mana(delta: float) -> void:
	var regen: float = CombatConfig.MANA_PER_SECOND * delta * CombatConfig.GAME_SPEED
	for player: PlayerState in _session.players:
		if player.mana >= CombatConfig.MANA_MAX - 0.001 and not _round.fields[player.id].is_finished():
			_stats[player.id]["mana_wasted"] += regen


# --- Manche -----------------------------------------------------------------

func _on_round_started(_round_index: int) -> void:
	_round = _session.current_round
	_combat_time = 0.0
	_first_finish_time = -1.0
	_stats.clear()
	if player_decks.is_empty():
		_record_decks()
	for player: PlayerState in _session.players:
		_stats[player.id] = { "cards": 0, "mana_spent": 0, "mana_wasted": 0.0, "deaths": 0, "finish_time": -1.0 }
		_round.fields[player.id].character.died.connect(_on_character_died.bind(player.id))
	_round.card_played.connect(_on_card_played)
	_round.player_finished.connect(_on_player_finished)
	_round.round_finished.connect(_on_round_finished)


## Au début de la partie, le deck complet = cartes débloquées + cartes encore à débloquer.
func _record_decks() -> void:
	for player: PlayerState in _session.players:
		var counts: Dictionary = {}
		for card: CardData in player.deck + player.locked_cards:
			counts[card.id] = counts.get(card.id, 0) + 1
		player_decks[player.id] = counts


func _on_card_played(caster_id: int, card: CardData, target: CardTarget) -> void:
	var kinds: Dictionary = card_targets.get_or_add(card.id, {})
	var kind: String = _target_kind(caster_id, target)
	kinds[kind] = kinds.get(kind, 0) + 1
	_stats[caster_id]["cards"] += 1
	_stats[caster_id]["mana_spent"] += card.cost
	card_plays[card.id] = card_plays.get(card.id, 0) + 1
	if not card_players.has(card.id):
		card_players[card.id] = {}
	card_players[card.id][caster_id] = true


## mon_monstre / mon_camp (personnage, compagnons) / mon_terrain (carte sans unité ciblée),
## puis la même chose chez un adversaire.
func _target_kind(caster_id: int, target: CardTarget) -> String:
	var own: bool = target.player_id == caster_id
	if target.unit == null:
		return "mon_terrain" if own else "joueur_adverse"
	if target.unit.side == CombatUnit.Side.MONSTER:
		return "mon_monstre" if own else "monstre_adverse"
	return "mon_camp" if own else "camp_adverse"


func _on_character_died(player_id: int) -> void:
	_stats[player_id]["deaths"] += 1


func _on_player_finished(player_id: int, _rank: int) -> void:
	_stats[player_id]["finish_time"] = _combat_time
	if _first_finish_time < 0.0:
		_first_finish_time = _combat_time


func _on_round_finished(results: Array[RoundResult]) -> void:
	for result: RoundResult in results:
		round_player_rows.append(_round_player_row(result))
	round_rows.append({
		"round": _round.round_index + 1,
		"family": MonsterRoster.family_name(_round.monster_family),
		"monsters": _round.fields.values()[0].total_monsters,
		"duration": _combat_time,
		"first_finish": _first_finish_time,
		"gap": _combat_time - maxf(_first_finish_time, 0.0),
	})


func _round_player_row(result: RoundResult) -> Dictionary:
	var stats: Dictionary = _stats[result.player_id]
	var finish_time: float = stats["finish_time"] if stats["finish_time"] >= 0.0 else _combat_time
	return {
		"round": _round.round_index + 1,
		"player": result.player_id,
		"class": _class_of(result.player_id),
		"rank": result.rank,
		"points": result.points,
		"finished": result.has_finished,
		"finish_time": finish_time,
		"cards": stats["cards"],
		"mana_spent": stats["mana_spent"],
		"mana_wasted": stats["mana_wasted"],
		"deaths": stats["deaths"],
		"allied": result.ally_id != -1,
	}


# --- Fin de partie ----------------------------------------------------------

## Place finale d'après les points ; les ex æquo partagent la victoire.
func _on_match_finished() -> void:
	var best_points: int = _best_points()
	var winners: int = _session.players.filter(func(player: PlayerState) -> bool: return player.points == best_points).size()
	for player: PlayerState in _session.players:
		player_rows.append({
			"player": player.id,
			"class": player.class_data.id,
			"points": player.points,
			"rank": _final_rank(player),
			"win_share": 1.0 / winners if player.points == best_points else 0.0,
		})


func _best_points() -> int:
	var best: int = -1000000
	for player: PlayerState in _session.players:
		best = maxi(best, player.points)
	return best


## 1 + nombre de joueurs qui ont strictement plus de points.
func _final_rank(player: PlayerState) -> int:
	return 1 + _session.players.filter(func(other: PlayerState) -> bool: return other.points > player.points).size()


func _class_of(player_id: int) -> StringName:
	var player: PlayerState = _session.get_player(player_id)
	return player.class_data.id if player else &""
