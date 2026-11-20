class_name SideRunState
extends RefCounted

const KEY := &"side_run_state"
const STARTING_RESERVE := 36
var _inventory: SideInventory
var inventory: SideInventory:
	get: return _inventory
var _collected: Dictionary[StringName, bool] = {}

func _init(catalog: ItemCatalog = null) -> void:
	_inventory = SideInventory.new(SideInventory.DEFAULT_CAPACITY, catalog,
		{ItemCatalog.AMMO_9MM.item_id: STARTING_RESERVE})

# The SceneTree outlives its current room; nothing here is serialized.
static func for_tree(tree: SceneTree) -> SideRunState:
	if not tree.has_meta(KEY):
		tree.set_meta(KEY, SideRunState.new())
	return tree.get_meta(KEY) as SideRunState

func is_collected(placement_id: StringName) -> bool:
	return _collected.has(placement_id)

func record_collected(placement_id: StringName) -> void:
	_collected[placement_id] = true

func reset() -> bool:
	if not inventory.reset():
		return false
	_collected.clear()
	return true
