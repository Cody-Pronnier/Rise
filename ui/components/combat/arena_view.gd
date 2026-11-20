class_name ArenaView
extends PanelContainer
## Affiche un terrain : le héros (et ses compagnons) à gauche, le monstre courant à droite.
## Peut afficher n'importe quel terrain ; show_field() change simplement celui qui est observé.

signal unit_clicked(unit: CombatUnit)
## Clic sur le terrain hors d'une unité (pour les cartes qui visent un joueur ou un terrain).
signal arena_clicked
## La souris entre sur le personnage du terrain affiché (true) ou en sort (false).
signal character_hover_changed(is_hovered: bool)

const UNIT_VIEW_SCENE: PackedScene = preload("res://ui/components/combat/unit_view.tscn")

@onready var _owner_label: Label = %OwnerLabel
@onready var _state_label: Label = %StateLabel
@onready var _monster_counter_label: Label = %MonsterCounterLabel
@onready var _stage: Control = %Stage
@onready var _hidden_overlay: Control = %HiddenOverlay
@onready var _character_view: UnitView = %CharacterView
@onready var _companion_container: HBoxContainer = %CompanionContainer
@onready var _monster_view: UnitView = %MonsterView
@onready var _monster_companion_container: HBoxContainer = %MonsterCompanionContainer

var _field: Field
var _can_see_hidden: bool = false
var _is_targeting: bool = false
var _binder := SignalBinder.new()


func _ready() -> void:
	_character_view.clicked.connect(unit_clicked.emit)
	_character_view.mouse_entered.connect(character_hover_changed.emit.bind(true))
	_character_view.mouse_exited.connect(character_hover_changed.emit.bind(false))
	_monster_view.clicked.connect(unit_clicked.emit)


## title : texte d'en-tête (« Ton terrain », « Terrain de X »…).
## can_see_hidden : vrai pour son propre terrain et celui de son allié.
func show_field(field: Field, title: String, can_see_hidden: bool) -> void:
	_binder.clear()
	_field = field
	_can_see_hidden = can_see_hidden
	_owner_label.text = title
	_bind_field_signals()
	_character_view.bind(field.character)
	_refresh_monster()
	_rebuild_companions()
	_rebuild_monster_companions()
	_refresh_field_state()


## Effet visuel d'une carte jouée sur ce terrain : sur l'unité visée, ou sur tout le terrain.
func play_card_effect(card: CardData, target: CardTarget) -> void:
	var color: Color = CardPalette.class_color(card)
	for view: UnitView in _views_hit_by(card, target):
		view.play_card_burst(card.display_name, color)


func _views_hit_by(card: CardData, target: CardTarget) -> Array[UnitView]:
	var views: Array[UnitView] = []
	for view: UnitView in _get_unit_views():
		if view.visible and _is_hit(view, card, target):
			views.append(view)
	return views


func _is_hit(view: UnitView, card: CardData, target: CardTarget) -> bool:
	match card.target_mode:
		CardData.TargetMode.UNIT:
			return view.get_unit() == target.unit
		CardData.TargetMode.FIELD, CardData.TargetMode.ALL_FIELDS:
			return true
		_:
			return view == _character_view


## Met en surbrillance les unités cliquables pendant le choix d'une cible.
func set_targeting(enabled: bool) -> void:
	_is_targeting = enabled
	_refresh_targetable_views()


func _gui_input(event: InputEvent) -> void:
	if UiInput.is_left_click(event):
		arena_clicked.emit()
		accept_event()


func _bind_field_signals() -> void:
	_binder.bind(_field.monster_changed, _on_monster_changed)
	_binder.bind(_field.companions_changed, _rebuild_companions)
	_binder.bind(_field.monster_companions_changed, _rebuild_monster_companions)
	_binder.bind(_field.protection_changed, _refresh_field_state)
	_binder.bind(_field.finished, _refresh_field_state)


func _refresh_monster() -> void:
	_monster_view.bind(_field.current_monster)
	_monster_counter_label.text = _describe_monster_counter()
	_refresh_targetable_views()


func _rebuild_companions() -> void:
	_rebuild_unit_row(_companion_container, _field.companions, 1.0)


## Les compagnons du monstre regardent vers la gauche, comme lui.
func _rebuild_monster_companions() -> void:
	_rebuild_unit_row(_monster_companion_container, _field.monster_companions, -1.0)


func _rebuild_unit_row(container: HBoxContainer, units: Array[CombatUnit], facing: float) -> void:
	for view: Node in container.get_children():
		view.queue_free()
	for unit: CombatUnit in units:
		_add_unit_view(container, unit, facing)
	_refresh_targetable_views()


func _add_unit_view(container: HBoxContainer, unit: CombatUnit, facing: float) -> void:
	var view: UnitView = UNIT_VIEW_SCENE.instantiate()
	view.facing = facing
	container.add_child(view)
	view.bind(unit)
	view.clicked.connect(unit_clicked.emit)


func _refresh_field_state() -> void:
	var is_hidden: bool = _field.hides_progress() and not _can_see_hidden
	_stage.visible = not is_hidden
	_hidden_overlay.visible = is_hidden
	_state_label.text = _describe_field_state()
	_monster_counter_label.text = _describe_monster_counter()


func _refresh_targetable_views() -> void:
	for view: UnitView in _get_unit_views():
		view.set_targetable(_is_targeting)


func _get_unit_views() -> Array[UnitView]:
	var views: Array[UnitView] = [_character_view, _monster_view]
	for container: HBoxContainer in [_companion_container, _monster_companion_container]:
		for child: Node in container.get_children():
			if child is UnitView and not child.is_queued_for_deletion():
				views.append(child)
	return views


func _describe_monster_counter() -> String:
	if _field.is_finished():
		return "Manche terminée !"
	return "Monstre %d / %d" % [_field.kills + 1, CombatConfig.MONSTERS_PER_ROUND]


func _describe_field_state() -> String:
	if _field.hides_progress():
		return "Invisible"
	if _field.is_protected():
		return "Protégé"
	return ""


func _on_monster_changed(_monster: CombatUnit) -> void:
	_refresh_monster()
