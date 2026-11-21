class_name CardData
extends Resource
## Définition d'une carte : qui elle peut cibler et la liste d'effets qu'elle déclenche.

enum TargetMode {
	UNIT,    ## Un personnage, un compagnon ou un monstre, sur n'importe quel terrain.
	PLAYER,  ## Un joueur (ex : bloquer ses cartes).
	FIELD,   ## Toutes les unités d'un terrain.
	SELF,    ## Son propre terrain, sans choix de cible.
	ALL_FIELDS,  ## Tous les terrains en jeu, sans choix de cible (voir CardPlayService.affected_field_ids).
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var class_id: StringName
@export var target_mode: TargetMode = TargetMode.UNIT
@export var is_ultimate: bool = false
## Mana à dépenser pour jouer la carte.
@export var cost: int = 3
## Indique aux bots si la carte sert plutôt à aider (soin, buff) ou à gêner.
@export var is_beneficial: bool = false
@export var effects: Array[CardEffect] = []


## Vrai pour les cartes qui partent sans choix de cible (son terrain, ou tous les terrains).
## Pour déclarer le coût en fin de ligne : CardFactory.card(...).with_cost(2).
func with_cost(value: int) -> CardData:
	cost = value
	return self


func is_played_without_target() -> bool:
	return target_mode == TargetMode.SELF or target_mode == TargetMode.ALL_FIELDS


func resolve(context: CardContext) -> void:
	for effect: CardEffect in effects:
		effect.apply(context)


func describe_target() -> String:
	match target_mode:
		TargetMode.UNIT:
			return "Cible : une unité"
		TargetMode.PLAYER:
			return "Cible : un joueur"
		TargetMode.FIELD:
			return "Cible : tout un terrain"
		TargetMode.ALL_FIELDS:
			return "Cible : tous les terrains"
		_:
			return "Cible : ton terrain"
