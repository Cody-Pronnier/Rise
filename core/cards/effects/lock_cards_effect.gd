class_name LockCardsEffect
extends CardEffect
## Empêche le joueur ciblé de jouer des cartes pendant un temps.
## freezes_mana : son mana ne se recharge plus non plus pendant ce temps.

@export var duration: float = 6.0
@export var freezes_mana: bool = false


func apply(context: CardContext) -> void:
	var boosted_duration: float = duration * context.power
	context.target_player.lock_cards(boosted_duration)
	if freezes_mana:
		context.target_player.freeze_mana(boosted_duration)
