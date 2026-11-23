class_name BotPlayer
extends RefCounted
## IA d'un bot, en deux styles :
## - SIMPLE : joue une carte au hasard de temps en temps ;
## - SMART : réfléchit vite, garde son mana pour son ultime, étale sa main sur la manche et joue
##   la carte qui rapporte le plus sur la meilleure cible (voir BotCardScorer et BotTargets) :
##   combos, marque, défense quand il est en danger, gêne des adversaires proches de finir…
## Ne tourne que chez l'hôte : il ne modifie rien lui-même, il soumet des commandes.

enum Style { SIMPLE, SMART }

const MIN_CARD_DELAY: float = 10.0
const MAX_CARD_DELAY: float = 20.0
const SELF_MONSTER_CHANCE: float = 0.5
## Délai entre deux essais de la capacité de classe (ex : recruter un mercenaire dès qu'il y a l'or).
const ABILITY_CHECK_INTERVAL: float = 1.5
## Chance de viser un adversaire mieux classé (bonus de rattrapage) plutôt qu'un adversaire au hasard.
const AIM_AHEAD_CHANCE: float = 0.7

## Bot malin : temps de réflexion entre deux cartes, et nouvel essai quand rien ne vaut le coup.
const SMART_MIN_DELAY: float = 1.5
const SMART_MAX_DELAY: float = 3.5
const SMART_RETRY_DELAY: float = 1.0
## Une carte doit rapporter au moins ça par point de mana… sauf si le mana est presque plein.
const SMART_MIN_VALUE_PER_MANA: float = 3.0
const SMART_NEAR_FULL_MANA: float = 1.0
## Un peu de hasard pour que deux bots identiques ne jouent pas exactement pareil.
const SMART_NOISE: float = 0.15
## Rythme : part de la main autorisée en plus de l'avancement (0.34 = un tiers d'avance).
const SMART_PACING_MARGIN: float = 0.34
## Gêner un adversaire sur le point de finir vaut jusqu'à (1 + ce poids) fois plus.
const SMART_THREAT_WEIGHT: float = 1.0

var style: Style = Style.SIMPLE

var _player: PlayerState
var _round: CombatRound
var _submit: Callable
var _delay: float = 0.0
var _ability_delay: float = ABILITY_CHECK_INTERVAL
## Taille de la main en début de manche et cartes jouées depuis (pour étaler sa main).
var _starting_hand_size: int = 0
var _cards_played: int = 0


## submit : reçoit chaque commande produite par le bot.
func _init(p_player: PlayerState, p_round: CombatRound, submit: Callable, p_style: Style = Style.SIMPLE) -> void:
	_player = p_player
	_round = p_round
	_submit = submit
	style = p_style
	_starting_hand_size = p_player.hand.size()
	_schedule_next_card()


func tick(delta: float) -> void:
	if _round.is_over or _round.is_preparing():
		return
	_tick_ability(delta)
	if _player.hand.is_empty():
		return
	_delay -= delta
	if _delay > 0.0:
		return
	if style == Style.SMART:
		_play_smart()
	else:
		_play_simple()


func _tick_ability(delta: float) -> void:
	_ability_delay -= delta
	if _ability_delay > 0.0:
		return
	_ability_delay = ABILITY_CHECK_INTERVAL
	var passive: ClassPassive = _round.fields[_player.id].passive
	if passive.has_ability() and passive.get_ability_error().is_empty():
		_submit.call(MatchCommands.use_ability(_player.id))


func _schedule_next_card() -> void:
	if style == Style.SMART:
		_delay = randf_range(SMART_MIN_DELAY, SMART_MAX_DELAY)
	else:
		_delay = randf_range(MIN_CARD_DELAY, MAX_CARD_DELAY)


func _submit_play(card: CardData, target: CardTarget) -> void:
	_submit.call(MatchCommands.play_card(_player.id, card, target, _round.fields[target.player_id]))


# --- Style simple -----------------------------------------------------------

func _play_simple() -> void:
	var card: CardData = _pick_affordable_card()
	if card == null:
		return
	_schedule_next_card()
	var target: CardTarget = _choose_target(card)
	if target:
		_submit_play(card, target)


## Une carte au hasard parmi celles que le bot peut payer (null s'il doit attendre son mana).
func _pick_affordable_card() -> CardData:
	var affordable: Array[CardData] = _player.hand.filter(_player.can_afford)
	return affordable.pick_random() if not affordable.is_empty() else null


func _choose_target(card: CardData) -> CardTarget:
	match card.target_mode:
		CardData.TargetMode.SELF, CardData.TargetMode.ALL_FIELDS:
			return CardTarget.for_player(_player.id)
		CardData.TargetMode.UNIT:
			return _choose_unit_target(card)
		_:
			return _choose_player_target(card)


func _choose_player_target(card: CardData) -> CardTarget:
	if card.is_beneficial:
		return CardTarget.for_player(_player.id)
	var opponent_id: int = _pick_opponent_id()
	return CardTarget.for_player(opponent_id) if opponent_id != -1 else null


func _choose_unit_target(card: CardData) -> CardTarget:
	var own_field: Field = _round.fields[_player.id]
	if card.is_beneficial:
		return CardTarget.for_unit(_player.id, _pick_own_ally(own_field))
	if own_field.current_monster and randf() < SELF_MONSTER_CHANCE:
		return CardTarget.for_unit(_player.id, own_field.current_monster)
	var opponent_id: int = _pick_opponent_id()
	return BotTargets.opponent_unit(_round, opponent_id) if opponent_id != -1 else null


## Un compagnon s'il y en a (mercenaire, invocations), sinon le personnage.
func _pick_own_ally(own_field: Field) -> CombatUnit:
	var living: Array[CombatUnit] = []
	living.assign(own_field.companions.filter(func(unit: CombatUnit) -> bool: return unit.is_alive()))
	return living.pick_random() if not living.is_empty() else own_field.character


## Le plus souvent un adversaire devant soi dans la manche (les cartes offensives y sont plus fortes).
func _pick_opponent_id() -> int:
	var candidates: Array[int] = []
	var ahead: Array[int] = []
	for player_id: int in _round.fields:
		if BotTargets.is_targetable_opponent(_round, _player.id, player_id):
			candidates.append(player_id)
			if CatchUpBoost.places_ahead(_round, _player.id, player_id) > 0:
				ahead.append(player_id)
	if not ahead.is_empty() and randf() < AIM_AHEAD_CHANCE:
		return ahead.pick_random()
	return candidates.pick_random() if not candidates.is_empty() else -1


# --- Style malin ------------------------------------------------------------

## Joue le meilleur couple (carte, cible) s'il vaut le coup, sinon réessaie un peu plus tard.
func _play_smart() -> void:
	var best_card: CardData = null
	var best_target: CardTarget = null
	var best_score: float = 0.0
	var candidates: Array[CardData] = _smart_candidates()
	if candidates.is_empty():
		_delay = SMART_RETRY_DELAY
		return
	var opponents: Array[int] = BotTargets.threatening_opponents(_round, _player.id)
	for card: CardData in candidates:
		for target: CardTarget in BotTargets.for_card(card, _round, _player.id, opponents):
			var score: float = _smart_score(card, target)
			if score > best_score:
				best_score = score
				best_card = card
				best_target = target
	if best_card == null or not _is_worth_playing(best_card, best_score):
		_delay = SMART_RETRY_DELAY
		return
	_schedule_next_card()
	_cards_played += 1
	_submit_play(best_card, best_target)


## Cartes payables, en respectant deux règles (sauf si le mana va déborder) :
## - tant que l'ultime n'est pas payable, le bot garde son mana pour elle ;
## - il étale sa main sur la manche au lieu de tout jouer sur le premier monstre.
func _smart_candidates() -> Array[CardData]:
	var none: Array[CardData] = []
	var affordable: Array[CardData] = _player.hand.filter(_player.can_afford)
	if _is_mana_nearly_full():
		return affordable
	var ultimate: CardData = _ultimate_in_hand()
	if ultimate and not _player.can_afford(ultimate):
		return none
	if _cards_played >= _cards_allowed_now():
		return none
	return affordable


## Nombre de cartes que le bot s'autorise à avoir jouées à ce stade de la manche.
func _cards_allowed_now() -> int:
	var progress: float = BotTargets.progress_ratio(_round, _player.id)
	return ceili(_starting_hand_size * minf(progress + SMART_PACING_MARGIN, 1.0))


func _ultimate_in_hand() -> CardData:
	for card: CardData in _player.hand:
		if card.is_ultimate:
			return card
	return null


func _is_mana_nearly_full() -> bool:
	return _player.mana >= CombatConfig.MANA_MAX - SMART_NEAR_FULL_MANA


func _is_worth_playing(card: CardData, score: float) -> bool:
	return card.cost == 0 or score / card.cost >= SMART_MIN_VALUE_PER_MANA or _is_mana_nearly_full()


## Valeur de la carte sur la cible, renforcée par le bonus de rattrapage, avec un peu de hasard.
## Gêner un adversaire vaut d'autant plus qu'il est proche de finir sa manche.
## Une cible refusée par les règles vaut 0.
func _smart_score(card: CardData, target: CardTarget) -> float:
	if not CardPlayService.get_play_error(_round, _player.id, card, target).is_empty():
		return 0.0
	var power: float = 1.0 + CatchUpBoost.bonus_for(_round, _player.id, card, target)
	var value: float = BotCardScorer.score(card, target, _round, _player) * power
	if target.player_id != _player.id:
		value *= 1.0 + BotTargets.progress_ratio(_round, target.player_id) * SMART_THREAT_WEIGHT
	return value * randf_range(1.0 - SMART_NOISE, 1.0 + SMART_NOISE)
