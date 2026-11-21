class_name CombatUnit
extends RefCounted
## Un combattant en simulation pure (aucun nœud).
## Les vues écoutent ses signaux ; elles ne modifient jamais son état.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, is_critical: bool)
signal healed(amount: float)
## Attaque esquivée, bloquée, renvoyée ou ratée (aveuglement).
signal attack_avoided(reason: String)
signal attacked
signal died
signal revived
signal statuses_changed

enum Side { HERO, MONSTER }

var data: UnitData
var side: Side
var health: float
var statuses: StatusContainer = StatusContainer.new()

var _attack_cooldown: float
var _known_max_health: float
var _pending_periodic_damage: float = 0.0
var _pending_periodic_heal: float = 0.0


## p_side est typé int pour contourner un bug de l'analyseur GDScript avec les enums
## dans les références cycliques entre classes. Passe CombatUnit.Side.HERO ou MONSTER.
func _init(p_data: UnitData, p_side: int) -> void:
	data = p_data
	side = p_side as Side
	health = p_data.max_health
	_known_max_health = p_data.max_health
	_attack_cooldown = p_data.attack_interval
	statuses.changed.connect(_on_statuses_changed)


# --- Lecture ----------------------------------------------------------------

func is_alive() -> bool:
	return health > 0.0


func get_max_health() -> float:
	return data.max_health * statuses.max_health_multiplier()


func get_health_ratio() -> float:
	return health / get_max_health()


func get_attack_interval() -> float:
	return data.attack_interval / maxf(statuses.attack_speed_multiplier(), CombatConfig.MIN_ATTACK_SPEED_MULTIPLIER)


func is_attack_ready() -> bool:
	return is_alive() and _attack_cooldown <= 0.0


# --- Simulation -------------------------------------------------------------

func tick(delta: float) -> void:
	if not is_alive():
		return
	statuses.tick(delta)
	_apply_expired_damage()
	_tick_periodic_damage(delta)
	_tick_periodic_heal(delta)
	if not statuses.has_flag(StatusData.Flag.STUN):
		_attack_cooldown -= delta


func perform_attack(target: CombatUnit) -> void:
	_attack_cooldown = get_attack_interval()
	attacked.emit()
	if statuses.has_flag(StatusData.Flag.BLIND):
		attack_avoided.emit("Aveuglé")
		return
	target.receive_damage(DamageCalculator.build_attack(self))


func receive_damage(info: DamageInfo) -> void:
	if not is_alive() or _try_avoid(info) or _try_reflect(info):
		return
	var amount: float = _absorb_with_shields(DamageCalculator.incoming_amount(self, info), info)
	if amount <= 0.0:
		attack_avoided.emit("Absorbé")
		return
	_lose_health(amount, info.is_critical)
	_apply_on_hit_statuses(info)
	_try_emergency_heal()


func receive_heal(amount: float) -> void:
	if not is_alive():
		return
	var effective: float = amount * statuses.heal_received_multiplier()
	var previous: float = health
	health = minf(health + effective, get_max_health())
	if health > previous:
		healed.emit(health - previous)
		health_changed.emit(health, get_max_health())


func apply_status(status: StatusData) -> bool:
	if not is_alive():
		return false
	return statuses.add(status)


func purge(categories: Array[int]) -> void:
	statuses.remove_categories(categories)


func revive() -> void:
	statuses.clear()
	health = get_max_health()
	_attack_cooldown = data.attack_interval
	health_changed.emit(health, get_max_health())
	revived.emit()


# --- Interne ----------------------------------------------------------------

func _try_avoid(info: DamageInfo) -> bool:
	if not info.undodgeable and statuses.has_flag(StatusData.Flag.DODGE_ALL):
		attack_avoided.emit("Esquive")
		return true
	if not info.undodgeable and statuses.consume_flag(StatusData.Flag.DODGE_NEXT):
		attack_avoided.emit("Leurre")
		return true
	if not info.unblockable and statuses.has_flag(StatusData.Flag.DAMAGE_IMMUNE):
		attack_avoided.emit("Bloqué")
		return true
	return false


## Les boucliers (Barrière arcanique…) absorbent les dégâts, sauf les dégâts imblocables.
func _absorb_with_shields(amount: float, info: DamageInfo) -> float:
	return amount if info.unblockable else statuses.absorb(amount)


## Dégâts des statuts arrivés à terme (Météore). Un sort : il peut être esquivé ou bloqué.
func _apply_expired_damage() -> void:
	var amount: float = statuses.take_expired_damage()
	if amount > 0.0:
		receive_damage(DamageCalculator.build_spell(amount, false, false))


func _try_reflect(info: DamageInfo) -> bool:
	if not statuses.has_flag(StatusData.Flag.REFLECT) or not info.can_be_reflected_by(self):
		return false
	info.reflectable = false
	attack_avoided.emit("Renvoyé")
	info.source.receive_damage(info)
	return true


func _lose_health(amount: float, is_critical: bool) -> void:
	if amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, is_critical)
	health_changed.emit(health, get_max_health())
	if not is_alive():
		died.emit()


func _apply_on_hit_statuses(info: DamageInfo) -> void:
	for status: StatusData in info.on_hit_statuses:
		apply_status(status)


func _try_emergency_heal() -> void:
	if not is_alive() or get_health_ratio() >= CombatConfig.EMERGENCY_HEALTH_RATIO:
		return
	var amount: float = statuses.consume_emergency_heal()
	if amount > 0.0:
		receive_heal(amount)


## Les dégâts sur la durée s'accumulent et ne sont appliqués que par point entier,
## pour ne pas émettre un signal à chaque image.
func _tick_periodic_damage(delta: float) -> void:
	var per_second: float = statuses.damage_per_second()
	if per_second <= 0.0 or statuses.has_flag(StatusData.Flag.DAMAGE_IMMUNE):
		_pending_periodic_damage = 0.0
		return
	_pending_periodic_damage += per_second * delta
	if _pending_periodic_damage < 1.0:
		return
	var amount: float = floorf(_pending_periodic_damage)
	_pending_periodic_damage -= amount
	_lose_health(amount, false)
	_try_emergency_heal()


func _tick_periodic_heal(delta: float) -> void:
	var per_second: float = statuses.heal_per_second()
	if per_second <= 0.0:
		_pending_periodic_heal = 0.0
		return
	_pending_periodic_heal += per_second * delta
	if _pending_periodic_heal < 1.0:
		return
	var amount: float = floorf(_pending_periodic_heal)
	_pending_periodic_heal -= amount
	receive_heal(amount)


## Quand les PV max augmentent (Gigantisme), l'unité gagne la différence ; quand ils baissent, on plafonne.
func _sync_max_health() -> void:
	var new_max: float = get_max_health()
	if is_equal_approx(new_max, _known_max_health):
		return
	if is_alive() and new_max > _known_max_health:
		health += new_max - _known_max_health
	health = minf(health, new_max)
	_known_max_health = new_max
	health_changed.emit(health, new_max)


func _on_statuses_changed() -> void:
	_sync_max_health()
	statuses_changed.emit()
