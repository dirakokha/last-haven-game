class_name SideWeapon
extends Node2D

signal fired(at: Vector2)
signal reloading(at: Vector2)
signal hit(at: Vector2, material: StringName)
const CAPACITY := 12
const RELOAD_TIME := 1.15
const SOCKET := Vector2(0, -78)
var magazine := CAPACITY
var reserve := 36
var aim := Vector2.RIGHT
var cooldown := 0.0
var reload_left := 0.0
@export var projectile_speed := 1840.0
@export var projectile_range := 730.0

func _physics_process(delta: float) -> void:
	set_aim(get_global_mouse_position())
	cooldown = maxf(0.0, cooldown - delta)
	if reload_left > 0.0:
		reload_left = maxf(0.0, reload_left - delta)
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

func set_aim(world_point: Vector2) -> void:
	var offset := world_point - to_global(SOCKET)
	if offset.length_squared() > 1.0:
		aim = offset.normalized()

func muzzle_position() -> Vector2:
	return to_global(SOCKET) + aim * 42.0

func begin_reload() -> void:
	if magazine < CAPACITY and reserve > 0 and cooldown == 0.0 and reload_left == 0.0:
		reload_left = RELOAD_TIME
		reloading.emit(to_global(SOCKET))

func shoot() -> void:
	if magazine <= 0 or cooldown > 0.0 or reload_left > 0.0:
		return
	magazine -= 1
	cooldown = 0.23
	var projectile := SideProjectile.new()
	projectile.direction = aim
	projectile.speed = projectile_speed
	projectile.distance_left = projectile_range
	projectile.shooter = (get_parent() as SidePlayer).get_rid()
	projectile.contact.connect(hit.emit)
	var world := get_parent().get_parent()
	var muzzle := muzzle_position()
	# A barrel cannot fire through cover between the shoulder and the muzzle.
	var query := PhysicsRayQueryParameters2D.create(to_global(SOCKET), muzzle, SideProjectile.TARGET_MASK, [projectile.shooter])
	query.hit_from_inside = true
	var blocked := get_world_2d().direct_space_state.intersect_ray(query)
	world.add_child(projectile)
	projectile.global_position = muzzle
	if not blocked.is_empty():
		projectile.resolve_contact(blocked)
		projectile.queue_free()
	fired.emit(muzzle)

func melee() -> void:
	if cooldown > 0.0 or reload_left > 0.0:
		return
	cooldown = 0.52
	var origin := to_global(Vector2(0, -51))
	var horizontal := signf(aim.x)
	if horizontal == 0.0:
		horizontal = (get_parent() as SidePlayer).facing
	var query := PhysicsRayQueryParameters2D.create(origin, origin + Vector2(horizontal * 87.0, aim.y * 18.0), SideProjectile.TARGET_MASK, [(get_parent() as SidePlayer).get_rid()])
	var strike := get_world_2d().direct_space_state.intersect_ray(query)
	if not strike.is_empty() and strike.collider.has_method("hurt"):
		strike.collider.hurt(31, horizontal * 220.0)
		hit.emit(strike.position, &"melee")
