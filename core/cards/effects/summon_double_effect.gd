class_name SummonDoubleEffect
extends CardEffect
## Dédoublement : invoque un double du personnage du lanceur pour un temps.
## Le double attaque avec une partie des dégâts du personnage, les monstres l'ignorent (seuls les
## autres joueurs peuvent l'abattre) et il répète les cartes du lanceur (voir DoubleEcho).

const TAG: StringName = &"double"

@export var duration: float = 20.0
@export var health: float = 40.0
## Part des dégâts d'attaque du personnage.
@export var attack_ratio: float = 0.5


func get_play_error(context: CardContext) -> String:
	if DoubleEcho.find_double(context.target_field) != null:
		return "Ton double est déjà sur le terrain."
	if not context.target_field.has_companion_slot():
		return "Plus de place sur le terrain."
	return ""


func apply(context: CardContext) -> void:
	var double: CombatUnit = context.target_field.add_companion(_build_double(context.target_field.character.data))
	if double:
		double.apply_status(StatusLibrary.mirror_image(duration))


func _build_double(original: UnitData) -> UnitData:
	var data: UnitData = UnitData.create(
		"Double",
		health,
		original.attack_damage * attack_ratio,
		original.attack_interval,
		original.crit_chance,
		original.color,
		original.portrait
	)
	return data.with_tag(TAG)
