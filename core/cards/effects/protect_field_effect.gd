class_name ProtectFieldEffect
extends CardEffect
## Rend le terrain inciblable par les autres joueurs, et peut cacher sa progression.

@export var duration: float = 10.0
@export var hides_progress: bool = false


func apply(context: CardContext) -> void:
	context.target_field.protect(duration, hides_progress)
