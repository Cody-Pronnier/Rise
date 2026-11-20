class_name SettingsStorage
extends RefCounted
## Lecture et écriture des réglages dans user://settings.cfg. Ne sait pas ce que les valeurs signifient.

const FILE_PATH: String = "user://settings.cfg"

var _config := ConfigFile.new()


func load_from_disk() -> void:
	var error: Error = _config.load(FILE_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de lire les réglages (%s)." % error_string(error))


func save_to_disk() -> void:
	var error: Error = _config.save(FILE_PATH)
	if error != OK:
		push_warning("Impossible d'enregistrer les réglages (%s)." % error_string(error))


func get_value(section: String, key: String, default_value: Variant) -> Variant:
	return _config.get_value(section, key, default_value)


func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
