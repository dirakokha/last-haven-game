class_name SideProjectile
extends Node2D

signal contact(at: Vector2, material: StringName)
const TARGET_MASK := 1 | 4
var direction := Vector2.RIGHT
var speed := 1840.0
var distance_left := 730.0
var damage := 24
var shooter: RID
var traveled := 0.0

func _physics_process(delta: float) -> void:
	var distance := minf(distance_left, speed * delta)
	var end := global_position + direction * distance
	var query := PhysicsRayQueryParameters2D.create(global_position, end, TARGET_MASK, [shooter])
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		resolve_contact(hit)
		queue_free()
		return
	global_position = end
	traveled += distance
	distance_left -= distance
	if distance_left <= 0.001:
		queue_free()
	queue_redraw()

func resolve_contact(hit: Dictionary) -> void:
	var collider := hit.get("collider") as CollisionObject2D
	if collider == null:
		return
	if collider.has_method("hurt"):
		collider.hurt(damage, direction.x * 65.0)
		contact.emit(hit.position, &"infected")
	else:
		contact.emit(hit.position, collider.get_meta("surface", &"concrete"))

func _draw() -> void:
	# Foundation marker only. No mouse-to-muzzle beam or long streak.
	draw_line(-direction * minf(traveled, 6.0), Vector2.ZERO, Color("f5d49d"), 2.0)
