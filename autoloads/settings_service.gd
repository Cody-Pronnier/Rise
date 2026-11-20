extends Node
## Réglages du joueur : volumes, résolution, plein écran, V-Sync.
## Les applique au moteur et les garde sur disque via SettingsStorage.

signal settings_changed

const AUDIO_SECTION: String = "audio"
const DISPLAY_SECTION: String = "display"
const FULLSCREEN_KEY: String = "fullscreen"
const VSYNC_KEY: String = "vsync"
const RESOLUTION_KEY: String = "resolution"

## Résolutions proposées en mode fenêtré (filtrées selon la taille de l'écran).
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const DEFAULT_VOLUME: float = 0.8
const MUTE_THRESHOLD: float = 0.001

var _storage := SettingsStorage.new()


func _ready() -> void:
	_ensure_audio_buses()
	_storage.load_from_disk()
	_apply_all()


# --- API publique -----------------------------------------------------------

func get_volume(bus: StringName) -> float:
	return _storage.get_value(AUDIO_SECTION, String(bus), DEFAULT_VOLUME)


## volume linéaire entre 0 et 1.
func set_volume(bus: StringName, volume: float) -> void:
	_storage.set_value(AUDIO_SECTION, String(bus), clampf(volume, 0.0, 1.0))
	_apply_volume(bus)
	settings_changed.emit()


func is_fullscreen() -> bool:
	return _storage.get_value(DISPLAY_SECTION, FULLSCREEN_KEY, false)


func set_fullscreen(enabled: bool) -> void:
	_storage.set_value(DISPLAY_SECTION, FULLSCREEN_KEY, enabled)
	_apply_fullscreen()
	settings_changed.emit()


func get_resolution() -> Vector2i:
	return _storage.get_value(DISPLAY_SECTION, RESOLUTION_KEY, DEFAULT_RESOLUTION)


func set_resolution(resolution: Vector2i) -> void:
	_storage.set_value(DISPLAY_SECTION, RESOLUTION_KEY, resolution)
	_apply_resolution()
	settings_changed.emit()


## Résolutions qui tiennent sur l'écran actuel (au moins la plus petite).
func get_available_resolutions() -> Array[Vector2i]:
	var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var available: Array[Vector2i] = []
	for resolution: Vector2i in RESOLUTIONS:
		if resolution.x <= screen_size.x and resolution.y <= screen_size.y:
			available.append(resolution)
	if available.is_empty():
		available.append(RESOLUTIONS[0])
	return available


func is_vsync_enabled() -> bool:
	return _storage.get_value(DISPLAY_SECTION, VSYNC_KEY, true)


func set_vsync_enabled(enabled: bool) -> void:
	_storage.set_value(DISPLAY_SECTION, VSYNC_KEY, enabled)
	_apply_vsync()
	settings_changed.emit()


func save() -> void:
	_storage.save_to_disk()


# --- Application au moteur --------------------------------------------------

func _apply_all() -> void:
	for bus: StringName in AudioBuses.ALL:
		_apply_volume(bus)
	_apply_fullscreen()
	_apply_resolution()
	_apply_vsync()


func _apply_volume(bus: StringName) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index == -1:
		return
	var volume: float = get_volume(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(volume))
	AudioServer.set_bus_mute(index, volume <= MUTE_THRESHOLD)


func _apply_fullscreen() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	if not is_fullscreen():
		_apply_resolution()


## En plein écran, la résolution native de l'écran est utilisée ; on ne touche qu'à la fenêtre.
## L'interface s'adapte toute seule (mode d'étirement « canvas_items » du projet).
func _apply_resolution() -> void:
	if is_fullscreen():
		return
	var size: Vector2i = get_resolution()
	var screen: int = DisplayServer.window_get_current_screen()
	var screen_origin: Vector2i = DisplayServer.screen_get_position(screen)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen_origin + (screen_size - size) / 2)


func _apply_vsync() -> void:
	var mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED if is_vsync_enabled() else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


## Crée les bus Musique et Effets s'ils n'existent pas dans la disposition audio du projet.
func _ensure_audio_buses() -> void:
	for bus: StringName in AudioBuses.ALL:
		if AudioServer.get_bus_index(bus) == -1:
			_create_bus(bus)


func _create_bus(bus: StringName) -> void:
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, AudioBuses.MASTER)
