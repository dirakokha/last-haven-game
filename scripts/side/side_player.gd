class_name SidePlayer
extends CharacterBody2D

signal launched
signal landed
signal footfall(running: bool)

@export var walk_speed := 178.0
@export var run_speed := 285.0
@export var gravity := 1420.0
@export var jump_height := 110.0
var facing := 1
var jump_buffer := 0.0
var dodge_left := 0.0
var dodge_recovery := 0.0
var stride := 0.0

func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()
	var axis := Input.get_axis("move_left", "move_right")
	var running := Input.is_action_pressed("sprint")
	var before := position.x
	if absf(axis) > 0.1 and dodge_left <= 0.0:
		facing = 1 if axis > 0.0 else -1
	if Input.is_action_just_pressed("side_jump"):
		jump_buffer = 0.10
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	dodge_recovery = maxf(0.0, dodge_recovery - delta)
	if grounded and dodge_recovery == 0.0 and Input.is_action_just_pressed("side_dodge"):
		dodge_left = 0.18
		dodge_recovery = 0.44
	if grounded and jump_buffer > 0.0 and dodge_left <= 0.0:
		velocity.y = -sqrt(2.0 * gravity * jump_height)
		jump_buffer = 0.0
		launched.emit()
	elif not grounded:
		velocity.y = minf(velocity.y + gravity * delta, 800.0)
	velocity.x = facing * 365.0 if dodge_left > 0.0 else axis * (run_speed if running else walk_speed)
	dodge_left = maxf(0.0, dodge_left - delta)
	move_and_slide()
	if not grounded and is_on_floor():
		landed.emit()
	if grounded and is_on_floor() and absf(position.x - before) > 0.01:
		stride += absf(position.x - before)
		var pace := 53.0 if running else 44.0
		if stride >= pace:
			stride = fmod(stride, pace)
			footfall.emit(running)
