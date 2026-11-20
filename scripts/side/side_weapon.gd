class_name SideWeapon
extends Node2D

signal fired(at: Vector2, facing: int)
signal handling(at: Vector2, stage: StringName)
signal hit(at: Vector2, material: StringName)
# Fractions of time remaining; preserve pistol insert at 0.59 s and slide at 0.19 s.
const INSERT_REMAINING := 59.0 / 115.0
const SLIDE_REMAINING := 19.0 / 115.0
const SHOT_FLASH_TIME := 0.047
const SHOT_RECOIL_TIME := 0.15
const SWITCH_LOCK := 0.18
# Contact uses the matching wooden barrel in the BAT_IMPACT cel (pixel 135, 46).
const BAT_TIP := Vector2(67, -68)
const BAT_START_CONTACT := 0.20
const BAT_END := 0.52
enum BatPhase { NONE, READY, WINDUP, SWING, IMPACT, FOLLOW, RECOVER }
var _loadout: WeaponLoadout
var loadout: WeaponLoadout:
	get: return _loadout
var firearm: WeaponInstance:
	get: return _loadout.active_weapon
var _switch_left := 0.0
var cooldown := 0.0
var reload_left := 0.0
var recoil_left := 0.0
var shot_facing := 1
var bat_facing := 1
var bat_elapsed := 0.0
var bat_phase := BatPhase.NONE
var reload_stage := 0
var started_empty := false

func _init(weapons: WeaponLoadout) -> void:
	_loadout = weapons

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	recoil_left = maxf(0.0, recoil_left - delta)
	_switch_left = maxf(0.0, _switch_left - delta)
	if bat_phase != BatPhase.NONE:
		advance_bat(delta)
		return
	if firearm == null:
		return
	var was_reloading := reload_left > 0.0
	if was_reloading:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_stage == 0 and reload_left <= firearm.definition.reload_duration * INSERT_REMAINING:
			reload_stage = 1
			handling.emit(shoulder(), &"insert")
		if started_empty and reload_stage == 1 and reload_left <= firearm.definition.reload_duration * SLIDE_REMAINING:
			reload_stage = 2
			handling.emit(shoulder(), &"slide")
		if reload_left == 0.0:
			var config := firearm.definition
			var owner_player := get_parent() as SidePlayer
			var needed := config.magazine_capacity - firearm.magazine
			var taken := owner_player.take_reserve(config.ammo_id, needed)
			firearm.load_rounds(config.ammo_id, taken)
	# A reload finishing this tick commits before any switch is processed.
	var slot := 0
	if Input.is_action_just_pressed("weapon_slot_1"):
		slot = WeaponLoadout.SLOT_1
	elif Input.is_action_just_pressed("weapon_slot_2"):
		slot = WeaponLoadout.SLOT_2
	if slot != 0 and switch_to(slot):
		return
	if not was_reloading and cooldown == 0.0:
		if Input.is_action_just_pressed("reload"):
			begin_reload()
		elif Input.is_action_just_pressed("bat"):
			melee()
		elif Input.is_action_just_pressed("fire"):
			shoot()

func switch_to(slot: int) -> bool:
	var actor := get_parent() as SidePlayer
	if actor == null or not is_inside_tree() or not can_process() or not actor.can_process() \
		or get_tree().paused or actor.vitals.is_depleted() or bat_phase != BatPhase.NONE \
		or _switch_left > 0.0 or not _loadout.can_equip(slot):
		return false
	# Cancellation never spends reserve. Do not reset the previous shot's cooldown.
	reload_left = 0.0
	reload_stage = 0
	started_empty = false
	_switch_left = SWITCH_LOCK
	return _loadout.equip(slot)

func facing() -> int:
	return (get_parent() as SidePlayer).facing

func shoulder() -> Vector2:
	return to_global(Vector2(0.0, firearm.definition.muzzle_offset.y))

func muzzle_position() -> Vector2:
	return muzzle_for(facing())

func muzzle_for(side: int) -> Vector2:
	var offset := firearm.definition.muzzle_offset
	return to_global(Vector2(side * offset.x, offset.y))

func showing_shot_flash() -> bool:
	return recoil_left > SHOT_RECOIL_TIME - SHOT_FLASH_TIME

func begin_reload() -> void:
	if firearm == null:
		return
	var config := firearm.definition
	if config == null or firearm.magazine >= config.magazine_capacity or cooldown > 0.0 or reload_left > 0.0:
		return
	if (get_parent() as SidePlayer).reserve_for(config.ammo_id) == 0:
		return
	reload_left = config.reload_duration
	reload_stage = 0
	started_empty = firearm.magazine == 0
	handling.emit(shoulder(), &"release")

func shoot() -> void:
	if cooldown > 0.0 or reload_left > 0.0 or firearm == null or not firearm.consume_round():
		return
	var config := firearm.definition
	cooldown = config.fire_cooldown
	recoil_left = SHOT_RECOIL_TIME
	var projectile := SideProjectile.new(config.projectile_speed, config.projectile_range, config.damage)
	var side := facing()
	shot_facing = side
	projectile.direction = side
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
