class_name CardText
extends RefCounted
## Texte d'une carte avec ses valeurs ajustées par un multiplicateur de puissance (bonus de rattrapage),
## façon Slay the Spire : les nombres renforcés passent en vert.
## Seuls les dégâts (« 30 dégâts ») et les durées (« pendant 4 s ») sont concernés ;
## les pourcentages et les dégâts par seconde ne changent pas.

const BOOSTED_COLOR := "#7dff8a"

static var _damage_pattern: RegEx
static var _duration_pattern: RegEx


## BBCode centré prêt pour un RichTextLabel.
static func describe(card: CardData, power: float) -> String:
	var text: String = card.description
	if not is_equal_approx(power, 1.0):
		text = _scale_matches(text, _damage_regex(), power, true)
		text = _scale_matches(text, _duration_regex(), power, false)
	return "[center]%s[/center]" % text


## « 30 dégâts » mais pas « 5 dégâts par seconde ».
static func _damage_regex() -> RegEx:
	if _damage_pattern == null:
		_damage_pattern = RegEx.create_from_string("(\\d+(?:,\\d+)?)(?= dégâts(?! par seconde))")
	return _damage_pattern


## « 4 s », « 2,5 s ».
static func _duration_regex() -> RegEx:
	if _duration_pattern == null:
		_duration_pattern = RegEx.create_from_string("(\\d+(?:,\\d+)?)(?= s(?:[\\s.,)]|$))")
	return _duration_pattern


## Remplace chaque nombre trouvé, de la fin vers le début pour garder les positions valides.
static func _scale_matches(text: String, pattern: RegEx, power: float, round_to_int: bool) -> String:
	var matches: Array[RegExMatch] = pattern.search_all(text)
	for index: int in range(matches.size() - 1, -1, -1):
		var found: RegExMatch = matches[index]
		var value: float = found.get_string(1).replace(",", ".").to_float() * power
		var formatted: String = str(roundi(value)) if round_to_int else _format_seconds(value)
		var colored: String = "[color=%s]%s[/color]" % [BOOSTED_COLOR, formatted]
		text = text.substr(0, found.get_start(1)) + colored + text.substr(found.get_end(1))
	return text


## Une décimale au plus, virgule française (« 4,8 »), sans « ,0 ».
static func _format_seconds(value: float) -> String:
	var rounded: float = snappedf(value, 0.1)
	if is_equal_approx(rounded, roundf(rounded)):
		return str(roundi(rounded))
	return ("%.1f" % rounded).replace(".", ",")
