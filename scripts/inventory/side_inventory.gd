class_name SideInventory
extends RefCounted

signal changed

const DEFAULT_CAPACITY := 6
const MAX_QUANTITY := 9223372036854775807
var _capacity: int
var capacity: int:
	get: return _capacity
var _catalog: ItemCatalog
var _initial: Dictionary[StringName, int]
var _stacks: Array[InventoryStack] = []
var _notifying := false

func _init(slots: int = DEFAULT_CAPACITY, catalog: ItemCatalog = null,
		initial: Dictionary[StringName, int] = {}) -> void:
	_capacity = maxi(0, slots)
	_catalog = catalog if catalog != null else ItemCatalog.new()
	_initial = initial.duplicate()
	reset()

func occupied_slots() -> int:
	return _stacks.size()

func definition_for(id: StringName) -> ItemDef:
	return _catalog.definition_for(id)

func count(id: StringName) -> int:
	var total := 0
	for stack in _stacks:
		if stack.definition.item_id == id:
			total += stack.quantity
	return total

# These are detached values in slot order; callers cannot mutate a live stack.
func stack_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for stack in _stacks:
		rows.append({"id": stack.definition.item_id, "name": stack.definition.display_name,
			"quantity": stack.quantity})
	return rows

func can_add(id: StringName, quantity: int) -> bool:
	return quantity > 0 and _accepted_quantity(definition_for(id), quantity) == quantity

func _accepted_quantity(definition: ItemDef, requested: int) -> int:
	if definition == null or requested <= 0:
		return 0
	var limit := mini(requested, MAX_QUANTITY - count(definition.item_id))
	if limit <= 0:
		return 0
	var remaining := limit
	for stack in _stacks:
		if stack.definition.item_id == definition.item_id:
			remaining -= mini(remaining, definition.max_stack - stack.quantity)
			if remaining == 0:
				return limit
	# Multiply only when free slots cannot hold the remainder, so it cannot overflow.
	@warning_ignore("integer_division")
	var required_slots := 1 + (remaining - 1) / definition.max_stack
	var free_slots := _capacity - occupied_slots()
	if free_slots >= required_slots:
		return limit
	return limit - remaining + free_slots * definition.max_stack

func add(id: StringName, quantity: int) -> bool:
	if _notifying or not can_add(id, quantity):
		return false
	_insert(definition_for(id), quantity)
	_notify()
	return true

func can_remove(id: StringName, quantity: int) -> bool:
	return quantity > 0 and count(id) >= quantity

func remove(id: StringName, quantity: int) -> bool:
	if _notifying or not can_remove(id, quantity):
		return false
	_withdraw(id, quantity)
	_notify()
	return true

## Moves as much as fits. If source_slot is supplied, only that stack is used.
func transfer_to(destination: SideInventory, id: StringName, requested: int, source_slot: int = -1) -> int:
	if destination == null or destination == self or requested <= 0 or _notifying or destination._notifying:
		return 0
	var source_def := definition_for(id)
	var destination_def := destination.definition_for(id)
	if source_def == null or not source_def.is_compatible_with(destination_def):
		return 0
	var available: int
	if source_slot == -1:
		available = count(id)
	elif source_slot >= 0 and source_slot < _stacks.size() and _stacks[source_slot].definition.item_id == id:
		available = _stacks[source_slot].quantity
	else:
		return 0
	var moved := destination._accepted_quantity(destination_def, mini(requested, available))
	if moved == 0:
		return 0
	# Commit both sides before notifying either. Keep both locked until all callbacks finish.
	_notifying = true
	destination._notifying = true
	_withdraw(id, moved, source_slot)
	destination._insert(destination_def, moved)
	changed.emit()
	destination.changed.emit()
	destination._notifying = false
	_notifying = false
	return moved

func _withdraw(id: StringName, quantity: int, source_slot: int = -1) -> void:
	var remaining := quantity
	var first := _stacks.size() - 1 if source_slot == -1 else source_slot
	for i in range(first, -1, -1):
		var stack := _stacks[i]
		if stack.definition.item_id != id:
			continue
		var removed := mini(stack.quantity, remaining)
		stack.quantity -= removed
		remaining -= removed
		if stack.quantity == 0:
			_stacks.remove_at(i)
		if remaining == 0:
			break

func clear() -> void:
	if not _notifying and not _stacks.is_empty():
		_stacks.clear()
		_notify()

# Stage a fresh loadout. Invalid initial contents leave the previous state intact.
func reset() -> bool:
	if _notifying:
		return false
	var previous := _stacks
	var previous_rows := stack_rows()
	_stacks = []
	for id in _initial:
		if not can_add(id, _initial[id]):
			_stacks = previous
			return false
		_insert(definition_for(id), _initial[id])
	if previous_rows != stack_rows():
		_notify()
	return true

func _insert(definition: ItemDef, quantity: int) -> void:
	var remaining := quantity
	for stack in _stacks:
		if stack.definition.item_id == definition.item_id:
			var merged := mini(remaining, definition.max_stack - stack.quantity)
			stack.quantity += merged
			remaining -= merged
			if remaining == 0:
				return
	while remaining > 0:
		var units := mini(remaining, definition.max_stack)
		_stacks.append(InventoryStack.new(definition, units))
		remaining -= units

func _notify() -> void:
	# Listeners read committed state. Reject reentrant mutations during notification.
	_notifying = true
	changed.emit()
	_notifying = false
