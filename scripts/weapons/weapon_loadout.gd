class_name WeaponLoadout
extends RefCounted
## Run-owned firearm slots; magazines live in their individual instances.

signal changed

const SLOT_1 := 1
const SLOT_2 := 2
const STARTING_PISTOL := preload("res://assets/weapons/pistol.tres")
var _starting: WeaponDef
var _slots: Dictionary[int, WeaponInstance] = {}
var _active_slot := 0
var _notifying := false
var active_slot: int:
	get: return _active_slot
var active_weapon: WeaponInstance:
	get: return weapon_at(_active_slot)

func _init(starting: WeaponDef = STARTING_PISTOL) -> void:
	_starting = starting
	reset()

func weapon_at(slot: int) -> WeaponInstance:
	return _slots.get(slot)

func can_unlock(slot: int, definition: WeaponDef) -> bool:
	if _notifying or (slot != SLOT_1 and slot != SLOT_2) or _slots.has(slot) \
		or definition == null or not definition.is_valid():
		return false
	for owned in _slots.values():
		if owned.definition.weapon_id == definition.weapon_id:
			return false
	return true

func unlock(slot: int, definition: WeaponDef) -> bool:
	if not can_unlock(slot, definition):
		return false
	_slots[slot] = WeaponInstance.new(definition)
	if _active_slot == 0:
		_active_slot = slot
	_notify()
	return true

func can_equip(slot: int) -> bool:
	return not _notifying and slot != _active_slot and _slots.has(slot)

func equip(slot: int) -> bool:
	if not can_equip(slot):
		return false
	_active_slot = slot
	_notify()
	return true

func reset() -> void:
	if _notifying:
		return
	_slots.clear()
	_active_slot = 0
	if _starting != null and _starting.is_valid():
		_slots[SLOT_1] = WeaponInstance.new(_starting)
		_active_slot = SLOT_1
	_notify()

func _notify() -> void:
	_notifying = true
	changed.emit()
	_notifying = false
