class_name SidePlayer
extends CharacterBody2D

signal launched
signal landed
signal footfall(running: bool, surface: StringName)
signal exerted


@export var walk_speed := 178.0
@export var run_speed := 285.0
@export var gravity := 1420.0
@export var jump_height := 110.0
var facing := 1
var jump_buffer := 0.0
var dodge_left := 0.0
var dodge_direction := 1
var dodge_recovery := 0.0
var stride := 0.0
var gait_moving := false
var gait_running := false
var ground_surface := &"concrete"
var jump_pose_left := 0.0
var land_pose_left := 0.0
var injury_left := 0.0
var down := false
var effort_left := 0.0

func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()
	jump_pose_left = maxf(0.0, jump_pose_left - delta)
	land_pose_left = maxf(0.0, land_pose_left - delta)
	injury_left = maxf(0.0, injury_left - delta)
	effort_left = maxf(0.0, effort_left - delta)
	var axis := Input.get_axis("move_left", "move_right")
	var running := Input.is_action_pressed("sprint")
	var before := position.x
	if absf(axis) > 0.1:
		facing = 1 if axis > 0.0 else -1
	if Input.is_action_just_pressed("side_jump"):
		jump_buffer = 0.10
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	dodge_recovery = maxf(0.0, dodge_recovery - delta)
	if grounded and dodge_recovery == 0.0 and Input.is_action_just_pressed("side_dodge"):
		dodge_left = 0.18
		dodge_direction = facing
		dodge_recovery = 0.44
	if grounded and jump_buffer > 0.0 and dodge_left <= 0.0:
		velocity.y = -sqrt(2.0 * gravity * jump_height)
		jump_buffer = 0.0
		jump_pose_left = 0.115
		land_pose_left = 0.0
		launched.emit()
	elif not grounded:
		velocity.y = minf(velocity.y + gravity * delta, 800.0)
	velocity.x = dodge_direction * 365.0 if dodge_left > 0.0 else axis * (run_speed if running else walk_speed)
	dodge_left = maxf(0.0, dodge_left - delta)
	move_and_slide()
	var on_ground := is_on_floor()
	if on_ground:
		for i in range(get_slide_collision_count()):
			var contact := get_slide_collision(i)
			if contact.get_normal().y < -0.75:
				ground_surface = contact.get_collider().get_meta("surface", &"concrete")
				break
	if not grounded and on_ground:
		land_pose_left = 0.10
		stride = 0.0
		footfall.emit(false, ground_surface)
		landed.emit()
	var distance := absf(position.x - before)
	var moving := grounded and on_ground and distance > 0.025 and dodge_left == 0.0
	if moving:
		if not gait_moving:
			stride = 0.0
			footfall.emit(running, ground_surface)
		var pace := 53.0 if running else 44.0
		stride += distance / pace
		if stride >= 1.0:
			stride = fposmod(stride, 1.0)
			footfall.emit(running, ground_surface)
		if running and effort_left == 0.0:
			effort_left = 2.8
			exerted.emit()
	else:
		stride = 0.0
	gait_moving = moving
	gait_running = moving and running
