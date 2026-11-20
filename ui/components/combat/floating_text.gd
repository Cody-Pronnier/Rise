class_name FloatingText
extends Label
## Texte qui monte et s'efface (dégâts, soins, esquives, nom d'une carte jouée).

const RISE_DISTANCE: float = 50.0
const DURATION: float = 0.8
const WIDTH: float = 100.0
const TITLE_WIDTH: float = 220.0
const HORIZONTAL_JITTER: float = 20.0
const FONT_SIZE: int = 22
const TITLE_FONT_SIZE: int = 26
const TITLE_DURATION: float = 1.3

var _font_size: int = FONT_SIZE
var _width: float = WIDTH
var _duration: float = DURATION
var _jitter: float = HORIZONTAL_JITTER


static func spawn(parent: Control, text: String, color: Color) -> void:
	_spawn_label(parent, FloatingText.new(), text, color)


## Version plus grande, plus lente et centrée : pour annoncer une carte.
static func spawn_title(parent: Control, text: String, color: Color) -> void:
	var label := FloatingText.new()
	label._font_size = TITLE_FONT_SIZE
	label._width = TITLE_WIDTH
	label._duration = TITLE_DURATION
	label._jitter = 0.0
	_spawn_label(parent, label, text, color)


static func _spawn_label(parent: Control, label: FloatingText, text: String, color: Color) -> void:
	label.text = text
	label.modulate = color
	parent.add_child(label)
	label._start()


func _start() -> void:
	_configure()
	_animate()


func _configure() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	z_index = 10
	add_theme_font_size_override("font_size", _font_size)
	add_theme_constant_override("outline_size", 6)
	add_theme_color_override("font_outline_color", Color.BLACK)
	size.x = _width
	position = Vector2(-_width / 2.0 + randf_range(-_jitter, _jitter), 0.0)


func _animate() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, _duration)
	tween.tween_property(self, "modulate:a", 0.0, _duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
