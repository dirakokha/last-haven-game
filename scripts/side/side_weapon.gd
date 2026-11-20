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
const SHOT_FLASH_TIME := 0.047
const SHOT_RECOIL_TIME := 0.15
# Contact uses the matching wooden barrel in the BAT_IMPACT cel (pixel 135, 46).
const BAT_TIP := Vector2(67, -68)
const BAT_START_CONTACT := 0.20
const BAT_END := 0.52
enum BatPhase { NONE, READY, WINDUP, SWING, IMPACT, FOLLOW, RECOVER }
var magazine := CAPACITY
var reserve := 36
var cooldown := 0.0
var reload_left := 0.0
var recoil_left := 0.0
var shot_facing := 1
var bat_facing := 1
var bat_elapsed := 0.0
var bat_phase := BatPhase.NONE
var reload_stage := 0
var started_empty := false
@export var projectile_speed := 1840.0
@export var projectile_range := 730.0

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	recoil_left = maxf(0.0, recoil_left - delta)
	if bat_phase != BatPhase.NONE:
		advance_bat(delta)
		return
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
	return muzzle_for(facing())

func muzzle_for(side: int) -> Vector2:
	return to_global(Vector2(side * BARREL_X, SHOULDER_Y))

func showing_shot_flash() -> bool:
	return recoil_left > SHOT_RECOIL_TIME - SHOT_FLASH_TIME

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
	recoil_left = SHOT_RECOIL_TIME
	var projectile := SideProjectile.new()
	var side := facing()
	shot_facing = side
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
	if cooldown > 0.0 or reload_left > 0.0 or bat_phase != BatPhase.NONE:
		return
	cooldown = BAT_END
	bat_elapsed = 0.0
	bat_facing = facing()
	bat_phase = BatPhase.READY

func advance_bat(delta: float) -> void:
	var before := bat_elapsed
	bat_elapsed = minf(BAT_END, before + delta)
	if bat_elapsed < 0.05:
		bat_phase = BatPhase.READY
	elif bat_elapsed < 0.15:
		bat_phase = BatPhase.WINDUP
	elif bat_elapsed < BAT_START_CONTACT:
		bat_phase = BatPhase.SWING
	elif bat_elapsed < 0.26:
		bat_phase = BatPhase.IMPACT
	elif bat_elapsed < 0.37:
		bat_phase = BatPhase.FOLLOW
	elif bat_elapsed < BAT_END:
		bat_phase = BatPhase.RECOVER
	else:
		bat_phase = BatPhase.NONE
	# One query per committed swing. Crossing the marker is also the only path
	# that can publish melee sound/effects. A miss has no impact feedback.
	if before < BAT_START_CONTACT and bat_elapsed >= BAT_START_CONTACT:
		resolve_bat_contact()

func resolve_bat_contact() -> void:
	var origin := to_global(Vector2(0, BAT_TIP.y))
	var tip := to_global(Vector2(bat_facing * BAT_TIP.x, BAT_TIP.y))
	var query := PhysicsRayQueryParameters2D.create(origin, tip, SideProjectile.TARGET_MASK, [(get_parent() as SidePlayer).get_rid()])
	query.hit_from_inside = true
	var strike := get_world_2d().direct_space_state.intersect_ray(query)
	if strike.is_empty():
		return
	if strike.collider is SideWalker:
		var walker := strike.collider as SideWalker
		if walker.hurt(31, bat_facing * 220.0) > 0:
			hit.emit(strike.position, &"melee")
	else:
		hit.emit(strike.position, strike.collider.get_meta("surface", &"concrete"))
