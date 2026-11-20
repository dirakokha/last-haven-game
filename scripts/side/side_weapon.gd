class_name SideWeapon
extends Node2D

signal fired(at: Vector2, facing: int)
signal handling(at: Vector2, stage: StringName)
signal hit(at: Vector2, material: StringName)
const CAPACITY := 12
const RELOAD_TIME := 1.15
const SHOULDER_Y := -78.0
# Measured from the authored cel pin to the front edge of the horizontal pistol.
const BARREL_X := 42.0
var magazine := CAPACITY
var reserve := 36
var cooldown := 0.0
var reload_left := 0.0
var recoil_left := 0.0
var swing_left := 0.0
var reload_stage := 0
var started_empty := false
@export var projectile_speed := 1840.0
@export var projectile_range := 730.0

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	recoil_left = maxf(0.0, recoil_left - delta)
	swing_left = maxf(0.0, swing_left - delta)
	if reload_left > 0.0:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_stage == 0 and reload_left <= 0.59:
			reload_stage = 1
			handling.emit(shoulder(), &"insert")
		if started_empty and reload_stage == 1 and reload_left <= 0.19:
			reload_stage = 2
			handling.emit(shoulder(), &"slide")
		if reload_left == 0.0:
			var n := mini(reserve, CAPACITY - magazine)
			magazine += n
			reserve -= n
	elif cooldown == 0.0:
		if Input.is_action_just_pressed("reload"):
			begin_reload()
		elif Input.is_action_just_pressed("bat"):
			melee()
		elif Input.is_action_just_pressed("fire"):
			shoot()

func facing() -> int:
	return (get_parent() as SidePlayer).facing

func shoulder() -> Vector2:
	return to_global(Vector2(0.0, SHOULDER_Y))

func muzzle_position() -> Vector2:
	return shoulder() + Vector2(facing() * BARREL_X, 0.0)

func begin_reload() -> void:
	if magazine < CAPACITY and reserve > 0 and cooldown == 0.0 and reload_left == 0.0:
		reload_left = RELOAD_TIME
		reload_stage = 0
		started_empty = magazine == 0
		handling.emit(shoulder(), &"release")

func shoot() -> void:
	if magazine <= 0 or cooldown > 0.0 or reload_left > 0.0:
		return
	magazine -= 1
	cooldown = 0.23
	recoil_left = 0.15
	var projectile := SideProjectile.new()
	var side := facing()
	projectile.direction = side
	projectile.speed = projectile_speed
	projectile.distance_left = projectile_range
	projectile.shooter = (get_parent() as SidePlayer).get_rid()
	projectile.contact.connect(hit.emit)
	var world := get_parent().get_parent()
	var muzzle := muzzle_position()
	# Geometry inside the barrel still blocks the shot; the flash remains on the actual muzzle.
	var query := PhysicsRayQueryParameters2D.create(shoulder(), muzzle, SideProjectile.TARGET_MASK, [projectile.shooter])
	query.hit_from_inside = true
	var blocked := get_world_2d().direct_space_state.intersect_ray(query)
	world.add_child(projectile)
	projectile.global_position = muzzle
	fired.emit(muzzle, side)
	if not blocked.is_empty():
		projectile.resolve_contact(blocked)
		projectile.queue_free()

func melee() -> void:
	if cooldown > 0.0 or reload_left > 0.0:
		return
	cooldown = 0.52
	swing_left = 0.24
	var origin := to_global(Vector2(0, -51))
	var horizontal := facing()
	var query := PhysicsRayQueryParameters2D.create(origin, origin + Vector2(horizontal * 87.0, 0.0), SideProjectile.TARGET_MASK, [(get_parent() as SidePlayer).get_rid()])
	var strike := get_world_2d().direct_space_state.intersect_ray(query)
	if not strike.is_empty() and strike.collider is SideWalker:
		strike.collider.hurt(31, horizontal * 220.0)
		hit.emit(strike.position, &"melee")
