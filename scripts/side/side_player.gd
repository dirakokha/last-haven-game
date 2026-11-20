class_name SidePlayer
extends CharacterBody2D

signal launched
signal landed
signal footfall(running: bool, surface: StringName)
signal exerted
signal damaged(amount: int)

const MAX_HEALTH := 100
const DAMAGE_IMMUNITY := 0.7
var vitals: CharacterVitals
var _immune_left := 0.0
var _inventory: SideInventory
var inventory: SideInventory:
	get: return _inventory

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
var effort_left := 0.0
var has_physics_sample := false
var landing_step := false

func _init(spawn_health: int = MAX_HEALTH, current_inventory: SideInventory = null) -> void:
	vitals = CharacterVitals.new(MAX_HEALTH, spawn_health)
	_inventory = current_inventory if current_inventory != null else SideInventory.new()

## The firearm controller only needs count and take, regardless of slot layout.
func reserve_for(ammo_id: StringName) -> int:
	return inventory.count(ammo_id) if _is_ammo(ammo_id) else 0

func add_reserve(ammo_id: StringName, rounds: int) -> bool:
	return _is_ammo(ammo_id) and inventory.add(ammo_id, rounds)

func take_reserve(ammo_id: StringName, rounds: int) -> int:
	var available := mini(rounds, reserve_for(ammo_id))
	return available if available > 0 and inventory.remove(ammo_id, available) else 0

func _is_ammo(id: StringName) -> bool:
	var definition := inventory.definition_for(id)
	return definition != null and definition.category == ItemDef.Category.AMMUNITION

func _process(delta: float) -> void:
	_immune_left = maxf(0.0, _immune_left - delta)

## Target policy: callers validate contact; this actor gates repeated damage.
func take_damage(amount: int) -> int:
	if _immune_left > 0.0:
		return 0
	var applied := vitals.apply_damage(amount)
	if applied > 0:
		_immune_left = DAMAGE_IMMUNITY
		injury_left = 0.24
		damaged.emit(applied)
	return applied

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
		jump_pose_left = 0.067
		land_pose_left = 0.0
		launched.emit()
	elif not grounded:
		velocity.y = minf(velocity.y + gravity * delta, 800.0)
	velocity.x = dodge_direction * 365.0 if dodge_left > 0.0 else axis * (run_speed if running else walk_speed)
	var dodging := dodge_left > 0.0
	dodge_left = maxf(0.0, dodge_left - delta)
	move_and_slide()
	var on_ground := is_on_floor()
	if on_ground:
		for i in range(get_slide_collision_count()):
			var contact := get_slide_collision(i)
			if contact.get_normal().y < -0.75:
				ground_surface = contact.get_collider().get_meta("surface", &"concrete")
				break
	if not grounded and on_ground and has_physics_sample:
		land_pose_left = 0.10
		landing_step = true
		stride = 0.0
		footfall.emit(false, ground_surface)
		landed.emit()
	has_physics_sample = true
	var distance := absf(position.x - before)
	var moving := grounded and on_ground and distance > 0.025 and not dodging
	if moving:
		if not gait_moving:
			stride = 0.0
			if not landing_step:
				footfall.emit(running, ground_surface)
			landing_step = false
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
		if not on_ground or land_pose_left <= 0.0:
			landing_step = false
	gait_moving = moving
	gait_running = moving and running
