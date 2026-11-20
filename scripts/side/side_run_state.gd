class_name SideRunState
extends RefCounted

const KEY := &"side_run_state"
var _collected: Dictionary[StringName, bool] = {}

# The SceneTree outlives its current room; nothing here is serialized.
static func for_tree(tree: SceneTree) -> SideRunState:
	if not tree.has_meta(KEY):
		tree.set_meta(KEY, SideRunState.new())
	return tree.get_meta(KEY) as SideRunState

func is_collected(placement_id: StringName) -> bool:
	return _collected.has(placement_id)

func record_collected(placement_id: StringName) -> void:
	_collected[placement_id] = true

func reset() -> void:
	_collected.clear()
