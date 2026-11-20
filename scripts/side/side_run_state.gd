class_name SideRunState
extends RefCounted

const KEY := &"side_run_state"
const STARTING_RESERVE := 36
var _inventory: SideInventory
var inventory: SideInventory:
	get: return _inventory
var _catalog: ItemCatalog
var _containers: Dictionary[StringName, SideInventory] = {}
var _collected: Dictionary[StringName, bool] = {}

func _init(catalog: ItemCatalog = null) -> void:
	_catalog = catalog if catalog != null else ItemCatalog.new()
	_inventory = SideInventory.new(SideInventory.DEFAULT_CAPACITY, _catalog,
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

func container_inventory(placement_id: StringName, definition: LootContainerDef) -> SideInventory:
	if placement_id == &"" or definition == null:
		return null
	if not _containers.has(placement_id):
		var contents := definition.create_inventory(_catalog)
		if contents == null:
			return null
		_containers[placement_id] = contents
	return _containers[placement_id]

func reset() -> bool:
	if not inventory.reset():
		return false
	for contents in _containers.values():
		if not contents.reset():
			return false
	_collected.clear()
	return true
