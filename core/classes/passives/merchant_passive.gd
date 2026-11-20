class_name MerchantPassive
extends ClassPassive
## Le Marchand gagne de l'or avec le temps et le dépense pour recruter un mercenaire (un seul à la fois).
## Tant que son mercenaire est debout, le Marchand ne frappe plus et les cartes adverses
## ne peuvent pas le viser (les monstres attaquent déjà les compagnons en premier).

const STARTING_GOLD: float = 25.0
const GOLD_PER_SECOND: float = 1.5
const RECRUIT_COST: int = 25

var _mercenary: UnitData
var _gold: float = STARTING_GOLD


func _init(mercenary: UnitData) -> void:
	_mercenary = mercenary


func tick(delta: float) -> void:
	var before: int = get_gold()
	_gold += GOLD_PER_SECOND * delta
	if get_gold() != before:
		changed.emit()


func character_can_attack() -> bool:
	return not field.has_mercenary()


func shields_character() -> bool:
	return field.has_mercenary()


func status_text() -> String:
	var guard: String = "protégé par ton mercenaire" if field.has_mercenary() else "sans mercenaire"
	return "Or : %d  ·  %s" % [get_gold(), guard]


func has_ability() -> bool:
	return true


func ability_label() -> String:
	return "Recruter (%d or)" % RECRUIT_COST


func get_ability_error() -> String:
	if field.has_mercenary():
		return "Tu as déjà un mercenaire."
	if get_gold() < RECRUIT_COST:
		return "Pas assez d'or (%d / %d)." % [get_gold(), RECRUIT_COST]
	if not field.has_companion_slot():
		return "Il n'y a plus de place sur ton terrain."
	return ""


func use_ability() -> void:
	_gold -= RECRUIT_COST
	field.add_companion(_mercenary)
	changed.emit()


func describe_ability_use() -> String:
	return "a recruté un mercenaire"


func uses_gold() -> bool:
	return true


func get_gold() -> int:
	return floori(_gold)


func receive_gold(amount: int) -> void:
	_gold += amount
	changed.emit()
