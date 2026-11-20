class_name AudioBuses
extends RefCounted
## Noms des bus audio du jeu et leur libellé dans les options.

const MASTER: StringName = &"Master"
const MUSIC: StringName = &"Music"
const SFX: StringName = &"SFX"

const ALL: Array[StringName] = [MASTER, MUSIC, SFX]

const LABELS: Dictionary[StringName, String] = {
	MASTER: "Volume général",
	MUSIC: "Musique",
	SFX: "Effets sonores",
}


static func label(bus: StringName) -> String:
	return LABELS.get(bus, String(bus))
