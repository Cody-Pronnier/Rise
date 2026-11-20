class_name UnitData
extends Resource
## Statistiques de base d'un combattant (personnage, compagnon ou monstre).

@export var display_name: String = ""
@export var max_health: float = 100.0
@export var attack_damage: float = 5.0
## Secondes entre deux attaques.
@export var attack_interval: float = 1.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
## Couleur du placeholder tant qu'il n'y a pas de sprite.
@export var color: Color = Color.WHITE
## Illustration de l'unité ; si absente, l'UI affiche un bloc de couleur avec l'initiale.
@export var portrait: Texture2D
## Sens du dessin : les héros regardent à droite, les monstres à gauche. L'UI retourne l'image au besoin.
@export var portrait_faces_left: bool = false
## Rôle d'une invocation (ex : &"minion" pour le Nécromancien, &"mercenary" pour le Marchand).
@export var tag: StringName = &""


static func create(
	p_name: String,
	p_max_health: float,
	p_attack_damage: float,
	p_attack_interval: float,
	p_crit_chance: float,
	p_color: Color,
	p_portrait: Texture2D = null
) -> UnitData:
	var data := UnitData.new()
	data.display_name = p_name
	data.max_health = p_max_health
	data.attack_damage = p_attack_damage
	data.attack_interval = p_attack_interval
	data.crit_chance = p_crit_chance
	data.color = p_color
	data.portrait = p_portrait
	return data


func scaled(multiplier: float) -> UnitData:
	var copy: UnitData = UnitData.create(
		display_name,
		max_health * multiplier,
		attack_damage * multiplier,
		attack_interval,
		crit_chance,
		color,
		portrait
	)
	copy.portrait_faces_left = portrait_faces_left
	copy.tag = tag
	return copy


func with_tag(p_tag: StringName) -> UnitData:
	tag = p_tag
	return self
