class_name SideWalker
extends CharacterBody2D

signal strikes(amount: int)
signal fell
signal warned(at: Vector2, is_runner: bool)

enum Motion { WAIT, FOLLOW, WARN, LUNGE, RECOVER }
var target: SidePlayer
var hp := 65
var runner := false
var active := true
var mode := Motion.WAIT
var direction := -1
var remaining := 0.0
var knocked := 0.0
var delivered := false

func hurt(amount: int, push: float) -> void:
	if hp <= 0:
		return
	hp -= amount
	knocked = push
	if hp <= 0:
		fell.emit()
		queue_free()

func _physics_process(delta: float) -> void:
	if hp <= 0 or target == null:
		return
	var gap := target.global_position - global_position
	var in_reach := absf(gap.x) < 72.0 and absf(gap.y) < 54.0
	velocity.x = 0.0
	remaining -= delta
	if active:
		match mode:
			Motion.WAIT:
				if absf(gap.x) < 370.0:
					mode = Motion.FOLLOW
			Motion.FOLLOW:
				direction = -1 if gap.x < 0.0 else 1
				if in_reach:
					mode = Motion.WARN
					remaining = 0.48 if runner else 0.58
					delivered = false
					warned.emit(global_position, runner)
				else:
					velocity.x = direction * (128.0 if runner else 85.0)
			Motion.WARN:
				if remaining <= 0.0:
					mode = Motion.LUNGE
					remaining = 0.33 if runner else 0.16
			Motion.LUNGE:
				velocity.x = direction * (270.0 if runner else 140.0)
				if not delivered and in_reach and gap.x * direction > 0.0 and clear_contact():
					delivered = true
					strikes.emit(22 if runner else 15)
				if remaining <= 0.0:
					mode = Motion.RECOVER
					remaining = 1.15 if runner else 0.78
			Motion.RECOVER:
				if remaining <= 0.0:
					mode = Motion.FOLLOW
	velocity.x += knocked
	knocked = move_toward(knocked, 0.0, 700.0 * delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1420.0 * delta, 800.0)
	move_and_slide()

func clear_contact() -> bool:
	var lift := Vector2(0, -48)
	var query := PhysicsRayQueryParameters2D.create(global_position + lift, target.global_position + lift, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
