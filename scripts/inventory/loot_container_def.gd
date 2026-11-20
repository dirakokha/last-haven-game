class_name LootContainerDef
extends Resource
## Deterministic starting contents. Runtime stock never writes to this resource.

@export var capacity: int = 4
@export var entries: Array[LootEntryDef] = []

func create_inventory(catalog: ItemCatalog) -> SideInventory:
	if capacity <= 0 or catalog == null or not catalog.is_valid():
		return null
	var initial: Dictionary[StringName, int] = {}
	var slots_left := capacity
	for entry in entries:
		if entry == null or not entry.is_valid() or initial.has(entry.item.item_id):
			return null
		var id := entry.item.item_id
		if not entry.item.is_compatible_with(catalog.definition_for(id)):
			return null
		@warning_ignore("integer_division")
		var required_slots := 1 + (entry.quantity - 1) / entry.item.max_stack
		if required_slots > slots_left:
			return null
		slots_left -= required_slots
		initial[id] = entry.quantity
	return SideInventory.new(capacity, catalog, initial)
