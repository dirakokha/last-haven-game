class_name SideWalker
extends CharacterBody2D

signal strikes(amount: int)
signal warned(at: Vector2, is_runner: bool)
signal vocal(at: Vector2, is_runner: bool, event: StringName)

enum Motion { WAIT, FOLLOW, WARN, LUNGE, RECOVER }
const MAX_HEALTH := 65
var target: SidePlayer
var vitals: CharacterVitals
var runner := false
var active := true
var mode := Motion.WAIT
var direction := -1
var remaining := 0.0
var knocked := 0.0
var delivered := false
var breath_left := 1.1
var hit_left := 0.0
var death_left := 0.0
var gait := 0.0

func _init(spawn_health: int = MAX_HEALTH) -> void:
	vitals = CharacterVitals.new(MAX_HEALTH, spawn_health)
	vitals.depleted.connect(_on_depleted)

## Returns HP lost so combat only publishes infected impacts for effective hits.
func hurt(amount: int, push: float) -> int:
	var applied := vitals.apply_damage(amount)
	if applied == 0:
		return 0
	knocked = push
	hit_left = 0.19
	if not vitals.is_depleted():
		vocal.emit(global_position, runner, &"damage")
	return applied

func _on_depleted() -> void:
	death_left = 0.21
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	vocal.emit(global_position, runner, &"death")

func _physics_process(delta: float) -> void:
	if vitals.is_depleted():
		death_left = maxf(0.0, death_left - delta)
		return
	if target == null:
		return
	hit_left = maxf(0.0, hit_left - delta)
	breath_left = maxf(0.0, breath_left - delta)
	if active and breath_left == 0.0 and mode in [Motion.WAIT, Motion.FOLLOW] and absf(position.x - target.position.x) < 295.0:
		vocal.emit(global_position, runner, &"breath")
		breath_left = 2.9 if runner else 4.4
	var before := position.x
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
					vocal.emit(global_position, runner, &"warn")
				else:
					velocity.x = direction * (128.0 if runner else 85.0)
			Motion.WARN:
				if remaining <= 0.0:
					mode = Motion.LUNGE
					vocal.emit(global_position, runner, &"attack")
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
	if mode == Motion.FOLLOW and absf(position.x - before) > 0.03:
		gait = fposmod(gait + absf(position.x - before) / 53.0, 1.0)
	else:
		gait = 0.0

func clear_contact() -> bool:
	var lift := Vector2(0, -48)
	var query := PhysicsRayQueryParameters2D.create(global_position + lift, target.global_position + lift, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
