class_name TargetingArrow
extends Control
## Flèche courbe de la carte sélectionnée jusqu'à la souris, pendant le choix d'une cible.

const DOT_COUNT: int = 20
const MIN_DOT_RADIUS: float = 3.0
const MAX_DOT_RADIUS: float = 7.0
const HEAD_LENGTH: float = 26.0
const HEAD_WIDTH: float = 18.0
const COLOR := Color(1.0, 0.8, 0.3)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.6)

## Renvoie la position globale de départ (la carte se déplace, on la relit à chaque image).
var _source_provider: Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	stop()


func _process(_delta: float) -> void:
	queue_redraw()


func start(source_provider: Callable) -> void:
	_source_provider = source_provider
	show()
	set_process(true)


func stop() -> void:
	_source_provider = Callable()
	hide()
	set_process(false)


func _draw() -> void:
	if not _source_provider.is_valid():
		return
	var start_point: Vector2 = get_global_transform().affine_inverse() * (_source_provider.call() as Vector2)
	var end_point: Vector2 = get_local_mouse_position()
	var control_point := Vector2(start_point.x, end_point.y)
	_draw_dots(start_point, control_point, end_point)
	_draw_head(control_point, end_point)


func _draw_dots(start_point: Vector2, control_point: Vector2, end_point: Vector2) -> void:
	for index: int in DOT_COUNT:
		var t: float = float(index) / DOT_COUNT
		var point: Vector2 = _bezier(start_point, control_point, end_point, t)
		var radius: float = lerpf(MIN_DOT_RADIUS, MAX_DOT_RADIUS, t)
		draw_circle(point, radius + 1.5, OUTLINE_COLOR)
		draw_circle(point, radius, Color(COLOR, lerpf(0.35, 1.0, t)))


func _draw_head(control_point: Vector2, end_point: Vector2) -> void:
	var direction: Vector2 = (end_point - control_point.lerp(end_point, 0.9)).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	var normal := Vector2(-direction.y, direction.x)
	var base: Vector2 = end_point - direction * HEAD_LENGTH
	var points := PackedVector2Array([end_point, base + normal * HEAD_WIDTH / 2.0, base - normal * HEAD_WIDTH / 2.0])
	draw_colored_polygon(points, COLOR)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), OUTLINE_COLOR, 2.0)


static func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
