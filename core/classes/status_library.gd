class_name StatusLibrary
extends RefCounted
## Tous les statuts du jeu. Les valeurs sont des premiers réglages d'équilibrage.

const BUFF := StatusData.Category.BUFF
const DEBUFF := StatusData.Category.DEBUFF
const CONTROL := StatusData.Category.CONTROL


static func _make(id: StringName, display_name: String, duration: float, category: StatusData.Category) -> StatusData:
	var status := StatusData.new()
	status.id = id
	status.display_name = display_name
	status.duration = duration
	status.category = category
	return status


# --- Dégâts sur la durée ----------------------------------------------------

static func bleed(damage_per_second: float = 3.0, duration: float = 6.0) -> StatusData:
	var status: StatusData = _make(&"bleed", "Saignement", duration, DEBUFF)
	status.damage_per_second = damage_per_second
	status.heal_received_mult = 0.5
	return status


static func burn() -> StatusData:
	var status: StatusData = _make(&"burn", "Brûlure", 4.0, DEBUFF)
	status.damage_per_second = 4.0
	return status


static func poison(damage_per_second: float = 2.0, duration: float = 5.0) -> StatusData:
	var status: StatusData = _make(&"poison", "Poison", duration, DEBUFF)
	status.damage_per_second = damage_per_second
	return status


# --- Débuffs et contrôles ---------------------------------------------------

static func frost() -> StatusData:
	var status: StatusData = _make(&"frost", "Givre", 5.0, DEBUFF)
	status.attack_speed_mult = 0.6
	return status


static func root() -> StatusData:
	var status: StatusData = _make(&"root", "Enracinement", 5.0, DEBUFF)
	status.attack_speed_mult = 0.5
	return status


static func blind() -> StatusData:
	var status: StatusData = _make(&"blind", "Aveuglement", 4.0, CONTROL)
	status.flags = StatusData.Flag.BLIND
	return status


static func smoke() -> StatusData:
	var status: StatusData = _make(&"smoke", "Fumée", 2.5, CONTROL)
	status.flags = StatusData.Flag.BLIND
	return status


## L'unité ne peut plus attaquer pendant la durée.
static func trip() -> StatusData:
	var status: StatusData = _make(&"trip", "Croc-en-jambe", 2.0, CONTROL)
	status.flags = StatusData.Flag.STUN
	return status


## L'unité subit plus de dégâts (de toutes les sources sauf les dégâts imblocables).
static func hunter_mark() -> StatusData:
	var status: StatusData = _make(&"hunter_mark", "Marque du chasseur", 8.0, DEBUFF)
	status.damage_taken_mult = 1.3
	return status


## Le météore tombe à la fin du statut. Une dissipation l'annule.
static func meteor(damage: float, delay: float) -> StatusData:
	var status: StatusData = _make(&"meteor", "Météore", delay, DEBUFF)
	status.damage_on_expire = damage
	return status


static func slow() -> StatusData:
	var status: StatusData = _make(&"slow", "Ralenti", 6.0, DEBUFF)
	status.attack_speed_mult = 0.7
	return status


# --- Défensifs --------------------------------------------------------------

static func shield() -> StatusData:
	var status: StatusData = _make(&"shield", "Bouclier", 4.0, BUFF)
	status.flags = StatusData.Flag.DAMAGE_IMMUNE
	return status


static func arcane_barrier() -> StatusData:
	var status: StatusData = _make(&"arcane_barrier", "Barrière arcanique", 10.0, BUFF)
	status.shield_amount = 35.0
	return status


static func yggdrasil() -> StatusData:
	var status: StatusData = _make(&"yggdrasil", "Yggdrasil", 5.0, BUFF)
	status.flags = StatusData.Flag.DAMAGE_IMMUNE
	return status


static func decoy() -> StatusData:
	var status: StatusData = _make(&"decoy", "Leurre", 15.0, BUFF)
	status.flags = StatusData.Flag.DODGE_NEXT
	return status


static func evasion() -> StatusData:
	var status: StatusData = _make(&"evasion", "Esquive", 3.0, BUFF)
	status.flags = StatusData.Flag.DODGE_ALL
	return status


static func trap() -> StatusData:
	var status: StatusData = _make(&"trap", "Trappe", 5.0, BUFF)
	status.flags = StatusData.Flag.REFLECT
	return status


static func stone_skin() -> StatusData:
	var status: StatusData = _make(&"stone_skin", "Peau de pierre", 8.0, BUFF)
	status.damage_taken_mult = 0.7
	return status


static func strength() -> StatusData:
	var status: StatusData = _make(&"strength", "Force", 10.0, BUFF)
	status.damage_mult = 1.3
	return status


static func absolute_defense() -> StatusData:
	var status: StatusData = _make(&"absolute_defense", "Défense absolue", 6.0, BUFF)
	status.damage_taken_mult = 0.4
	return status


# --- Offensifs --------------------------------------------------------------

static func blessing() -> StatusData:
	var status: StatusData = _make(&"blessing", "Bénédiction", 8.0, BUFF)
	status.damage_mult = 1.5
	return status


static func haste() -> StatusData:
	var status: StatusData = _make(&"haste", "Hâte", 8.0, BUFF)
	status.attack_speed_mult = 1.6
	return status


static func crit_boost() -> StatusData:
	var status: StatusData = _make(&"crit_boost", "Critique +", 10.0, BUFF)
	status.crit_bonus = 0.4
	return status


static func poisoned_weapon() -> StatusData:
	var status: StatusData = _make(&"poisoned_weapon", "Arme empoisonnée", 10.0, BUFF)
	status.on_hit_status = poison()
	return status


static func berserk() -> StatusData:
	var status: StatusData = _make(&"berserk", "Berserker", 8.0, BUFF)
	status.flags = StatusData.Flag.CC_IMMUNE
	status.damage_mult = 1.6
	status.damage_taken_mult = 1.6
	return status


static func hack_away() -> StatusData:
	var status: StatusData = _make(&"hack_away", "Hachez-vous", 8.0, BUFF)
	status.attack_speed_mult = 0.6
	status.damage_mult = 2.0
	return status


static func dual_blades() -> StatusData:
	var status: StatusData = _make(&"dual_blades", "Double épées", 8.0, BUFF)
	status.attack_speed_mult = 1.4
	status.damage_mult = 1.2
	return status


static func gigantism() -> StatusData:
	var status: StatusData = _make(&"gigantism", "Gigantisme", 10.0, BUFF)
	status.damage_mult = 1.4
	status.max_health_mult = 1.5
	return status


# --- Soins ------------------------------------------------------------------

static func regrowth() -> StatusData:
	var status: StatusData = _make(&"regrowth", "Revitalisation", 8.0, BUFF)
	status.heal_per_second = 4.0
	return status


static func vitality_seed() -> StatusData:
	var status: StatusData = _make(&"vitality_seed", "Graine de vitalité", 20.0, BUFF)
	status.emergency_heal = 40.0
	return status


# --- Nécromancien -----------------------------------------------------------

static func unholy_frenzy() -> StatusData:
	var status: StatusData = _make(&"unholy_frenzy", "Frénésie impie", 8.0, BUFF)
	status.attack_speed_mult = 1.5
	status.damage_mult = 1.2
	return status


static func bone_armor() -> StatusData:
	var status: StatusData = _make(&"bone_armor", "Armure d'os", 8.0, BUFF)
	status.damage_taken_mult = 0.6
	return status


static func curse() -> StatusData:
	var status: StatusData = _make(&"curse", "Malédiction", 8.0, DEBUFF)
	status.damage_taken_mult = 1.4
	return status


# --- Marchand (équipements) -------------------------------------------------

static func sharpened_blade() -> StatusData:
	var status: StatusData = _make(&"sharpened_blade", "Lame affûtée", 15.0, BUFF)
	status.damage_mult = 1.5
	return status


static func plate_armor() -> StatusData:
	var status: StatusData = _make(&"plate_armor", "Armure de plates", 15.0, BUFF)
	status.damage_taken_mult = 0.6
	return status


static func swift_boots() -> StatusData:
	var status: StatusData = _make(&"swift_boots", "Bottes de célérité", 15.0, BUFF)
	status.attack_speed_mult = 1.5
	return status


static func bribed() -> StatusData:
	var status: StatusData = _make(&"bribed", "Soudoyé", 6.0, DEBUFF)
	status.damage_mult = 0.7
	status.attack_speed_mult = 0.6
	return status
