class_name CatchUpBoost
extends RefCounted
## Bonus de rattrapage : une carte offensive qui vise directement un adversaire mieux classé dans
## la manche est plus puissante, d'autant plus que l'écart de places est grand.
## « Directement » = son personnage (carte UNIT), ou le joueur lui-même (carte PLAYER, ex : Chaîne).
## Jamais sur son monstre ni sur tout son terrain : renforcer les dégâts sur son monstre l'aiderait.
## Exclus aussi : cartes de soutien, ultimes, cartes globales, cartes de podium.

const BONUS_PER_PLACE: float = 0.1
const MAX_BONUS: float = 0.5


## 0.0 = pas de bonus ; 0.2 = +20 %.
static func bonus_for(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> float:
	if not is_eligible(card) or not _aims_at_opponent(combat_round, caster_id, card, target):
		return 0.0
	return clampf(places_ahead(combat_round, caster_id, target.player_id) * BONUS_PER_PLACE, 0.0, MAX_BONUS)


## Nombre de places d'avance de la cible sur le lanceur (négatif si elle est derrière).
static func places_ahead(combat_round: CombatRound, caster_id: int, target_player_id: int) -> int:
	return RoundRanking.position_of(combat_round, caster_id) - RoundRanking.position_of(combat_round, target_player_id)


static func is_eligible(card: CardData) -> bool:
	if card.is_beneficial or card.is_ultimate or card.class_id == PodiumCards.CLASS_ID:
		return false
	return card.target_mode in [CardData.TargetMode.UNIT, CardData.TargetMode.PLAYER]


## Vrai si la carte vise le personnage d'un autre joueur (ou ce joueur lui-même).
static func _aims_at_opponent(combat_round: CombatRound, caster_id: int, card: CardData, target: CardTarget) -> bool:
	var field: Field = combat_round.fields.get(target.player_id)
	if field == null or target.player_id == caster_id:
		return false
	return card.target_mode == CardData.TargetMode.PLAYER or target.unit == field.character
