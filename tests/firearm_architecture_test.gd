extends SceneTree

const PISTOL := preload("res://assets/weapons/pistol.tres")
const ALTERNATE := preload("res://tests/fixtures/alternate_firearm.tres")
var failures := 0
var shots: Array[Vector2] = []
var impacts: Array[StringName] = []
var stages: Array[StringName] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("Firearm architecture: " + label)

func check_definitions() -> void:
	check(PISTOL.is_valid() and ALTERNATE.is_valid(), "both Resources load and validate")
	check(PISTOL.weapon_id == &"weapon.pistol.basic" and PISTOL.display_name == "تپانچه"
		and PISTOL.ammo_id == &"ammo.9mm" and PISTOL.magazine_capacity == 12
		and is_equal_approx(PISTOL.reload_duration, 1.15) and is_equal_approx(PISTOL.fire_cooldown, 0.23)
		and PISTOL.damage == 24 and PISTOL.projectile_speed == 1840.0 and PISTOL.projectile_range == 730.0
		and PISTOL.muzzle_offset == Vector2(42, -78), "approved pistol definition values")
	check(ALTERNATE.weapon_id != PISTOL.weapon_id and ALTERNATE.ammo_id != PISTOL.ammo_id
		and ALTERNATE.magazine_capacity == 3, "alternate definition really differs")
	var invalid_cases := {
		"weapon_id": &"", "display_name": " ", "ammo_id": &" spaced ", "magazine_capacity": 0,
		"reload_duration": NAN, "fire_cooldown": 0.0, "damage": -1,
		"projectile_speed": INF, "projectile_range": 0.0, "muzzle_offset": Vector2(-1, -78),
	}
	for field in invalid_cases:
		var invalid := PISTOL.duplicate() as WeaponDef
		invalid.set(field, invalid_cases[field])
		check(not invalid.is_valid(), "invalid field rejected: " + field)
		var inert := WeaponInstance.new(invalid)
		check(inert.definition == null and inert.magazine == 0 and not inert.consume_round(), "invalid instances are inert")

func check_magazines() -> void:
	var first := WeaponInstance.new(PISTOL)
	var second := WeaponInstance.new(PISTOL)
	check(first.definition == second.definition and first.magazine == 12 and second.magazine == 12,
		"instances share config but start with separate full magazines")
	check(first.consume_round() and first.magazine == 11 and second.magazine == 12, "shot affects just one instance")
	check(first.load_rounds(&"wrong", 6) == 0 and first.load_rounds(PISTOL.ammo_id, -6) == 0
		and first.load_rounds(PISTOL.ammo_id, 0) == 0 and first.magazine == 11, "invalid loads are no-ops")
	check(first.load_rounds(PISTOL.ammo_id, 20) == 1 and first.magazine == 12, "load clamps to remaining space")
	check(first.load_rounds(PISTOL.ammo_id, 1) == 0, "full magazine refuses more rounds")
	first.restore_magazine(-20)
	check(first.magazine == 0 and not first.consume_round(), "empty and negative snapshots cannot yield rounds")
	first.restore_magazine(20)
	check(first.magazine == 12, "oversized snapshot clamps to capacity")
	first.restore_magazine(5)
	check(first.magazine == 5 and second.magazine == 12, "valid snapshot replaces only one magazine")

func add_box(body: CollisionObject2D, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	var box := RectangleShape2D.new()
	box.size = size
	var shape := CollisionShape2D.new()
	shape.shape = box
	shape.position = offset
	body.add_child(shape)

func projectile_in(world: Node2D) -> SideProjectile:
	for node in world.get_children():
		if node is SideProjectile and not node.is_queued_for_deletion():
			return node
	return null

func run() -> void:
	check_definitions()
	check_magazines()
	var world := Node2D.new()
	root.add_child(world)
	var ammo_fixture := preload("res://tests/fixtures/alternate_ammo.tres")
	var inventory := SideInventory.new(2, ItemCatalog.new([ItemCatalog.AMMO_9MM, ammo_fixture]))
	var player := SidePlayer.new(SidePlayer.MAX_HEALTH, inventory)
	player.position = Vector2(200, 200)
	player.collision_layer = 2
	world.add_child(player)
	player.set_physics_process(false)
	var gun := SideWeapon.new(ALTERNATE)
	player.add_child(gun)
	# Explicit deltas exercise the production tick without frame-rate-dependent thresholds.
	gun.set_physics_process(false)
	gun.fired.connect(func(point: Vector2, _facing: int) -> void: shots.append(point))
	gun.hit.connect(func(_point: Vector2, material: StringName) -> void: impacts.append(material))
	gun.handling.connect(func(_point: Vector2, stage: StringName) -> void: stages.append(stage))
	var walker := SideWalker.new()
	walker.position = Vector2(270, 200)
	walker.collision_layer = 4
	add_box(walker, Vector2(30, 96), Vector2(0, -48))
	world.add_child(walker)
	walker.set_physics_process(false)
	await physics_frame
	await process_frame

	check(gun.firearm.definition == ALTERNATE and gun.firearm.magazine == 3, "same controller loads alternate capacity")
	check(gun.muzzle_for(1) == Vector2(225, 136) and gun.muzzle_for(-1) == Vector2(175, 136), "offset mirrors X only")
	gun.shoot()
	var bullet := projectile_in(world)
	check(bullet != null and shots == [Vector2(225, 136)], "actual right projectile emits at alternate muzzle")
	if bullet != null:
		check(bullet.global_position == shots[0] and bullet.direction == 1, "right origin and direction")
		bullet._physics_process(0.05)
		check(bullet.global_position.is_equal_approx(Vector2(246, 136)), "alternate projectile actually travels at 420 px/s")
		bullet._physics_process(0.08)
	check(walker.vitals.health == 56 and impacts == [&"infected"], "alternate hit applies 9 damage through Walker vitals")
	check(is_equal_approx(gun.cooldown, 0.45), "alternate cooldown starts from definition")
	gun._physics_process(0.24)
	gun.shoot()
	check(gun.firearm.magazine == 2 and shots.size() == 1, "still cooling after the pistol's usual window")
	gun._physics_process(0.22)
	player.facing = -1
	gun.shoot()
	bullet = projectile_in(world)
	check(bullet != null and shots.size() == 2 and shots[-1] == Vector2(175, 136), "actual left projectile emits at mirrored muzzle")
	if bullet != null:
		check(bullet.global_position == shots[-1] and bullet.direction == -1, "left origin and direction")
		bullet._physics_process(1.0)
		check(bullet.traveled == 110.0 and bullet.global_position == Vector2(65, 136) and bullet.is_queued_for_deletion(),
			"sweep clamps actual travel to alternate range and then expires")

	gun._physics_process(0.46)
	var ammo := ALTERNATE.ammo_id
	player.add_reserve(PISTOL.ammo_id, 8)
	var other_player := SidePlayer.new()
	check(other_player.reserve_for(PISTOL.ammo_id) == 0, "reserve stock is independent between players")
	other_player.free()
	player.add_reserve(ammo, -10)
	check(player.take_reserve(PISTOL.ammo_id, -2) == 0 and player.reserve_for(PISTOL.ammo_id) == 8,
		"invalid reserve operations do not create or consume rounds")
	gun.begin_reload()
	check(gun.reload_left == 0.0 and stages.is_empty() and gun.firearm.magazine == 1, "mismatched stock cannot start reload")
	player.add_reserve(ammo, 4)
	var total := gun.firearm.magazine + player.reserve_for(ammo)
	gun.begin_reload()
	check(is_equal_approx(gun.reload_left, 0.6), "alternate reload duration from definition")
	gun._physics_process(0.59)
	gun.shoot()
	check(gun.firearm.magazine == 1 and player.reserve_for(ammo) == 4 and shots.size() == 2,
		"reload blocks shots and transfers no ammo before completion")
	gun._physics_process(0.02)
	check(stages == [&"release", &"insert"] and gun.firearm.magazine == 3
		and player.reserve_for(ammo) == 2 and gun.firearm.magazine + player.reserve_for(ammo) == total,
		"partial-magazine reload preserves rounds and omits the slide")
	gun.begin_reload()
	check(gun.reload_left == 0.0 and stages.size() == 2 and player.reserve_for(ammo) == 2,
		"full magazine cannot start a reload or spend stock")
	while gun.firearm.consume_round():
		pass
	gun.shoot()
	check(shots.size() == 2 and gun.firearm.magazine == 0, "empty magazine cannot create a shot")
	stages.clear()
	gun.begin_reload()
	gun._physics_process(0.61)
	check(stages == [&"release", &"insert", &"slide"] and gun.firearm.magazine == 2
		and player.reserve_for(ammo) == 0 and player.reserve_for(PISTOL.ammo_id) == 8,
		"empty reload loads only available matching rounds and plays the slide")

	var cover := StaticBody2D.new()
	cover.position = Vector2(190, 136)
	cover.set_meta("surface", &"metal")
	add_box(cover, Vector2(4, 18))
	world.add_child(cover)
	await physics_frame
	await process_frame
	gun.shoot()
	check(impacts == [&"infected", &"metal"] and gun.firearm.magazine == 1
		and projectile_in(world) == null, "alternate preflight hits real cover between shoulder and muzzle")
	world.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: firearm definitions, independent magazines, alternate controller, ammo, cooldown, reload, damage, muzzle, speed, range and obstruction")
	quit(0 if failures == 0 else 1)
