class_name SideProjectile
extends Node2D

signal contact(at: Vector2, material: StringName)
const TARGET_MASK := 1 | 4
var direction := 1:
	set(value):
		direction = -1 if value < 0 else 1
var speed: float
var distance_left: float
var damage: int
var shooter: RID
var traveled := 0.0

func _init(shot_speed: float, shot_range: float, shot_damage: int) -> void:
	speed = shot_speed
	distance_left = shot_range
	damage = shot_damage

func _physics_process(delta: float) -> void:
	var distance := minf(distance_left, speed * delta)
	var end := global_position + Vector2(direction * distance, 0.0)
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
	if collider is SideWalker:
		if collider.hurt(damage, direction * 65.0) > 0:
			contact.emit(hit.position, &"infected")
	else:
		contact.emit(hit.position, collider.get_meta("surface", &"concrete"))

func _draw() -> void:
	var length := minf(traveled, 8.0)
	draw_line(Vector2(-direction * length, 0.0), Vector2(-direction, 0.0), Color(1.0, 0.76, 0.46, 0.48), 1.0)
	draw_rect(Rect2(-1, -1, 2, 2), Color("fff0b0"))
