class_name HandLayout
extends RefCounted
## Calcule la position de chaque carte dans la main en éventail (façon Slay the Spire 2).
## Fonctions pures : on donne l'index, le nombre de cartes et la zone, on récupère une pose.

const CARD_SIZE := Vector2(170, 240)

const MAX_SPACING: float = 128.0
const MAX_HAND_WIDTH_RATIO: float = 0.62
const MAX_ROTATION_DEGREES: float = 9.0
## Les cartes du bord descendent pour former l'arc.
const ARC_DROP: float = 26.0
## Part de la carte visible au repos (le bas sort de l'écran).
const VISIBLE_RATIO: float = 0.7

const HOVER_LIFT: float = 112.0
const HOVER_SCALE: float = 1.25
const HOVER_Z: int = 100
const SELECTED_LIFT: float = 70.0
const SELECTED_SCALE: float = 1.12
const SELECTED_Z: int = 90
## Écartement des voisines de la carte survolée.
const NEIGHBOR_PUSH: float = 60.0


class Pose:
	var center: Vector2
	var rotation: float = 0.0
	var scale: float = 1.0
	var z_index: int = 0


static func pose_for(index: int, count: int, area: Vector2, hovered: int, selected: int) -> Pose:
	var pose := Pose.new()
	var spread: float = _spread(index, count)
	pose.center = Vector2(
		base_x(index, count, area) + _neighbor_push(index, hovered),
		_rest_y(area) + spread * spread * ARC_DROP
	)
	pose.rotation = deg_to_rad(spread * MAX_ROTATION_DEGREES)
	pose.z_index = index
	if index == selected:
		_lift(pose, area, SELECTED_LIFT, SELECTED_SCALE, SELECTED_Z)
	if index == hovered:
		_lift(pose, area, HOVER_LIFT, HOVER_SCALE, HOVER_Z)
	return pose


## Index de la carte la plus proche de x, ou -1 si la souris est hors de la main.
static func index_at(x: float, count: int, area: Vector2) -> int:
	var best_index: int = -1
	var best_distance: float = spacing(count, area) / 2.0 + CARD_SIZE.x * 0.25
	for index: int in count:
		var distance: float = absf(x - base_x(index, count, area))
		if distance < best_distance:
			best_index = index
			best_distance = distance
	return best_index


static func base_x(index: int, count: int, area: Vector2) -> float:
	return area.x / 2.0 + (index - (count - 1) / 2.0) * spacing(count, area)


static func spacing(count: int, area: Vector2) -> float:
	if count <= 1:
		return 0.0
	return minf(MAX_SPACING, area.x * MAX_HAND_WIDTH_RATIO / (count - 1))


## Position relative dans l'éventail : -1 (bord gauche) à 1 (bord droit).
static func _spread(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	return (index - (count - 1) / 2.0) / ((count - 1) / 2.0)


static func _rest_y(area: Vector2) -> float:
	return area.y - CARD_SIZE.y * VISIBLE_RATIO + CARD_SIZE.y / 2.0


static func _neighbor_push(index: int, hovered: int) -> float:
	if hovered == -1 or index == hovered:
		return 0.0
	var distance: int = index - hovered
	return signf(distance) * NEIGHBOR_PUSH / absf(distance)


static func _lift(pose: Pose, area: Vector2, lift: float, lift_scale: float, z: int) -> void:
	pose.center.y = _rest_y(area) - lift
	pose.rotation = 0.0
	pose.scale = lift_scale
	pose.z_index = z
