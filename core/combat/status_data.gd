class_name StatusData
extends Resource
## Définition d'un effet temporaire (buff, débuff ou contrôle) appliqué à une unité.
## Les multiplicateurs valent 1.0 quand ils n'ont pas d'effet.

enum Category { BUFF, DEBUFF, CONTROL }

enum Flag {
	BLIND = 1,          ## N'inflige plus de dégâts en attaquant.
	DAMAGE_IMMUNE = 2,  ## Ne reçoit plus de dégâts (sauf « imblocable »).
	DODGE_NEXT = 4,     ## Esquive la prochaine attaque puis disparaît.
	DODGE_ALL = 8,      ## Esquive toutes les attaques pendant la durée.
	CC_IMMUNE = 16,     ## Insensible aux statuts de catégorie CONTROL.
	REFLECT = 32,       ## Renvoie les dégâts d'attaque vers l'attaquant.
}

@export var id: StringName
@export var display_name: String = ""
@export var duration: float = 5.0
@export var category: Category = Category.BUFF
@export_flags("Aveuglement", "Immunité dégâts", "Esquive prochaine", "Esquive totale", "Immunité CC", "Renvoi") var flags: int = 0

@export_group("Multiplicateurs")
@export var damage_mult: float = 1.0
@export var attack_speed_mult: float = 1.0
@export var damage_taken_mult: float = 1.0
@export var heal_received_mult: float = 1.0
@export var max_health_mult: float = 1.0

@export_group("Bonus")
@export var crit_bonus: float = 0.0
@export var damage_per_second: float = 0.0
@export var heal_per_second: float = 0.0
## Soin déclenché une seule fois quand l'unité passe sous le seuil critique.
@export var emergency_heal: float = 0.0
## Statut appliqué à chaque cible touchée par les attaques du porteur (ex : arme empoisonnée).
@export var on_hit_status: StatusData


func has_flag(flag: int) -> bool:
	return (flags & flag) != 0


func is_control() -> bool:
	return category == Category.CONTROL
