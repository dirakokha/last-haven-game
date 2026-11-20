class_name SideLootContainer
extends SideInteractable

@export var definition: LootContainerDef
var contents: SideInventory:
	get: return _contents
var _contents: SideInventory

func _ready() -> void:
	_contents = SideRunState.for_tree(get_tree()).container_inventory(placement_id, definition)

func _is_available(actor: SidePlayer) -> bool:
	var room := _room()
	return _contents != null and room != null and room.player == actor \
		and is_finite(reach) and reach > 0.0 and is_finite(vertical_tolerance) and vertical_tolerance > 0.0

func _activate(actor: SidePlayer) -> bool:
	return _room().open_loot(actor, _contents)

func _room() -> SideRoom:
	var node := get_parent()
	while node != null and not node is SideRoom:
		node = node.get_parent()
	return node as SideRoom
