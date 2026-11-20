class_name SummonOnFieldEffect
extends CardEffect
## Invoque une ou plusieurs unités aux côtés de l'unité ciblée, sur n'importe quel terrain :
## à côté d'un personnage ou d'un compagnon, elles se battent pour les héros ;
## à côté d'un monstre, elles se battent pour le monstre (et partent avec lui).
## Sans unité ciblée (carte jouée sur son terrain), elles rejoignent les héros.
## Une invocation échoue sans bruit si le camp est plein.

@export var companion: UnitData
@export var count: int = 1


func apply(context: CardContext) -> void:
	var for_monster: bool = not context.target_units.is_empty() and context.target_units[0].side == CombatUnit.Side.MONSTER
	for _index: int in count:
		if for_monster:
			context.target_field.add_monster_companion(companion)
		else:
			context.target_field.add_companion(companion)
