class_name BotRewardPicker
extends RefCounted
## Récompenses des bots. Produit des commandes, ne modifie rien.

## Un bot n'achète que s'il garde au moins ce nombre de points après l'achat.
const MIN_POINTS_KEPT: int = 4
const BUY_CHANCE: float = 0.5


## Achat éventuel d'une carte en boutique, puis validation avec des cartes de deck gardées au hasard.
static func shop_commands(phase: RewardPhase, player_id: int) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var player: PlayerState = phase.get_player(player_id)
	var can_afford: bool = player.points - CombatConfig.SHOP_CARD_COST >= MIN_POINTS_KEPT
	if can_afford and player.can_purchase() and randf() < BUY_CHANCE:
		commands.append(MatchCommands.buy_card(player_id, randi() % phase.get_shop_offer(player_id).size()))
	commands.append(MatchCommands.rewards_ready(player_id, _random_keep(phase, player_id)))
	return commands


static func _random_keep(phase: RewardPhase, player_id: int) -> Array[int]:
	var indices: Array[int] = []
	for index: int in phase.get_deck_offer(player_id).size():
		indices.append(index)
	indices.shuffle()
	return indices.slice(0, phase.get_keep_count(player_id))


## Commande de draft, ou {} s'il n'y a plus rien à prendre.
static func draft_command(phase: RewardPhase, player_id: int) -> Dictionary:
	var available: Array[CardData] = phase.draft.get_available()
	if available.is_empty():
		return {}
	var offer: Array[CardData] = phase.draft.get_offer()
	return MatchCommands.draft_pick(player_id, offer.find(available.pick_random()))
