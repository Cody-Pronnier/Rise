class_name BalanceOverrides
extends RefCounted
## Réglages globaux (CombatConfig) que le simulateur peut modifier avec --set et --sweep.
## Les valeurs d'origine sont gardées pour être remises entre deux séries de parties.
## Une liste (MONSTERS_BY_ROUND, POINTS_BY_RANK) s'écrit avec des points-virgules : 3;3;5.
## Les stats d'un personnage s'écrivent classe.stat : archer.attack_damage=6.5
## (stats : max_health, attack_damage, attack_interval, crit_chance).

const NAMES: Array[String] = [
	"GAME_SPEED",
	"MONSTER_BREATHER_DURATION",
	"RESPAWN_DELAY",
	"CRITICAL_MULTIPLIER",
	"MONSTER_SCALING_PER_ROUND",
	"MONSTER_HEALTH_MULTIPLIER",
	"MAX_ROUNDS",
	"MANA_MAX",
	"MANA_START",
	"MANA_PER_SECOND",
	"PREPARATION_DURATION",
	"MONSTERS_BY_ROUND",
	"POINTS_BY_RANK",
]

const CHARACTER_STATS: Array[String] = ["max_health", "attack_damage", "attack_interval", "crit_chance"]

static var _defaults: Dictionary = {}
## « classe.stat » → valeur d'origine, pour les stats de personnage modifiées.
static var _character_defaults: Dictionary = {}


## Stats de personnage modifiées dans la série en cours, en texte (« archer.attack_damage=6.5 »).
static func describe_character_overrides() -> String:
	var parts: PackedStringArray = []
	for key: String in _character_defaults:
		parts.append("%s=%s" % [key, _read_character_stat(key)])
	return " ".join(parts)


static func is_known(setting: String) -> bool:
	return NAMES.has(setting)


## Garde les valeurs d'origine (à appeler une fois, avant toute modification).
static func remember_defaults() -> void:
	for setting: String in NAMES:
		_defaults[setting] = read(setting)


static func restore_defaults() -> void:
	for setting: String in _defaults:
		_write(setting, _defaults[setting])
	for key: String in _character_defaults:
		_write_character_stat(key, _character_defaults[key])
	_character_defaults.clear()


## Applique une valeur écrite en texte (« 0.5 », « 3;3;5 »). Renvoie "" ou l'erreur.
static func apply(setting: String, text: String) -> String:
	if setting.contains("."):
		return _apply_character_stat(setting, text.to_float())
	if not is_known(setting):
		return "Réglage inconnu : %s (réglages possibles : %s)" % [setting, ", ".join(PackedStringArray(NAMES))]
	if setting in ["MONSTERS_BY_ROUND", "POINTS_BY_RANK"]:
		_write(setting, _parse_int_list(text))
	elif setting == "MAX_ROUNDS":
		_write(setting, text.to_int())
	else:
		_write(setting, text.to_float())
	return ""


## Valeur actuelle, en texte lisible (pour les rapports).
static func describe(setting: String) -> String:
	var value: Variant = read(setting)
	if value is Array:
		return ";".join(PackedStringArray((value as Array).map(func(item: Variant) -> String: return str(item))))
	return str(value)


static func read(setting: String) -> Variant:
	match setting:
		"GAME_SPEED": return CombatConfig.GAME_SPEED
		"MONSTER_BREATHER_DURATION": return CombatConfig.MONSTER_BREATHER_DURATION
		"RESPAWN_DELAY": return CombatConfig.RESPAWN_DELAY
		"CRITICAL_MULTIPLIER": return CombatConfig.CRITICAL_MULTIPLIER
		"MONSTER_SCALING_PER_ROUND": return CombatConfig.MONSTER_SCALING_PER_ROUND
		"MONSTER_HEALTH_MULTIPLIER": return CombatConfig.MONSTER_HEALTH_MULTIPLIER
		"MAX_ROUNDS": return CombatConfig.MAX_ROUNDS
		"MANA_MAX": return CombatConfig.MANA_MAX
		"MANA_START": return CombatConfig.MANA_START
		"MANA_PER_SECOND": return CombatConfig.MANA_PER_SECOND
		"PREPARATION_DURATION": return CombatConfig.PREPARATION_DURATION
		"MONSTERS_BY_ROUND": return CombatConfig.MONSTERS_BY_ROUND.duplicate()
		"POINTS_BY_RANK": return CombatConfig.POINTS_BY_RANK.duplicate()
	return null


static func _write(setting: String, value: Variant) -> void:
	match setting:
		"GAME_SPEED": CombatConfig.GAME_SPEED = value
		"MONSTER_BREATHER_DURATION": CombatConfig.MONSTER_BREATHER_DURATION = value
		"RESPAWN_DELAY": CombatConfig.RESPAWN_DELAY = value
		"CRITICAL_MULTIPLIER": CombatConfig.CRITICAL_MULTIPLIER = value
		"MONSTER_SCALING_PER_ROUND": CombatConfig.MONSTER_SCALING_PER_ROUND = value
		"MONSTER_HEALTH_MULTIPLIER": CombatConfig.MONSTER_HEALTH_MULTIPLIER = value
		"MAX_ROUNDS": CombatConfig.MAX_ROUNDS = value
		"MANA_MAX": CombatConfig.MANA_MAX = value
		"MANA_START": CombatConfig.MANA_START = value
		"MANA_PER_SECOND": CombatConfig.MANA_PER_SECOND = value
		"PREPARATION_DURATION": CombatConfig.PREPARATION_DURATION = value
		"MONSTERS_BY_ROUND": CombatConfig.MONSTERS_BY_ROUND.assign(value)
		"POINTS_BY_RANK": CombatConfig.POINTS_BY_RANK.assign(value)


## Stat du personnage d'une classe (ClassData.character), lue en direct par les combats.
static func _apply_character_stat(key: String, value: float) -> String:
	var class_data: ClassData = ClassCatalog.find(StringName(key.get_slice(".", 0)))
	var stat: String = key.get_slice(".", 1)
	if class_data == null:
		return "Classe inconnue dans %s" % key
	if not CHARACTER_STATS.has(stat):
		return "Stat inconnue dans %s (stats possibles : %s)" % [key, ", ".join(PackedStringArray(CHARACTER_STATS))]
	if not _character_defaults.has(key):
		_character_defaults[key] = _read_character_stat(key)
	_write_character_stat(key, value)
	return ""


static func _read_character_stat(key: String) -> float:
	var class_data: ClassData = ClassCatalog.find(StringName(key.get_slice(".", 0)))
	return class_data.character.get(key.get_slice(".", 1))


static func _write_character_stat(key: String, value: float) -> void:
	var class_data: ClassData = ClassCatalog.find(StringName(key.get_slice(".", 0)))
	class_data.character.set(key.get_slice(".", 1), value)


static func _parse_int_list(text: String) -> Array[int]:
	var values: Array[int] = []
	for part: String in text.split(";", false):
		values.append(part.strip_edges().to_int())
	return values
