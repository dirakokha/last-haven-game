extends CanvasLayer

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		$Caption.visible = get_tree().paused
		get_viewport().set_input_as_handled()
