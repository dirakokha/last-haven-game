class_name SidePortal
extends Marker2D

@export_file("*.tscn") var destination: String
@export var arrival: StringName
@export var entrance_text := "ورود"
@export var reach := 70.0

func in_reach(actor: SidePlayer) -> bool:
	return actor.is_on_floor() and absf(actor.global_position.x - global_position.x) < reach \
		and absf(actor.global_position.y - global_position.y) < 16.0
