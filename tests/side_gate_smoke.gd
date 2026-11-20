extends SceneTree

const COURT := "res://scenes/side/Court.tscn"
var failures := 0
var jump_count := 0
var landing_count := 0
var fired := Vector2.ZERO
var fired_side := 0
var impact_point := Vector2.ZERO
var last_material := &""
var contact_count := 0
var case_steps := 0
var reload_stages: Array[StringName] = []
var restored_preferences := false
var backup := PackedByteArray()
var had_preferences := false

func _initialize() -> void:
	call_deferred("run")

func restore_preferences() -> void:
	if restored_preferences:
		return
	restored_preferences = true
	if had_preferences:
		var file := FileAccess.open(SideWeatherPreferences.FILE, FileAccess.WRITE)
		file.store_buffer(backup)
	elif FileAccess.file_exists(SideWeatherPreferences.FILE):
		DirAccess.remove_absolute(SideWeatherPreferences.FILE)

func timeout() -> void:
	restore_preferences()
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

func f2() -> void:
	var input := InputEventKey.new()
	input.physical_keycode = KEY_F2
	input.pressed = true
	Input.parse_input_event(input)
	Input.flush_buffered_events()
	input = InputEventKey.new()
	input.physical_keycode = KEY_F2
	Input.parse_input_event(input)
	Input.flush_buffered_events()

func click(cursor: Vector2) -> void:
	var drag := InputEventMouseMotion.new()
	drag.position = cursor
	Input.parse_input_event(drag)
	var mouse := InputEventMouseButton.new()
	mouse.position = cursor
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	await ticks(1)
	mouse = InputEventMouseButton.new()
	mouse.position = cursor
	mouse.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()

func run() -> void:
	had_preferences = FileAccess.file_exists(SideWeatherPreferences.FILE)
	if had_preferences:
		backup = FileAccess.get_file_as_bytes(SideWeatherPreferences.FILE)
	SideWeatherPreferences.save(true)
	create_timer(21.0).timeout.connect(timeout)
	get_root().size = Vector2i(960, 540)
	if change_scene_to_file(COURT) != OK:
		restore_preferences()
		quit(1)
		return
	await scene_changed
	var room := current_scene as SideRoom
	if room == null or not is_instance_valid(room.walker):
		restore_preferences()
		quit(1)
		return
	room.walker.active = false
	await ticks(3)
	for bus in [&"Weapons", &"Player", &"Zombies", &"Environment", &"Interface"]:
		check(AudioServer.get_bus_index(bus) > 0, "independent audio bus " + str(bus))
	check(room.rain_enabled and room.view.weather.visible and room.audio.rain.playing, "starts with visible/audible rain nodes")
	f2()
	check(not room.rain_enabled and not room.view.weather.visible and not room.view.weather.is_processing() and not room.audio.rain.playing, "F2 stops both weather paths immediately")
	f2()
	check(room.rain_enabled and room.view.weather.visible and room.audio.rain.playing, "F2 restores both weather paths")
	f2()
	check(not SideWeatherPreferences.read(), "F2 persists off to disk")
	var actor: SidePlayer = room.player
	actor.launched.connect(func() -> void: jump_count += 1)
	actor.landed.connect(func() -> void: landing_count += 1)
	actor.footfall.connect(func(_running: bool, surface: StringName) -> void:
		if surface == &"metal":
			case_steps += 1)
	room.weapon.fired.connect(func(at: Vector2, side: int) -> void:
		fired = at
		fired_side = side)
	room.weapon.hit.connect(func(at: Vector2, what: StringName) -> void:
		impact_point = at
		last_material = what
		contact_count += 1)
	room.weapon.handling.connect(func(_at: Vector2, stage: StringName) -> void: reload_stages.append(stage))
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
	await click(Vector2(2, 2))
	var projectile: SideProjectile
	for child in room.world.get_children():
		if child is SideProjectile:
			projectile = child
	check(projectile != null and fired_side == 1 and gun.magazine == 11,
		"airborne LMB ignores opposite overhead cursor")
	if projectile != null:
		check(projectile.direction == 1 and is_equal_approx(projectile.global_position.y, fired.y)
			and projectile.global_position.x >= fired.x, "right shot sweeps horizontally from the flash")
	check(room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"flash" and f.p == fired), "flash uses exact fired pin")
	await pulse("side_jump")
	await ticks(43)
	Input.action_release("move_right")
	check(jump_count == 1 and landing_count == 1 and actor.is_on_floor(), "one jump before landing")
	check(actor.position.x > 555.0, "jump clears real obstacle")
	check(not is_instance_valid(projectile), "projectile expires at finite range")

	# The approved low case is below the horizontal muzzle. A temporary tall
	# fixture intersects the ray so the test exercises real metal occlusion.
	var tall_cover := room.add_solid(Rect2(465, 319, 24, 64), &"metal")
	actor.position = Vector2(390, 425)
	room.walker.position = Vector2(620, 425)
	await ticks(3)
	gun.shoot()
	await ticks(17)
	check(room.walker.hp == 65 and gun.magazine == 10 and last_material == &"metal" and absf(impact_point.x - 465.0) < 0.2, "metal cover stops projectile at actual contact")
	check(not room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"blood"), "no blood on metal")
	tall_cover.queue_free()
	actor.position = Vector2(570, 425)
	await ticks(3)
	gun.shoot()
	await ticks(3)
	check(last_material == &"infected" and absf(impact_point.y - (425.0 + SideWeapon.SHOULDER_Y)) < 0.2, "infected contact at horizontal projectile height")
	check(room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"blood" and f.p.distance_to(impact_point) < 8.0), "blood originates at the infected hit")
	await ticks(14)
	check(room.walker.hp == 41 and gun.magazine == 9, "side-view projectile uses original damage")
	await pulse("reload")
	check(gun.reload_left > 0.0, "original reload command")
	await ticks(72)
	check(gun.magazine == 12 and gun.reserve == 33, "reload consumes exactly three reserve rounds")
	check(reload_stages == [&"release", &"insert"], "tactical reload contact stages without unnecessary slide")
	actor.position = Vector2(500, 370)
	actor.velocity = Vector2.ZERO
	await ticks(14)
	check(case_steps > 0 and actor.ground_surface == &"metal", "case landing plays the metal contact surface")
	room.take_damage(15)
	actor.position = Vector2(691, 425)
	actor.velocity = Vector2.ZERO
	await pulse("move_left")
	await ticks(2)
	check(actor.facing == -1 and is_equal_approx(gun.muzzle_position().x, actor.global_position.x - SideWeapon.BARREL_X), "A flips and idle retains the mirrored pin")
	await click(Vector2(950, 510))
	check(fired_side == -1 and is_equal_approx(fired.y, actor.global_position.y + SideWeapon.SHOULDER_Y), "left LMB ignores cursor below/right")
	await ticks(5)
	check(room.walker.hp == 17 and last_material == &"infected", "left projectile reaches an actual infected collider")
	actor.position = Vector2(703, 425)
	await ticks(3)
	check(room.hud.prompt.visible, "contextual Persian prompt appears at grounded doorway")
	await pulse("side_entrance")
	check(room.transitioning, "W starts a guarded transition")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(4)
	check(room.indoor and absf(room.player.position.x - 265.0) < 1.0, "interior loaded at linked marker")
	check(not room.rain_enabled and room.audio.rain == null and room.audio.warehouse.playing, "interior uses its own ambience and remembers F2")
	check(room.health == 85 and room.weapon.magazine == 11 and room.weapon.reserve == 33, "transition carries combat state")
	await pulse("side_entrance")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(5)
	check(not room.indoor and absf(room.player.position.x - 680.0) < 1.0, "return reaches the linked exterior marker")
	check(is_instance_valid(room.walker) and room.walker.hp == 17, "return cannot reset Walker damage")
	if not is_instance_valid(room.walker):
		restore_preferences()
		quit(1)
		return
	check(not room.rain_enabled and not room.view.weather.visible and not room.audio.rain.playing, "rain remains off after round trip")
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
	gun.melee()
	await ticks(4)
	check(room.walker.hp == 0 and room.walker.collision_layer == 0 and room.checkpoint_hp == 0, "melee finishes the Walker and corpse is nonblocking")
	await ticks(17)
	check((room.walker.get_child(-1) as SideReviewArt).pose_index == SideReviewArt.Infected.DEATH, "distinct final Walker cels stay visible")
	f2()
	check(room.view.weather.visible and room.audio.rain.playing, "F2 turns rain back on after round trip")
	f2()
	room.immune = 0.0
	room.take_damage(999)
	await pulse("restart")
	if current_scene == null or current_scene == room:
		await scene_changed
	room = current_scene as SideRoom
	await ticks()
	check(room.health == 100 and not room.rain_enabled and not room.audio.rain.playing, "defeat restart resets combat but retains F2 off")
	room.weapon.magazine = 0
	reload_stages.clear()
	room.weapon.handling.connect(func(_at: Vector2, stage: StringName) -> void: reload_stages.append(stage))
	await pulse("reload")
	await ticks(72)
	check(reload_stages == [&"release", &"insert", &"slide"] and room.weapon.reserve == 24, "empty reload includes the slide and fills only from reserve")
	var walker := room.walker
	walker.active = false
	room.player.position = Vector2(25, 425)
	await pulse("move_left")
	await ticks(2)
	last_material = &""
	room.weapon.hit.connect(func(at: Vector2, material: StringName) -> void:
		impact_point = at
		last_material = material)
	await click(Vector2(940, 2))
	check(last_material == &"concrete" and absf(impact_point.x) < 0.2, "shoulder-to-muzzle preflight catches a concrete obstruction")
	check(room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"dust")
		and not room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"blood"), "concrete produces dust, not blood")
	unload_current_scene()
	await ticks(4)
	restore_preferences()
	if failures == 0:
		print("PASS: V1.1 side-view movement, directional LMB/muzzle, finite sweep and contacts, reload, Walker/melee, audio routing, rain F2/persistence, portal and scale")
	quit(0 if failures == 0 else 1)
