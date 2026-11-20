class_name SideInteractable
extends Marker2D

const GROUP := &"side_interactables"

@export var placement_id: StringName
@export var prompt_text := ""
@export var input_action := &"side_interact"
@export var reach := 70.0
@export var vertical_tolerance := 16.0
@export var enabled := true

func _enter_tree() -> void:
	add_to_group(GROUP)

func interaction_prompt() -> String:
	return tr(prompt_text)

func horizontal_distance(actor: SidePlayer) -> float:
	return absf(actor.global_position.x - global_position.x)

func can_activate(actor: SidePlayer) -> bool:
	return enabled and placement_id != &"" and is_inside_tree() and not is_queued_for_deletion() \
		and InputMap.has_action(input_action) and not get_tree().paused and can_process() \
		and is_instance_valid(actor) and actor.is_inside_tree() and actor.get_tree() == get_tree() \
		and actor.can_process() and not actor.vitals.is_depleted() and actor.is_on_floor() \
		and horizontal_distance(actor) < reach \
		and absf(actor.global_position.y - global_position.y) < vertical_tolerance \
		and _is_available(actor)

# Recheck policy at the point of use. Subclasses implement only the local transaction.
func activate(actor: SidePlayer) -> bool:
	return can_activate(actor) and _activate(actor)

func _is_available(_actor: SidePlayer) -> bool:
	return false

func _activate(_actor: SidePlayer) -> bool:
	return false
