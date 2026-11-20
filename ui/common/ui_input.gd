class_name UiInput
extends RefCounted
## Petits tests d'entrée partagés par les composants d'interface.


static func is_left_click(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	return mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT


static func is_cancel(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	var mouse_event := event as InputEventMouseButton
	return mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT
