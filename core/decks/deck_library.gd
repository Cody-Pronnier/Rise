class_name DeckLibrary
extends RefCounted
## Decks enregistrés sur la machine du joueur (user://decks.cfg) : SLOTS_PER_CLASS par classe.
## Un emplacement vide renvoie null.

const PATH: String = "user://decks.cfg"
const SLOTS_PER_CLASS: int = 2
const MAX_NAME_LENGTH: int = 24


static func get_deck(class_id: StringName, slot: int) -> DeckList:
	var config: ConfigFile = _load()
	var section: String = _section(class_id, slot)
	if not config.has_section(section):
		return null
	var ids: Array[StringName] = []
	for card_id: Variant in config.get_value(section, "cards", []):
		ids.append(StringName(card_id))
	return DeckList.new(config.get_value(section, "name", "Deck %d" % (slot + 1)), class_id, ids)


## Emplacements de la classe (null pour un emplacement vide).
static func get_decks(class_id: StringName) -> Array[DeckList]:
	var decks: Array[DeckList] = []
	for slot: int in SLOTS_PER_CLASS:
		decks.append(get_deck(class_id, slot))
	return decks


## Decks complets et valides, prêts à être choisis pour une partie.
static func get_playable_decks(class_id: StringName) -> Array[DeckList]:
	var playable: Array[DeckList] = []
	for deck: DeckList in get_decks(class_id):
		if deck and deck.is_valid():
			playable.append(deck)
	return playable


static func save_deck(slot: int, deck: DeckList) -> void:
	var config: ConfigFile = _load()
	var section: String = _section(deck.class_id, slot)
	config.set_value(section, "name", sanitize_name(deck.name, slot))
	var ids: Array[String] = []
	for card_id: StringName in deck.card_ids:
		ids.append(String(card_id))
	config.set_value(section, "cards", ids)
	config.save(PATH)


static func delete_deck(class_id: StringName, slot: int) -> void:
	var config: ConfigFile = _load()
	var section: String = _section(class_id, slot)
	if config.has_section(section):
		config.erase_section(section)
		config.save(PATH)


static func sanitize_name(deck_name: String, slot: int) -> String:
	var cleaned: String = deck_name.strip_edges().left(MAX_NAME_LENGTH)
	return cleaned if not cleaned.is_empty() else "Deck %d" % (slot + 1)


static func _section(class_id: StringName, slot: int) -> String:
	return "%s_%d" % [class_id, slot]


static func _load() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(PATH)
	return config
