class_name LockCardsEffect
extends CardEffect
## Empêche le joueur ciblé de jouer des cartes pendant un temps.

@export var duration: float = 6.0


func apply(context: CardContext) -> void:
	context.target_player.lock_cards(duration * context.power)
