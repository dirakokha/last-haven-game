class_name SidePortal
extends SideInteractable

@export_file("*.tscn") var destination: String
@export var arrival: StringName
@export var entrance_text := "ورود"

func _init() -> void:
	input_action = &"side_entrance"

func interaction_prompt() -> String:
	return tr(entrance_text)

func _is_available(actor: SidePlayer) -> bool:
	var room := _room()
	return room != null and room.player == actor and ResourceLoader.exists(destination, "PackedScene")

func _activate(_actor: SidePlayer) -> bool:
	return _room().start_travel(destination, arrival)

func _room() -> SideRoom:
	var node := get_parent()
	while node != null and not node is SideRoom:
		node = node.get_parent()
	return node as SideRoom
