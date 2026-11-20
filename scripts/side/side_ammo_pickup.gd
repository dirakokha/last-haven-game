class_name SideAmmoPickup
extends SideInteractable

const AMMO := ItemCatalog.AMMO_9MM
@export_range(1, 100) var rounds := 12
var _run_state: SideRunState

func _ready() -> void:
	_run_state = SideRunState.for_tree(get_tree())
	if _run_state.is_collected(placement_id):
		_consume()

func _is_available(_actor: SidePlayer) -> bool:
	return _run_state != null and not _run_state.is_collected(placement_id) and rounds > 0

func _activate(actor: SidePlayer) -> bool:
	if not actor.add_reserve(AMMO.item_id, rounds):
		return false
	_run_state.record_collected(placement_id)
	_consume()
	return true

func _consume() -> void:
	enabled = false
	hide()
	queue_free()
