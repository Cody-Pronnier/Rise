class_name UnitView
extends Control
## Affiche une CombatUnit : corps, ombre, barre de vie, statuts et textes flottants,
## plus les effets visuels des statuts (taille, teinte, aura, bouclier) et l'impact des cartes.
## Ne modifie jamais l'unité ; un clic émet seulement « clicked ».

signal clicked(unit: CombatUnit)

const LUNGE_DISTANCE: float = 28.0
const LUNGE_DURATION: float = 0.1
const BOB_HEIGHT: float = 6.0
const BOB_MIN_DURATION: float = 1.4
const BOB_MAX_DURATION: float = 1.9
const FLASH_COLOR := Color(2.0, 2.0, 2.0)
const FLASH_DURATION: float = 0.15
const DEAD_TINT: float = 0.7
const BODY_RADIUS: int = 18

const DAMAGE_COLOR := Color(1.0, 0.4, 0.4)
const CRITICAL_COLOR := Color(1.0, 0.8, 0.2)
const HEAL_COLOR := Color(0.45, 1.0, 0.55)
const INFO_COLOR := Color(0.85, 0.9, 1.0)

const SCALE_TWEEN_DURATION: float = 0.4
const AURA_PULSE_DURATION: float = 1.2
const AURA_RADIUS: int = 80
const SHIELD_COLOR := Color(0.5, 0.9, 1.0)
const SHIELD_RADIUS: int = 100
const IMPACT_SIZE: float = 60.0
const IMPACT_DURATION: float = 0.45
const IMPACT_MAX_SCALE: float = 2.4

## 1 = regarde vers la droite (héros), -1 = vers la gauche (monstres).
@export var facing: float = 1.0

@onready var _name_label: Label = %NameLabel
@onready var _sprite: Panel = %Sprite
@onready var _initial_label: Label = %InitialLabel
@onready var _portrait: TextureRect = %Portrait
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _status_list: HFlowContainer = %StatusList
@onready var _highlight: Control = %Highlight
@onready var _float_anchor: Control = %FloatAnchor
@onready var _aura: Panel = %Aura
@onready var _shield: Panel = %Shield

var _unit: CombatUnit
var _binder := SignalBinder.new()
var _lunge_tween: Tween
var _flash_tween: Tween
var _scale_tween: Tween
var _aura_tween: Tween
## Pastille affichée pour chaque statut actif, pour mettre à jour son temps restant à chaque image.
var _status_chips: Dictionary[StatusInstance, Label] = {}


func _ready() -> void:
	_health_bar.add_theme_stylebox_override("background", UiStyle.bar_background())
	_shield.add_theme_stylebox_override("panel", _build_shield_style())
	## Le sprite grandit vers le haut, les pieds restent au sol.
	_sprite.pivot_offset = Vector2(_sprite.size.x / 2.0, _sprite.size.y)
	_start_idle_bob()
	set_process(false)


func _process(_delta: float) -> void:
	_update_status_timers()


func bind(unit: CombatUnit) -> void:
	_binder.clear()
	_unit = unit
	visible = unit != null
	if unit == null:
		_clear_status_chips()
		_reset_status_visuals()
		return
	_bind_unit_signals()
	_refresh_identity()
	_refresh_health()
	_refresh_statuses()


func get_unit() -> CombatUnit:
	return _unit


## Annonce d'une carte jouée sur cette unité : nom de la carte et anneau d'impact.
func play_card_burst(card_name: String, color: Color) -> void:
	FloatingText.spawn_title(_float_anchor, card_name, color)
	_spawn_impact_ring(color)


func set_targetable(enabled: bool) -> void:
	_highlight.visible = enabled and _unit != null and _unit.is_alive()


func _gui_input(event: InputEvent) -> void:
	if _unit and UiInput.is_left_click(event):
		clicked.emit(_unit)
		accept_event()


func _bind_unit_signals() -> void:
	_binder.bind(_unit.health_changed, _on_health_changed)
	_binder.bind(_unit.damaged, _on_damaged)
	_binder.bind(_unit.healed, _on_healed)
	_binder.bind(_unit.attack_avoided, _on_attack_avoided)
	_binder.bind(_unit.attacked, _play_lunge)
	_binder.bind(_unit.statuses_changed, _refresh_statuses)
	_binder.bind(_unit.died, _refresh_identity)
	_binder.bind(_unit.revived, _refresh_identity)


# --- Rafraîchissement -------------------------------------------------------

## Les rafraîchissements ignorent un appel arrivé après bind(null) : Godot peut encore livrer
## un signal en cours d'émission (ex : « died » du dernier monstre) juste après la déconnexion.
func _refresh_identity() -> void:
	if _unit == null:
		return
	_name_label.text = _unit.data.display_name
	_initial_label.text = _unit.data.display_name.left(1)
	_refresh_body()
	_apply_status_visuals()
	_health_bar.add_theme_stylebox_override("fill", UiStyle.bar_fill(_health_color()))


func _refresh_health() -> void:
	if _unit == null:
		return
	_health_bar.max_value = _unit.get_max_health()
	_health_bar.value = _unit.health
	_health_label.text = "%d / %d" % [ceili(_unit.health), ceili(_unit.get_max_health())]


func _refresh_statuses() -> void:
	if _unit == null:
		return
	_clear_status_chips()
	for instance: StatusInstance in _unit.statuses.get_instances():
		var chip: Label = _create_status_chip(instance.data)
		_status_list.add_child(chip)
		_status_chips[instance] = chip
	_update_status_timers()
	set_process(not _status_chips.is_empty())
	_apply_status_visuals()


func _clear_status_chips() -> void:
	for chip: Node in _status_list.get_children():
		chip.queue_free()
	_status_chips.clear()
	set_process(false)


func _create_status_chip(status: StatusData) -> Label:
	var chip := Label.new()
	chip.add_theme_font_size_override("font_size", 11)
	chip.add_theme_stylebox_override("normal", UiStyle.status_chip(status.category))
	return chip


func _update_status_timers() -> void:
	for instance: StatusInstance in _status_chips:
		_status_chips[instance].text = _format_status(instance)


## « Bouclier 3s » ; une décimale sous 3 secondes pour sentir la fin approcher.
func _format_status(instance: StatusInstance) -> String:
	var remaining: float = maxf(instance.remaining, 0.0)
	if remaining < 3.0:
		return "%s %.1fs" % [instance.data.display_name, remaining]
	return "%s %ds" % [instance.data.display_name, ceili(remaining)]


## Avec une illustration : on l'affiche (grisée si l'unité est morte).
## Sans : bloc arrondi de la couleur de l'unité avec son initiale.
func _refresh_body() -> void:
	var portrait: Texture2D = _unit.data.portrait
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_portrait.self_modulate = Color.WHITE if _unit.is_alive() else Color(0.35, 0.35, 0.4)
	_portrait.flip_h = (facing < 0.0) != _unit.data.portrait_faces_left
	_initial_label.visible = portrait == null
	if portrait:
		_sprite.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		_sprite.add_theme_stylebox_override("panel", _build_body_style())


func _build_body_style() -> StyleBoxFlat:
	var color: Color = _unit.data.color if _unit.is_alive() else _unit.data.color.darkened(DEAD_TINT)
	var style: StyleBoxFlat = UiStyle.box(color, BODY_RADIUS, color.darkened(0.45), 3)
	return UiStyle.with_shadow(style, Color(color, 0.25), 12)


func _health_color() -> Color:
	return UiStyle.HERO_HEALTH if _unit.side == CombatUnit.Side.HERO else UiStyle.MONSTER_HEALTH


# --- Effets des statuts -----------------------------------------------------

func _apply_status_visuals() -> void:
	var visuals: StatusVisuals = StatusVisuals.from_statuses(_unit.statuses.get_instances()) if _unit.is_alive() else StatusVisuals.new()
	_tween_scale(visuals.scale)
	_portrait.modulate = visuals.tint
	_shield.visible = visuals.has_shield
	_show_aura(visuals.aura)


func _reset_status_visuals() -> void:
	_tween_scale(1.0)
	_portrait.modulate = Color.WHITE
	_shield.hide()
	_show_aura(Color.TRANSPARENT)


func _tween_scale(target_scale: float) -> void:
	if is_equal_approx(_sprite.scale.x, target_scale) and _scale_tween == null:
		return
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(_sprite, "scale", Vector2.ONE * target_scale, SCALE_TWEEN_DURATION)
	_scale_tween.finished.connect(func() -> void: _scale_tween = null)


## Aura colorée qui pulse derrière l'unité ; transparente = pas d'aura.
func _show_aura(color: Color) -> void:
	if color.a == 0.0:
		_aura.hide()
		if _aura_tween:
			_aura_tween.kill()
			_aura_tween = null
		return
	_aura.add_theme_stylebox_override("panel", _build_aura_style(color))
	if _aura_tween == null:
		_aura.show()
		_aura_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		_aura_tween.tween_property(_aura, "modulate:a", 0.45, AURA_PULSE_DURATION / 2.0)
		_aura_tween.tween_property(_aura, "modulate:a", 1.0, AURA_PULSE_DURATION / 2.0)


func _build_aura_style(color: Color) -> StyleBoxFlat:
	return UiStyle.with_shadow(UiStyle.box(Color(color, 0.18), AURA_RADIUS), Color(color, 0.6), 24)


func _build_shield_style() -> StyleBoxFlat:
	return UiStyle.with_shadow(UiStyle.box(Color(SHIELD_COLOR, 0.12), SHIELD_RADIUS, SHIELD_COLOR, 3), Color(SHIELD_COLOR, 0.45), 14)


## Anneau qui s'élargit et s'efface depuis le centre du sprite.
func _spawn_impact_ring(color: Color) -> void:
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2.ONE * IMPACT_SIZE
	ring.pivot_offset = ring.size / 2.0
	ring.position = _sprite.position + _sprite.size / 2.0 - ring.size / 2.0
	ring.scale = Vector2.ONE * 0.3
	ring.add_theme_stylebox_override("panel", UiStyle.with_shadow(UiStyle.box(Color(color, 0.15), int(IMPACT_SIZE), color, 4), Color(color, 0.7), 12))
	_sprite.get_parent().add_child(ring)
	var tween: Tween = ring.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2.ONE * IMPACT_MAX_SCALE, IMPACT_DURATION)
	tween.tween_property(ring, "modulate:a", 0.0, IMPACT_DURATION)
	tween.chain().tween_callback(ring.queue_free)


# --- Animations -------------------------------------------------------------

## Léger mouvement de respiration, décalé au hasard pour que les unités ne bougent pas en rythme.
func _start_idle_bob() -> void:
	var duration: float = randf_range(BOB_MIN_DURATION, BOB_MAX_DURATION)
	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "position:y", -BOB_HEIGHT, duration / 2.0)
	tween.tween_property(_sprite, "position:y", 0.0, duration / 2.0)


func _play_lunge() -> void:
	if _lunge_tween:
		_lunge_tween.kill()
	_sprite.position.x = 0.0
	_lunge_tween = create_tween()
	_lunge_tween.tween_property(_sprite, "position:x", LUNGE_DISTANCE * facing, LUNGE_DURATION)
	_lunge_tween.tween_property(_sprite, "position:x", 0.0, LUNGE_DURATION)


func _play_hit_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_sprite.modulate = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, FLASH_DURATION)


func _spawn_text(text: String, color: Color) -> void:
	FloatingText.spawn(_float_anchor, text, color)


# --- Réactions --------------------------------------------------------------

func _on_health_changed(_current: float, _maximum: float) -> void:
	_refresh_health()


func _on_damaged(amount: float, is_critical: bool) -> void:
	var text: String = "-%d" % ceili(amount)
	_spawn_text(text + "!" if is_critical else text, CRITICAL_COLOR if is_critical else DAMAGE_COLOR)
	_play_hit_flash()


func _on_healed(amount: float) -> void:
	_spawn_text("+%d" % ceili(amount), HEAL_COLOR)


func _on_attack_avoided(reason: String) -> void:
	_spawn_text(reason, INFO_COLOR)
