class_name SideAmmoPickup
extends SideInteractable

const AMMO_ID := &"ammo.9mm"
const MAX_RESERVE := 9223372036854775807
@export_range(1, 100) var rounds := 12
var _run_state: SideRunState

func _ready() -> void:
	_run_state = SideRunState.for_tree(get_tree())
	if _run_state.is_collected(placement_id):
		_consume()

func _is_available(actor: SidePlayer) -> bool:
	# add_reserve() saturates, so reject a grant that wouldn't fit in full.
	return _run_state != null and not _run_state.is_collected(placement_id) \
		and rounds > 0 and actor.reserve_for(AMMO_ID) <= MAX_RESERVE - rounds

func _activate(actor: SidePlayer) -> bool:
	actor.add_reserve(AMMO_ID, rounds)
	_run_state.record_collected(placement_id)
	_consume()
	return true

func _consume() -> void:
	enabled = false
	hide()
	queue_free()
