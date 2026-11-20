class_name LootContainerDef
extends Resource
## Deterministic starting contents. Runtime stock never writes to this resource.

@export var definition_id: StringName
@export var capacity: int = 4
@export var entries: Array[LootEntryDef] = []

# Compare exact authored values, not a resource pointer or a hash. Entry order
# matters because it defines the starting slot order shown in Loot.
func configuration_signature(catalog: ItemCatalog) -> Array:
	var id_pattern := RegEx.create_from_string("\\A[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?)*\\z")
	if id_pattern.search(definition_id) == null or capacity <= 0 or catalog == null or not catalog.is_valid():
		return []
	var signature: Array = [capacity]
	var seen: Dictionary[StringName, bool] = {}
	var slots_left := capacity
	for entry in entries:
		if entry == null or not entry.is_valid() or seen.has(entry.item.item_id):
			return []
		var id := entry.item.item_id
		if not entry.item.is_compatible_with(catalog.definition_for(id)):
			return []
		@warning_ignore("integer_division")
		var required_slots := 1 + (entry.quantity - 1) / entry.item.max_stack
		if required_slots > slots_left:
			return []
		slots_left -= required_slots
		seen[id] = true
		signature.append([id, entry.quantity, entry.item.category, entry.item.max_stack])
	return signature

func create_inventory(catalog: ItemCatalog) -> SideInventory:
	if configuration_signature(catalog).is_empty():
		return null
	var initial: Dictionary[StringName, int] = {}
	for entry in entries:
		initial[entry.item.item_id] = entry.quantity
	return SideInventory.new(capacity, catalog, initial)
