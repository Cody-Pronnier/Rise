class_name MatchCommands
extends RefCounted
## Les commandes qui font avancer une partie. Ce sont de simples Dictionary (sérialisables avec
## var_to_bytes) : l'hôte les ordonne et les diffuse, chaque machine les applique dans le même ordre.
## Les cartes sont désignées par leur id (cartes en main) ou leur index (offres de récompense),
## les unités par Field.ref_of().

const TYPE: String = "type"

# Déroulé de la partie (émises uniquement par l'hôte).
const BEGIN_CLASS_SELECTION: String = "begin_class_selection"
const CLASS_LOCKED: String = "class_locked"
const START_MATCH: String = "start_match"
const START_ROUND: String = "start_round"
const START_REWARDS: String = "start_rewards"
const END_MATCH: String = "end_match"

# Actions des joueurs (émises par un joueur ou un bot, validées à l'application).
const PLAY_CARD: String = "play_card"
## Capacité active de la classe (ex : recruter un mercenaire pour le Marchand).
const USE_ABILITY: String = "use_ability"
const PROPOSE_TRADE: String = "propose_trade"
const ACCEPT_TRADE: String = "accept_trade"
const DECLINE_TRADE: String = "decline_trade"
const CANCEL_TRADE: String = "cancel_trade"
const BREAK_ALLIANCE: String = "break_alliance"
## Achat d'une carte de la boutique (par son index dans l'offre du joueur).
const BUY_CARD: String = "buy_card"
## Le joueur a fini ses achats et choix entre deux manches ("keep" : cartes de son deck gardées).
const REWARDS_READY: String = "rewards_ready"
const DRAFT_PICK: String = "draft_pick"

## Requête privée client → hôte, jamais diffusée (le choix de classe reste secret).
const CHOOSE_CLASS: String = "choose_class"

const PLAYER_ACTIONS: Array[String] = [
	PLAY_CARD, USE_ABILITY, PROPOSE_TRADE, ACCEPT_TRADE, DECLINE_TRADE, CANCEL_TRADE, BREAK_ALLIANCE, BUY_CARD, REWARDS_READY, DRAFT_PICK,
]


static func is_player_action(command: Dictionary) -> bool:
	return command.get(TYPE, "") in PLAYER_ACTIONS


# --- Déroulé ----------------------------------------------------------------

## players : [{ "id", "name", "bot" }] sans les classes.
static func begin_class_selection(players: Array[Dictionary], duration: float) -> Dictionary:
	return { TYPE: BEGIN_CLASS_SELECTION, "players": players, "duration": duration }


static func class_locked(player_id: int) -> Dictionary:
	return { TYPE: CLASS_LOCKED, "player": player_id }


## players : [{ "id", "name", "class", "bot", "deck" (facultatif) }].
static func start_match(seed_value: int, players: Array[Dictionary]) -> Dictionary:
	return { TYPE: START_MATCH, "seed": seed_value, "players": players }


static func start_round(round_index: int) -> Dictionary:
	return { TYPE: START_ROUND, "round": round_index }


static func start_rewards() -> Dictionary:
	return { TYPE: START_REWARDS }


static func end_match() -> Dictionary:
	return { TYPE: END_MATCH }


# --- Actions ----------------------------------------------------------------

static func play_card(player_id: int, card: CardData, target: CardTarget, field: Field) -> Dictionary:
	var unit_ref: String = field.ref_of(target.unit) if target.unit else ""
	return { TYPE: PLAY_CARD, "player": player_id, "card": card.id, "target": target.player_id, "unit": unit_ref }


static func use_ability(player_id: int) -> Dictionary:
	return { TYPE: USE_ABILITY, "player": player_id }


static func propose_trade(player_id: int, offer: TradeOffer) -> Dictionary:
	return {
		TYPE: PROPOSE_TRADE,
		"player": player_id,
		"to": offer.to_id,
		"give": card_ids(offer.given_cards),
		"give_points": offer.given_points,
		"ask": card_ids(offer.requested_cards),
		"ask_points": offer.requested_points,
		"alliance": offer.proposes_alliance,
	}


static func accept_trade(player_id: int, offer_id: int) -> Dictionary:
	return { TYPE: ACCEPT_TRADE, "player": player_id, "offer": offer_id }


static func decline_trade(player_id: int, offer_id: int) -> Dictionary:
	return { TYPE: DECLINE_TRADE, "player": player_id, "offer": offer_id }


static func cancel_trade(player_id: int, offer_id: int) -> Dictionary:
	return { TYPE: CANCEL_TRADE, "player": player_id, "offer": offer_id }


static func break_alliance(player_id: int) -> Dictionary:
	return { TYPE: BREAK_ALLIANCE, "player": player_id }


## index : position de la carte dans la boutique du joueur.
static func buy_card(player_id: int, index: int) -> Dictionary:
	return { TYPE: BUY_CARD, "player": player_id, "index": index }


## keep : positions des cartes gardées parmi celles tirées de son deck.
static func rewards_ready(player_id: int, keep: Array[int]) -> Dictionary:
	return { TYPE: REWARDS_READY, "player": player_id, "keep": keep }


## index : position de la carte dans l'offre neutre du draft.
static func draft_pick(player_id: int, index: int) -> Dictionary:
	return { TYPE: DRAFT_PICK, "player": player_id, "index": index }


## deck : ids des 16 cartes du deck choisi (vide = deck de base). L'hôte le vérifie.
static func choose_class(player_id: int, class_id: StringName, deck: Array[StringName] = []) -> Dictionary:
	return { TYPE: CHOOSE_CLASS, "player": player_id, "class": class_id, "deck": deck }


static func card_ids(cards: Array[CardData]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: CardData in cards:
		ids.append(card.id)
	return ids
