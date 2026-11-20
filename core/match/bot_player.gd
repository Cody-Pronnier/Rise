class_name BotPlayer
extends RefCounted
## IA minimale d'un bot : joue une carte au hasard de temps en temps.
## Les cartes « bénéfiques » vont sur son personnage, les autres gênent un adversaire
## ou accélèrent son propre combat.
## Ne tourne que chez l'hôte : il ne modifie rien lui-même, il soumet des commandes.

const MIN_CARD_DELAY: float = 6.0
const MAX_CARD_DELAY: float = 14.0
const SELF_MONSTER_CHANCE: float = 0.5
## Délai entre deux essais de la capacité de classe (ex : recruter un mercenaire dès qu'il y a l'or).
const ABILITY_CHECK_INTERVAL: float = 1.5
## Chance de viser un adversaire mieux classé (bonus de rattrapage) plutôt qu'un adversaire au hasard.
const AIM_AHEAD_CHANCE: float = 0.7

var _player: PlayerState
var _round: CombatRound
var _submit: Callable
var _delay: float = 0.0
var _ability_delay: float = ABILITY_CHECK_INTERVAL


## submit : reçoit chaque commande produite par le bot.
func _init(p_player: PlayerState, p_round: CombatRound, submit: Callable) -> void:
	_player = p_player
	_round = p_round
	_submit = submit
	_schedule_next_card()


func tick(delta: float) -> void:
	if _round.is_over:
		return
	_tick_ability(delta)
	if _player.hand.is_empty():
		return
	_delay -= delta
	if _delay > 0.0:
		return
	_schedule_next_card()
	_play_random_card()


func _tick_ability(delta: float) -> void:
	_ability_delay -= delta
	if _ability_delay > 0.0:
		return
	_ability_delay = ABILITY_CHECK_INTERVAL
	var passive: ClassPassive = _round.fields[_player.id].passive
	if passive.has_ability() and passive.get_ability_error().is_empty():
		_submit.call(MatchCommands.use_ability(_player.id))


func _schedule_next_card() -> void:
	_delay = randf_range(MIN_CARD_DELAY, MAX_CARD_DELAY)


func _play_random_card() -> void:
	var card: CardData = _player.hand.pick_random()
	var target: CardTarget = _choose_target(card)
	if target:
		_submit.call(MatchCommands.play_card(_player.id, card, target, _round.fields[target.player_id]))


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
	if opponent_id == -1:
		return null
	var opponent_field: Field = _round.fields[opponent_id]
	if opponent_field.is_character_shielded():
		var shields: Array[CombatUnit] = opponent_field.get_companions_tagged(&"mercenary")
		return CardTarget.for_unit(opponent_id, shields[0]) if not shields.is_empty() else null
	return CardTarget.for_unit(opponent_id, opponent_field.character)


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
		if _is_targetable_opponent(player_id):
			candidates.append(player_id)
			if CatchUpBoost.places_ahead(_round, _player.id, player_id) > 0:
				ahead.append(player_id)
	if not ahead.is_empty() and randf() < AIM_AHEAD_CHANCE:
		return ahead.pick_random()
	return candidates.pick_random() if not candidates.is_empty() else -1


func _is_targetable_opponent(player_id: int) -> bool:
	var field: Field = _round.fields[player_id]
	return player_id != _player.id and not field.is_protected() and not field.is_finished()
