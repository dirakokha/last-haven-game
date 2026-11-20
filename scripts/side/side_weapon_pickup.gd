class_name SideWeaponPickup
extends SideInteractable

@export var definition: WeaponDef
@export_range(1, 2) var slot: int = WeaponLoadout.SLOT_2
var _run: SideRunState

func _ready() -> void:
	_run = SideRunState.for_tree(get_tree())
	if _run.is_collected(placement_id):
		_consume()

func _is_available(actor: SidePlayer) -> bool:
	return _run != null and actor.inventory == _run.inventory and not _run.is_collected(placement_id)

func _activate(actor: SidePlayer) -> bool:
	if definition == null:
		return false
	var ammo := actor.inventory.definition_for(definition.ammo_id)
	if ammo == null or ammo.category != ItemDef.Category.AMMUNITION or not _run.loadout.unlock(slot, definition):
		return false
	_run.record_collected(placement_id)
	_consume()
	return true

func _consume() -> void:
	enabled = false
	hide()
	queue_free()
