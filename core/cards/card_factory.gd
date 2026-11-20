class_name CardFactory
extends RefCounted
## Raccourcis pour déclarer une carte en une ligne.


static func card(
	id: StringName,
	display_name: String,
	description: String,
	target_mode: CardData.TargetMode,
	effects: Array,
	is_beneficial: bool
) -> CardData:
	var data := CardData.new()
	data.id = id
	data.display_name = display_name
	data.description = description
	data.target_mode = target_mode
	data.is_beneficial = is_beneficial
	data.effects.assign(effects)
	return data


static func ultimate(
	id: StringName,
	display_name: String,
	description: String,
	target_mode: CardData.TargetMode,
	effects: Array,
	is_beneficial: bool
) -> CardData:
	var data: CardData = card(id, display_name, description, target_mode, effects, is_beneficial)
	data.is_ultimate = true
	return data
