class_name SideRunState
extends RefCounted

const KEY := &"side_run_state"
const STARTING_RESERVE := 36
var _inventory: SideInventory
var inventory: SideInventory:
	get: return _inventory
var _catalog: ItemCatalog
var _containers: Dictionary[StringName, Dictionary] = {}
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
	if placement_id == &"":
		return null
	var signature := definition.configuration_signature(_catalog) if definition != null else []
	if signature.is_empty():
		var requested_id := definition.definition_id if definition != null else &""
		push_warning("Loot placement '%s' rejected invalid or catalog-incompatible definition '%s'." % [placement_id, requested_id])
		return null
	if _containers.has(placement_id):
		var registered: Dictionary = _containers[placement_id]
		if registered.definition_id != definition.definition_id or registered.signature != signature:
			push_warning("Loot placement '%s' already uses definition '%s'; requested '%s' does not match its ID or authored configuration." %
				[placement_id, registered.definition_id, definition.definition_id])
			return null
		return registered.inventory
	var contents := definition.create_inventory(_catalog)
	if contents == null:
		return null
	_containers[placement_id] = {"inventory": contents, "definition_id": definition.definition_id, "signature": signature}
	return contents

func reset() -> bool:
	if not inventory.reset():
		return false
	for registered in _containers.values():
		var contents: SideInventory = registered.inventory
		if not contents.reset():
			return false
	_collected.clear()
	return true
