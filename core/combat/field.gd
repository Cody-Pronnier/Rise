class_name Field
extends RefCounted
## Le terrain d'un joueur : son personnage (et ses compagnons) contre une file de 3 monstres.
## Le combat est entièrement automatique ; les cartes ne font que modifier les unités.
## Le passif de la classe (ClassPassive) peut changer certaines règles : personnage qui ne frappe
## pas, personnage protégé des cartes adverses, invocations automatiques, or…

signal monster_changed(monster: CombatUnit)
signal companions_changed
signal monster_companions_changed
signal progress_changed(progress: float)
signal protection_changed
signal finished

var owner_id: int
var character: CombatUnit
var companions: Array[CombatUnit] = []
## Compagnons invoqués du côté du monstre : ils attaquent les héros et partent avec le monstre.
var monster_companions: Array[CombatUnit] = []
## null pendant la pause entre deux monstres et quand les 3 monstres sont tombés.
var current_monster: CombatUnit
var kills: int = 0
## Nombre de monstres à vaincre sur ce terrain pendant la manche.
var total_monsters: int = 0
var passive: ClassPassive

## Compagnons que les monstres ne frappent jamais.
const UNTARGETED_BY_MONSTERS: Array[StringName] = [&"double"]

var _pending_monsters: Array[UnitData] = []
var _respawn_remaining: float = 0.0
var _breather_remaining: float = 0.0
var _protection_remaining: float = 0.0
var _hidden_remaining: float = 0.0


func _init(p_owner_id: int, character_data: UnitData, monsters: Array[UnitData], p_passive: ClassPassive = null) -> void:
	owner_id = p_owner_id
	character = CombatUnit.new(character_data, CombatUnit.Side.HERO)
	character.died.connect(_on_character_died)
	_pending_monsters = monsters.duplicate()
	total_monsters = monsters.size()
	_spawn_next_monster()
	passive = p_passive if p_passive else ClassPassive.new()
	passive.attach(self)


# --- Lecture ----------------------------------------------------------------

func is_finished() -> bool:
	return kills >= total_monsters


## 0 à 3 : nombre de monstres tués + fraction de PV retirée au monstre courant.
func get_progress() -> float:
	if current_monster == null:
		return float(kills)
	return kills + 1.0 - current_monster.get_health_ratio()


func get_heroes() -> Array[CombatUnit]:
	var heroes: Array[CombatUnit] = [character]
	heroes.append_array(companions)
	return heroes


## Le monstre en cours et ses compagnons.
func get_monster_side() -> Array[CombatUnit]:
	var monsters: Array[CombatUnit] = []
	if current_monster:
		monsters.append(current_monster)
	monsters.append_array(monster_companions)
	return monsters


## Le camp d'une unité sur ce terrain : personnage + compagnons, ou monstre + ses compagnons.
func get_side_of(unit: CombatUnit) -> Array[CombatUnit]:
	return get_heroes() if unit.side == CombatUnit.Side.HERO else get_monster_side()


func get_all_units() -> Array[CombatUnit]:
	var units: Array[CombatUnit] = get_heroes()
	units.append_array(get_monster_side())
	return units


func contains(unit: CombatUnit) -> bool:
	return get_all_units().has(unit)


## Identifiant d'une unité transmissible sur le réseau :
## "c" = personnage, "p0".."pN" = compagnons, "m2" = monstre courant (numéro = monstres déjà tués).
## Le numéro du monstre évite qu'une carte visant un monstre mort touche le suivant.
func ref_of(unit: CombatUnit) -> String:
	if unit == character:
		return "c"
	if unit == current_monster:
		return "m%d" % kills
	var companion_index: int = companions.find(unit)
	if companion_index != -1:
		return "p%d" % companion_index
	var monster_companion_index: int = monster_companions.find(unit)
	return "q%d" % monster_companion_index if monster_companion_index != -1 else ""


## Inverse de ref_of ; null si l'unité n'existe plus.
func unit_from_ref(ref: String) -> CombatUnit:
	if ref == "c":
		return character
	if ref.begins_with("m"):
		return current_monster if current_monster and ref.substr(1).to_int() == kills else null
	if ref.begins_with("p"):
		var index: int = ref.substr(1).to_int()
		return companions[index] if index >= 0 and index < companions.size() else null
	if ref.begins_with("q"):
		var monster_index: int = ref.substr(1).to_int()
		return monster_companions[monster_index] if monster_index >= 0 and monster_index < monster_companions.size() else null
	return null


func has_living_companions() -> bool:
	return companions.any(func(companion: CombatUnit) -> bool: return companion.is_alive())


func get_companions_tagged(tag: StringName) -> Array[CombatUnit]:
	var tagged: Array[CombatUnit] = []
	tagged.assign(companions.filter(func(companion: CombatUnit) -> bool: return companion.data.tag == tag and companion.is_alive()))
	return tagged


func has_mercenary() -> bool:
	return not get_companions_tagged(&"mercenary").is_empty()


func has_companion_slot() -> bool:
	return companions.size() < CombatConfig.MAX_COMPANIONS


## Les cartes des autres joueurs ne peuvent pas viser ce personnage (ex : Marchand avec mercenaire).
func is_character_shielded() -> bool:
	return passive.shields_character()


## Un terrain protégé ne peut pas être ciblé par les cartes des autres joueurs.
func is_protected() -> bool:
	return _protection_remaining > 0.0


## Un terrain caché ne montre pas sa progression aux autres joueurs.
func hides_progress() -> bool:
	return _hidden_remaining > 0.0


# --- Actions des cartes -----------------------------------------------------

func protect(duration: float, hide_progress: bool) -> void:
	_protection_remaining = maxf(_protection_remaining, duration)
	if hide_progress:
		_hidden_remaining = maxf(_hidden_remaining, duration)
	protection_changed.emit()


## Renvoie le compagnon créé, ou null si le terrain est plein.
func add_companion(companion_data: UnitData) -> CombatUnit:
	if not has_companion_slot():
		return null
	var companion := CombatUnit.new(companion_data, CombatUnit.Side.HERO)
	companion.died.connect(_on_companion_died.bind(companion))
	companions.append(companion)
	companions_changed.emit()
	return companion


## Retire des compagnons sans les faire mourir (fusion, mercenaire congédié).
func dismiss_companions(dismissed: Array[CombatUnit]) -> void:
	if dismissed.is_empty():
		return
	for companion: CombatUnit in dismissed:
		companions.erase(companion)
	companions_changed.emit()


## Compagnon qui se bat pour le monstre courant (ex : un loup invoqué sur l'orc).
func add_monster_companion(companion_data: UnitData) -> void:
	if current_monster == null or monster_companions.size() >= CombatConfig.MAX_COMPANIONS:
		return
	var companion := CombatUnit.new(companion_data, CombatUnit.Side.MONSTER)
	companion.died.connect(_on_monster_companion_died.bind(companion))
	monster_companions.append(companion)
	monster_companions_changed.emit()


# --- Simulation -------------------------------------------------------------

func tick(delta: float) -> void:
	if is_finished():
		return
	_tick_protection(delta)
	_tick_respawn(delta)
	_tick_breather(delta)
	passive.tick(delta)
	_tick_units(delta)
	_resolve_hero_attacks()
	_resolve_monster_attack()


func _tick_protection(delta: float) -> void:
	if not is_protected() and not hides_progress():
		return
	var was_protected: bool = is_protected()
	var was_hidden: bool = hides_progress()
	_protection_remaining = maxf(_protection_remaining - delta, 0.0)
	_hidden_remaining = maxf(_hidden_remaining - delta, 0.0)
	if was_protected != is_protected() or was_hidden != hides_progress():
		protection_changed.emit()


func _tick_respawn(delta: float) -> void:
	if character.is_alive():
		return
	_respawn_remaining -= delta
	if _respawn_remaining <= 0.0:
		character.revive()


## Pause entre deux monstres : le suivant arrive quand elle est écoulée.
func is_between_monsters() -> bool:
	return current_monster == null and not is_finished()


func _tick_breather(delta: float) -> void:
	if not is_between_monsters():
		return
	_breather_remaining -= delta
	if _breather_remaining <= 0.0:
		_spawn_next_monster()


func _tick_units(delta: float) -> void:
	for unit: CombatUnit in get_all_units():
		unit.tick(delta)


func _resolve_hero_attacks() -> void:
	for hero: CombatUnit in get_heroes():
		if current_monster == null:
			return
		if hero == character and not passive.character_can_attack():
			continue
		if hero.is_attack_ready():
			hero.perform_attack(current_monster)


## Le monstre et ses compagnons frappent chacun à leur rythme.
func _resolve_monster_attack() -> void:
	for companion: CombatUnit in monster_companions.duplicate():
		_resolve_monster_side_attack(companion)
	_resolve_monster_side_attack(current_monster)


func _resolve_monster_side_attack(attacker: CombatUnit) -> void:
	if attacker == null or not attacker.is_attack_ready():
		return
	var target: CombatUnit = _pick_monster_target()
	if target:
		attacker.perform_attack(target)


## Les compagnons servent de bouclier au personnage, sauf ceux qui restent en retrait
## (le double du Mage : seuls les autres joueurs peuvent l'abattre).
func _pick_monster_target() -> CombatUnit:
	for companion: CombatUnit in companions:
		if companion.is_alive() and not UNTARGETED_BY_MONSTERS.has(companion.data.tag):
			return companion
	return character if character.is_alive() else null


func _spawn_next_monster() -> void:
	current_monster = CombatUnit.new(_pending_monsters.pop_front(), CombatUnit.Side.MONSTER)
	current_monster.died.connect(_on_monster_died)
	current_monster.health_changed.connect(_on_monster_health_changed)
	monster_changed.emit(current_monster)
	progress_changed.emit(get_progress())


func _start_breather() -> void:
	current_monster = null
	_breather_remaining = CombatConfig.MONSTER_BREATHER_DURATION
	monster_changed.emit(null)
	progress_changed.emit(get_progress())


func _finish() -> void:
	current_monster = null
	monster_changed.emit(null)
	progress_changed.emit(get_progress())
	finished.emit()


func _on_monster_died() -> void:
	kills += 1
	_clear_monster_companions()
	if is_finished():
		_finish()
	else:
		_start_breather()


func _on_monster_health_changed(_current: float, _maximum: float) -> void:
	progress_changed.emit(get_progress())


func _on_character_died() -> void:
	_respawn_remaining = CombatConfig.RESPAWN_DELAY


func _on_companion_died(companion: CombatUnit) -> void:
	companions.erase(companion)
	companions_changed.emit()


func _on_monster_companion_died(companion: CombatUnit) -> void:
	monster_companions.erase(companion)
	monster_companions_changed.emit()


func _clear_monster_companions() -> void:
	if monster_companions.is_empty():
		return
	monster_companions.clear()
	monster_companions_changed.emit()
