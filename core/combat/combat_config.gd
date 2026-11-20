class_name CombatConfig
extends RefCounted
## Réglages d'équilibrage du combat. Aucune logique ici.

const MONSTERS_PER_ROUND: int = 3
const RESPAWN_DELAY: float = 5.0
## Compagnons d'un même camp sur un terrain (au-delà, les invocations échouent).
const MAX_COMPANIONS: int = 4
const CRITICAL_MULTIPLIER: float = 1.5
const MIN_ATTACK_SPEED_MULTIPLIER: float = 0.1

## Hausse des stats des monstres à chaque manche (0.25 = +25 % par manche).
const MONSTER_SCALING_PER_ROUND: float = 0.25

const MAX_ROUNDS: int = 3

## Deck pendant une partie : 6 cartes à la manche 1. Après chaque manche, on tire 5 cartes
## de la suite de son deck, on en garde 2 et les 3 autres sont défaussées.
const STARTING_HAND_SIZE: int = 6
const DECK_CARDS_OFFERED: int = 5
const DECK_CARDS_KEPT: int = 2

## Boutique entre deux manches : cartes achetées avec des points (4 au plus sur toute la partie).
const SHOP_OFFER_SIZE: int = 3
const SHOP_CARD_COST: int = 3
const MAX_SHOP_PURCHASES: int = 4

## Récompenses entre deux manches.
## Nombre de joueurs du podium qui se partagent les cartes neutres (une carte proposée par place).
const PODIUM_SIZE: int = 3

## Échanges et alliances.
const TRADE_OFFER_TIMEOUT: float = 20.0
## Offres en attente qu'un joueur peut recevoir en même temps.
const MAX_PENDING_OFFERS_PER_PLAYER: int = 5
## Points donnés à son allié quand on rompt l'alliance (le total peut devenir négatif).
const ALLIANCE_BREAK_COST: int = 3

## Points selon l'ordre d'arrivée. Le joueur qui n'a pas fini marque 0.
const POINTS_BY_RANK: Array[int] = [8, 7, 6, 5, 4, 3, 2]

## Sous ce ratio de PV, la « Graine de vitalité » se déclenche.
const EMERGENCY_HEALTH_RATIO: float = 0.1
