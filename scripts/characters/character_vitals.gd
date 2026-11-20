class_name CharacterVitals
extends RefCounted
## Per-character runtime health. Owns no scene, input, or combat policy.
## Health notifications are synchronous; listeners may read but not mutate vitals
## during a notification. An explicit reset starts a new life; healing never does.

signal health_changed(previous: int, current: int)
signal depleted

var _max_health: int
var _starting_health: int
var _health: int
var _notifying := false

var max_health: int:
	get:
		return _max_health
var health: int:
	get:
		return _health

## Capacity is at least one; starting health is clamped to the valid range.
func _init(capacity: int, starting_health: int) -> void:
	_max_health = maxi(1, capacity)
	_starting_health = clampi(starting_health, 0, _max_health)
	_health = _starting_health

func is_depleted() -> bool:
	return _health == 0

## Returns HP actually lost. Nonpositive damage and damage to the dead are no-ops.
func apply_damage(amount: int) -> int:
	if _notifying or amount <= 0 or is_depleted():
		return 0
	var applied := mini(amount, _health)
	_commit(_health - applied)
	return applied

## Returns HP actually gained. Does not revive a depleted component.
func apply_healing(amount: int) -> int:
	if _notifying or amount <= 0 or is_depleted():
		return 0
	var applied := mini(amount, _max_health - _health)
	_commit(_health + applied)
	return applied

## Restores the configured starting HP, notifying only if HP changed.
func reset() -> void:
	if not _notifying:
		_commit(_starting_health)

func _commit(next: int) -> void:
	var previous := _health
	if previous == next:
		return
	_health = next
	_notifying = true
	health_changed.emit(previous, _health)
	if _health == 0:
		depleted.emit()
	_notifying = false
