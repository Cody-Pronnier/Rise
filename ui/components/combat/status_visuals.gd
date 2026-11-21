class_name StatusVisuals
extends RefCounted
## Traduit les statuts actifs d'une unité en effets visuels : taille, teinte, aura, bulle de bouclier.
## Tout est ici, côté interface : la simulation ne connaît pas ces réglages.

const AURA_GOLD := Color(1.0, 0.82, 0.3)
const AURA_GREEN := Color(0.45, 1.0, 0.45)
const AURA_RED := Color(1.0, 0.35, 0.3)
const AURA_BLUE := Color(0.45, 0.75, 1.0)
const AURA_PURPLE := Color(0.75, 0.45, 1.0)
const AURA_GREY := Color(0.75, 0.75, 0.8)

## Agrandissement du sprite.
const SCALES: Dictionary[StringName, float] = {
	&"gigantism": 1.35,
}

## Teintes multipliées entre elles (au-dessus de 1 = plus lumineux).
const TINTS: Dictionary[StringName, Color] = {
	&"berserk": Color(1.3, 0.7, 0.7),
	&"hack_away": Color(1.2, 0.8, 0.8),
	&"frost": Color(0.7, 0.85, 1.35),
	&"slow": Color(0.85, 0.85, 1.15),
	&"root": Color(0.8, 1.05, 0.7),
	&"poison": Color(0.75, 1.15, 0.7),
	&"burn": Color(1.3, 0.85, 0.6),
	&"bleed": Color(1.15, 0.75, 0.75),
	&"blind": Color(0.5, 0.5, 0.58),
	&"smoke": Color(0.6, 0.6, 0.65),
	&"stone_skin": Color(0.85, 0.85, 0.85),
	&"curse": Color(0.85, 0.7, 1.1),
	&"bribed": Color(1.15, 1.05, 0.7),
	&"hunter_mark": Color(1.25, 0.85, 0.8),
	&"trip": Color(0.85, 0.85, 0.9),
	&"meteor": Color(1.2, 0.9, 0.75),
}

## Statuts qui rendent l'unité semi-transparente (esquive).
const TRANSLUCENT_IDS: Array[StringName] = [&"evasion", &"decoy"]
const TRANSLUCENT_ALPHA: float = 0.55

## Aura derrière l'unité ; la première trouvée l'emporte.
const AURAS: Dictionary[StringName, Color] = {
	&"berserk": AURA_RED,
	&"blessing": AURA_GOLD,
	&"strength": AURA_GOLD,
	&"dual_blades": AURA_RED,
	&"hack_away": AURA_RED,
	&"haste": AURA_BLUE,
	&"crit_boost": AURA_PURPLE,
	&"trap": AURA_PURPLE,
	&"poisoned_weapon": AURA_GREEN,
	&"regrowth": AURA_GREEN,
	&"vitality_seed": AURA_GREEN,
	&"gigantism": AURA_GREEN,
	&"absolute_defense": AURA_GREY,
	&"stone_skin": AURA_GREY,
	&"unholy_frenzy": AURA_GREEN,
	&"bone_armor": AURA_GREY,
	&"curse": AURA_PURPLE,
	&"sharpened_blade": AURA_RED,
	&"plate_armor": AURA_GREY,
	&"swift_boots": AURA_BLUE,
	&"hunter_mark": AURA_RED,
	&"meteor": AURA_RED,
}

var scale: float = 1.0
var tint: Color = Color.WHITE
var aura: Color = Color.TRANSPARENT
var has_shield: bool = false


static func from_statuses(instances: Array[StatusInstance]) -> StatusVisuals:
	var visuals := StatusVisuals.new()
	for instance: StatusInstance in instances:
		visuals._add(instance.data)
	return visuals


func _add(status: StatusData) -> void:
	scale *= SCALES.get(status.id, 1.0)
	tint *= TINTS.get(status.id, Color.WHITE)
	if status.id in TRANSLUCENT_IDS:
		tint.a = TRANSLUCENT_ALPHA
	if aura.a == 0.0 and AURAS.has(status.id):
		aura = AURAS[status.id]
	if status.has_flag(StatusData.Flag.DAMAGE_IMMUNE) or status.shield_amount > 0.0:
		has_shield = true
