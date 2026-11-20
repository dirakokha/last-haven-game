extends SceneTree

const COURT := "res://scenes/side/Court.tscn"
var failures := 0
var jump_count := 0
var landing_count := 0

func _initialize() -> void:
	call_deferred("run")

func timeout() -> void:
	push_error("Side-view smoke timed out")
	quit(1)

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func ticks(count: int = 2) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func pulse(action: String) -> void:
	# Keyboard events exercise InputMap, including W, instead of calling transition methods.
	var mapped := InputMap.action_get_events(action)[0] as InputEventKey
	var key := InputEventKey.new()
	key.physical_keycode = mapped.physical_keycode
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await ticks()
	key = InputEventKey.new()
	key.physical_keycode = mapped.physical_keycode
	Input.parse_input_event(key)
	Input.flush_buffered_events()

func run() -> void:
	create_timer(16.0).timeout.connect(timeout)
	get_root().size = Vector2i(960, 540)
	if change_scene_to_file(COURT) != OK:
		quit(1)
		return
	await scene_changed
	var room := current_scene as SideRoom
	if room == null or not is_instance_valid(room.walker):
		quit(1)
		return
	room.walker.active = false
	await ticks(3)
	var actor: SidePlayer = room.player
	actor.launched.connect(func() -> void: jump_count += 1)
	actor.landed.connect(func() -> void: landing_count += 1)
	check(actor.is_on_floor(), "start grounded")
	var start: Vector2 = actor.position
	await pulse("side_entrance")
	check(not room.transitioning and actor.position.is_equal_approx(start), "W neither moves nor enters outside portal")
	Input.action_press("move_near")
	await ticks(7)
	Input.action_release("move_near")
	check(actor.position.is_equal_approx(start), "old depth movement unused")
	Input.action_press("move_right")
	await ticks(65)
	check(actor.position.x < 451.0 and actor.position.x > 445.0, "low obstacle blocks walking")
	await pulse("side_jump")
	await ticks(10)
	check(jump_count == 1 and not actor.is_on_floor() and actor.position.y < 360.0, "responsive jump and gravity")
	var gun: SideWeapon = room.weapon
	gun.set_aim(actor.global_position + Vector2(250, -120))
	var muzzle: Vector2 = gun.muzzle_position()
	check(muzzle.y < actor.global_position.y - 78.0 and muzzle.x > actor.global_position.x, "airborne aim points from shoulder to target")
	gun.shoot()
	var projectile: SideProjectile
	for child in room.world.get_children():
		if child is SideProjectile:
			projectile = child
	check(projectile != null and projectile.global_position.is_equal_approx(muzzle) and gun.magazine == 11,
		"fire while airborne launches actual object at the muzzle")
	await pulse("side_jump")
	await ticks(43)
	Input.action_release("move_right")
	check(jump_count == 1 and landing_count == 1 and actor.is_on_floor(), "one jump before landing")
	check(actor.position.x > 555.0, "jump clears real obstacle")
	check(not is_instance_valid(projectile), "projectile expires at finite range")

	# Place fixtures at a flat collision segment for controlled projectile tests.
	actor.position = Vector2(390, 425)
	room.walker.position = Vector2(620, 425)
	await ticks(3)
	gun.set_aim(Vector2(620, 421))
	gun.shoot()
	await ticks(17)
	check(room.walker.hp == 65 and gun.magazine == 10, "metal cover stops projectile")
	actor.position = Vector2(570, 425)
	await ticks(3)
	gun.set_aim(Vector2(620, 362))
	gun.shoot()
	await ticks(17)
	check(room.walker.hp == 41 and gun.magazine == 9, "side-view projectile uses original damage")
	await pulse("reload")
	check(gun.reload_left > 0.0, "original reload command")
	await ticks(72)
	check(gun.magazine == 12 and gun.reserve == 33, "reload consumes exactly three reserve rounds")
	room.take_damage(15)
	gun.set_aim(Vector2(620, 362))
	gun.shoot()
	await ticks(5)
	actor.position = Vector2(703, 425)
	await ticks(3)
	check(room.hud.prompt.visible, "contextual Persian prompt appears at grounded doorway")
	await pulse("side_entrance")
	check(room.transitioning, "W starts a guarded transition")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(4)
	check(room.indoor and absf(room.player.position.x - 265.0) < 1.0, "interior loaded at linked marker")
	check(room.health == 85 and room.weapon.magazine == 11 and room.weapon.reserve == 33, "transition carries combat state")
	await pulse("side_entrance")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(5)
	check(not room.indoor and absf(room.player.position.x - 680.0) < 1.0, "return reaches the linked exterior marker")
	check(room.walker.hp == 17, "return cannot reset Walker damage")
	check(room.camera.position.y == 270.0, "side camera does not vertically follow jumps")
	root.size = Vector2i(1920, 1080)
	check(root.get_final_transform().get_scale().is_equal_approx(Vector2(2, 2)), "actual viewport maps design coordinates at 2x")
	root.size = Vector2i(960, 540)
	room.walker.position = Vector2(746, 425)
	room.walker.mode = SideWalker.Motion.FOLLOW
	await ticks(3)
	check(room.walker.mode == SideWalker.Motion.WARN, "horizontal close attack announces a warning")
	await ticks(38)
	check(room.health == 70, "Walker still deals the original 15 damage")
	gun = room.weapon
	gun.set_aim(Vector2(750, 356))
	gun.melee()
	await ticks(4)
	check(not is_instance_valid(room.walker) and room.checkpoint_hp == 0, "melee can finish the Walker and clear the exterior")
	unload_current_scene()
	await ticks(4)
	if failures == 0:
		print("PASS: side-view floor, one jump, obstacle, airborne muzzle, finite projectile, cover, reload, Walker warning/contact, melee, scaling and two-way W portal")
	quit(0 if failures == 0 else 1)
