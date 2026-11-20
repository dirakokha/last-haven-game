class_name WeaponInstance
extends RefCounted
## One loaded magazine per instance. Reserve stock belongs to the actor.

var _definition: WeaponDef
var _magazine := 0
var definition: WeaponDef:
	get:
		return _definition
var magazine: int:
	get:
		return _magazine

## An invalid definition creates an inert instance with no loaded ammunition.
func _init(config: WeaponDef) -> void:
	if config != null and config.is_valid():
		_definition = config
		_magazine = config.magazine_capacity

func consume_round() -> bool:
	if _magazine == 0:
		return false
	_magazine -= 1
	return true

## Returns how many rounds were accepted; wrong ammo and nonpositive amounts are no-ops.
func load_rounds(ammo_id: StringName, amount: int) -> int:
	if _definition == null or ammo_id != _definition.ammo_id or amount <= 0:
		return 0
	var accepted := mini(amount, _definition.magazine_capacity - _magazine)
	_magazine += accepted
	return accepted

## Restore a value snapshot from the same definition; this does not spend reserve.
func restore_magazine(rounds: int) -> void:
	if _definition != null:
		_magazine = clampi(rounds, 0, _definition.magazine_capacity)
