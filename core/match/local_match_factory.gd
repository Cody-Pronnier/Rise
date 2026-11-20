class_name LocalMatchFactory
extends RefCounted
## Fiches des joueurs d'une partie (format de la commande START_MATCH / BEGIN_CLASS_SELECTION) :
## { "id", "name", "bot" } puis "class" une fois les classes connues. Utilisé uniquement par l'hôte.

## Les bots ont des identifiants à part pour ne jamais croiser un identifiant Steam.
const BOT_ID_BASE: int = 1000


## Entraînement : le joueur local avec sa classe (et son deck) + des bots aux classes aléatoires.
## deck_ids vide = deck de base.
static func create_training_specs(local_id: int, local_name: String, local_class_id: StringName, deck_ids: Array[StringName] = []) -> Array[Dictionary]:
	var specs: Array[Dictionary] = [human_spec(local_id, local_name)]
	specs[0]["class"] = local_class_id
	if not deck_ids.is_empty():
		specs[0]["deck"] = deck_ids
	for bot_index: int in range(1, GameConfig.MAX_PLAYERS):
		specs.append(bot_spec(bot_index))
	return assign_bot_classes(specs)


## En ligne : les membres du salon + les bots ajoutés par l'hôte (sans classes).
static func create_online_specs(members: Array[LobbyMember], bot_count: int) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for member: LobbyMember in members:
		specs.append(human_spec(member.steam_id, member.display_name))
	for bot_index: int in range(1, bot_count + 1):
		specs.append(bot_spec(bot_index))
	return specs


static func human_spec(player_id: int, display_name: String) -> Dictionary:
	return { "id": player_id, "name": display_name, "bot": false }


static func bot_spec(bot_index: int) -> Dictionary:
	return { "id": BOT_ID_BASE + bot_index, "name": "Bot %d" % bot_index, "bot": true }


## Donne une classe aléatoire aux bots qui n'en ont pas et ajoute la classe à leur nom.
static func assign_bot_classes(specs: Array[Dictionary]) -> Array[Dictionary]:
	for spec: Dictionary in specs:
		if spec["bot"] and not spec.has("class"):
			var class_data: ClassData = ClassCatalog.pick_random()
			spec["class"] = class_data.id
			spec["name"] = "%s (%s)" % [spec["name"], class_data.display_name]
	return specs
