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
var melee_hits := 0
var walker_deaths := 0
var player_reactions := 0
var player_deaths := 0
var hit_phase := SideWeapon.BatPhase.NONE
var footsteps: Array[int] = []
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

func wait_bat_phase(gun: SideWeapon, expected: SideWeapon.BatPhase) -> void:
	# Await actual physics markers rather than assuming exactly one fixed tick
	# per rendered frame (the decimal boundaries can also round one tick later).
	for i in range(16):
		if gun.bat_phase == expected:
			return
		await ticks(1)

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
	var paused_drops: PackedVector2Array = room.view.weather.drops.duplicate()
	await ticks(3)
	check(room.view.weather.drops == paused_drops, "F2 off also stops precipitation simulation")
	check(not room.rain_enabled and not room.view.weather.visible and not room.view.weather.is_processing() and not room.audio.rain.playing, "F2 stops both weather paths immediately")
	f2()
	check(room.rain_enabled and room.view.weather.visible and room.audio.rain.playing, "F2 restores both weather paths")
	await ticks(3)
	check(room.view.weather.drops != paused_drops, "F2 on resumes precipitation simulation")
	f2()
	check(not SideWeatherPreferences.read(), "F2 persists off to disk")
	var actor: SidePlayer = room.player
	actor.launched.connect(func() -> void: jump_count += 1)
	actor.landed.connect(func() -> void: landing_count += 1)
	actor.footfall.connect(func(_running: bool, surface: StringName) -> void:
		footsteps.append(Engine.get_physics_frames())
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
	await ticks(6)
	check(actor.gait_moving and not actor.gait_running and absf(actor.velocity.x - actor.walk_speed) < 0.1, "walk uses approved speed and grounded gait")
	Input.action_press("sprint")
	await ticks(6)
	check(actor.gait_running and absf(actor.velocity.x - actor.run_speed) < 0.1, "sprint switches speed without leaving the gait")
	Input.action_release("sprint")
	Input.action_release("move_right")
	await pulse("side_dodge")
	check(actor.dodge_left > 0.0 and not actor.gait_moving, "dodge doesn't create a walking footfall pose")
	await ticks(30)
	actor.position = start
	await ticks(3)
	footsteps.clear()
	Input.action_press("move_right")
	await ticks(65)
	check(actor.position.x < 451.0 and actor.position.x > 445.0, "low obstacle blocks walking")
	await pulse("side_jump")
	await ticks(10)
	check(jump_count == 1 and not actor.is_on_floor() and actor.position.y < 360.0, "responsive jump and gravity")
	var gun: SideWeapon = room.weapon
	check(gun.firearm.definition == preload("res://assets/weapons/pistol.tres"), "active Court controller uses the approved pistol definition")
	check((gun.muzzle_for(1) - actor.global_position).is_equal_approx(Vector2(42, -78))
		and (gun.muzzle_for(-1) - actor.global_position).is_equal_approx(Vector2(-42, -78)),
		"active pistol preserves approved muzzle offsets in both directions")
	await click(Vector2(2, 2))
	var projectile: SideProjectile
	for child in room.world.get_children():
		if child is SideProjectile:
			projectile = child
	check(projectile != null and fired_side == 1 and gun.firearm.magazine == 11,
		"airborne LMB ignores opposite overhead cursor")
	if projectile != null:
		check(projectile.direction == 1 and is_equal_approx(projectile.global_position.y, fired.y)
			and projectile.global_position.x >= fired.x, "right shot sweeps horizontally from the flash")
	check(room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"flash" and f.p == fired), "flash uses exact fired pin")
	await pulse("side_jump")
	await ticks(43)
	Input.action_release("move_right")
	check(jump_count == 1 and landing_count == 1 and actor.is_on_floor(), "one jump before landing")
	for i in range(1, footsteps.size()):
		check(footsteps[i] - footsteps[i-1] > 1, "landing doesn't double-trigger the resumed gait")
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
	check(room.walker.vitals.health == 65 and gun.firearm.magazine == 10 and last_material == &"metal" and absf(impact_point.x - 465.0) < 0.2, "metal cover stops projectile at actual contact")
	check(not room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"blood"), "no blood on metal")
	tall_cover.queue_free()
	actor.position = Vector2(570, 425)
	await ticks(3)
	gun.shoot()
	await ticks(3)
	check(last_material == &"infected" and absf(impact_point.y - (425.0 - 78.0)) < 0.2, "infected contact at horizontal projectile height")
	check(room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"blood" and f.p.distance_to(impact_point) < 8.0), "blood originates at the infected hit")
	await ticks(14)
	check(room.walker.vitals.health == 41 and gun.firearm.magazine == 9, "side-view projectile uses original damage")
	await pulse("reload")
	check(gun.reload_left > 0.0, "original reload command")
	await ticks(72)
	check(gun.firearm.magazine == 12 and room.player.reserve_for(&"ammo.9mm") == 33, "reload consumes exactly three reserve rounds")
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
	check(actor.facing == -1 and is_equal_approx(gun.muzzle_position().x, actor.global_position.x - 42.0), "A flips and idle retains the mirrored pin")
	await click(Vector2(950, 510))
	check(fired_side == -1 and is_equal_approx(fired.y, actor.global_position.y - 78.0), "left LMB ignores cursor below/right")
	await ticks(5)
	check(room.walker.vitals.health == 17 and last_material == &"infected", "left projectile reaches an actual infected collider")
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
	check(room.player.vitals.health == 85 and room.weapon.firearm.magazine == 11 and room.player.reserve_for(&"ammo.9mm") == 33, "transition carries combat state")
	check(room.hud.instrument.text == "تپانچه" and room.hud.mag_count.text == "خشاب ۱۱"
		and room.hud.reserve_count.text == "ذخیره ۳۳", "Persian HUD reads the loaded definition and restored ammo")
	await pulse("side_entrance")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(5)
	check(not room.indoor and absf(room.player.position.x - 680.0) < 1.0, "return reaches the linked exterior marker")
	check(room.weapon.firearm.magazine == 11 and room.player.reserve_for(&"ammo.9mm") == 33,
		"return from Warehouse preserves magazine and player-owned stock")
	check(is_instance_valid(room.walker) and room.walker.vitals.health == 17, "return cannot reset Walker damage")
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
	check(room.player.vitals.health == 70, "Walker still deals the original 15 damage")
	await ticks(2)
	var pain_voices: Array[AudioStreamPlayer2D] = room.audio.pools[&"Player"]
	check(room.player.injury_left > 0.0 and pain_voices.any(func(voice: AudioStreamPlayer2D) -> bool:
		return voice.playing and voice.stream == SideReviewAudio.CLIPS[&"hurt"]),
		"accepted Walker damage starts existing Player reaction and pain cue")
	check(room.hud.vitals.text == room.hud.tr("سلامت  %s") % "۷۰"
		and is_equal_approx(room.hud.health_fill.size.x, room.hud.health_track.size.x * 0.7),
		"Persian health label and fill read authoritative HP")
	room.player.damaged.connect(func(_amount: int) -> void: player_reactions += 1)
	room.player.vitals.depleted.connect(func() -> void: player_deaths += 1)
	room.take_damage(15)
	check(room.player.vitals.health == 70 and player_reactions == 0, "immunity rejects another hit and reaction in the existing window")
	room.walker.vocal.connect(func(_at: Vector2, _runner: bool, cue: StringName) -> void:
		if cue == &"death":
			walker_deaths += 1)
	gun = room.weapon
	gun.hit.connect(func(_at: Vector2, material: StringName) -> void:
		melee_hits += int(material == &"melee")
		hit_phase = gun.bat_phase
		last_material = material)
	var player_art := room.player.get_child(-1) as SideReviewArt
	var mag_before: int = gun.firearm.magazine
	await pulse("bat")
	check(gun.bat_phase == SideWeapon.BatPhase.READY and player_art.pose_index == SideReviewArt.Hero.BAT_READY, "F equips the ready drawing")
	await wait_bat_phase(gun, SideWeapon.BatPhase.WINDUP)
	check(gun.bat_phase == SideWeapon.BatPhase.WINDUP and player_art.pose_index == SideReviewArt.Hero.BAT_WINDUP, "bat displays windup before contact")
	check(room.walker.vitals.health == 17 and melee_hits == 0, "no damage or impact while winding up")
	await wait_bat_phase(gun, SideWeapon.BatPhase.SWING)
	check(gun.bat_phase == SideWeapon.BatPhase.SWING and player_art.pose_index == SideReviewArt.Hero.BAT_SWING, "bat displays pre-contact swing")
	await wait_bat_phase(gun, SideWeapon.BatPhase.IMPACT)
	check(gun.bat_phase == SideWeapon.BatPhase.IMPACT and player_art.pose_index == SideReviewArt.Hero.BAT_IMPACT, "impact drawing matches the physics contact window")
	check(melee_hits == 1 and hit_phase == SideWeapon.BatPhase.IMPACT and gun.firearm.magazine == mag_before, "one melee contact on impact, no magazine change")
	var voices: Array[AudioStreamPlayer2D] = room.audio.pools[&"Weapons"]
	check(voices.any(func(voice: AudioStreamPlayer2D) -> bool:
		return voice.playing and voice.stream == SideReviewAudio.CLIPS[&"melee"]), "same hit event starts licensed melee cue on Weapons")
	check(room.effects.flecks.any(func(f: SideEffects.Fleck) -> bool: return f.kind == &"strike"), "actual melee hit triggers impact FX")
	check(room.walker.vitals.health == 0 and room.walker.collision_layer == 0 and room.walker.collision_mask == 0,
		"bat finishes Walker and corpse is nonblocking")
	var knocked_at_death: float = room.walker.knocked
	check(room.walker.hurt(99, 999.0) == 0 and walker_deaths == 1 and room.walker.knocked == knocked_at_death,
		"repeated corpse damage cannot replay death or apply knockback")
	await wait_bat_phase(gun, SideWeapon.BatPhase.FOLLOW)
	check(player_art.pose_index == SideReviewArt.Hero.BAT_FOLLOW, "bat displays follow-through")
	await wait_bat_phase(gun, SideWeapon.BatPhase.RECOVER)
	check(player_art.pose_index == SideReviewArt.Hero.BAT_RECOVER, "bat displays recovery")
	await wait_bat_phase(gun, SideWeapon.BatPhase.NONE)
	check(gun.bat_phase == SideWeapon.BatPhase.NONE and melee_hits == 1, "no repeat damage in recovery")
	check((room.walker.get_child(-1) as SideReviewArt).pose_index == SideReviewArt.Infected.DEATH, "distinct final Walker cel stays visible")
	await pulse("bat")
	await ticks(33)
	check(melee_hits == 1, "bat miss or corpse does not trigger impact")
	f2()
	check(room.view.weather.visible and room.audio.rain.playing, "F2 turns rain back on after round trip")
	f2()
	room.take_damage(999)
	check(room.player.vitals.health == 0 and player_reactions == 1 and player_deaths == 1,
		"after immunity expires a lethal hit commits once and reacts once")
	check(room.defeated and room.world.process_mode == Node.PROCESS_MODE_DISABLED,
		"player depletion freezes the world")
	room.take_damage(999)
	check(player_reactions == 1 and player_deaths == 1, "defeated player cannot react or die again")
	await ticks()
	check(room.hud.result.visible and room.hud.health_fill.size.x == 0.0, "defeat panel visible with authoritative zero HP")
	check(player_art.pose_index == SideReviewArt.Hero.LOW, "player art still presents defeat while simulation is frozen")
	await pulse("restart")
	if current_scene == null or current_scene == room:
		await scene_changed
	room = current_scene as SideRoom
	await ticks()
	check(room.player.vitals.health == 100 and not room.rain_enabled and not room.audio.rain.playing, "defeat restart resets combat but retains F2 off")
	check(not room.defeated and room.world.process_mode != Node.PROCESS_MODE_DISABLED
		and is_instance_valid(room.walker) and room.walker.vitals.health == 65
		and room.weapon.firearm.magazine == 12 and room.player.reserve_for(&"ammo.9mm") == 36,
		"restart restores original encounter and ammunition")
	room.weapon.firearm.restore_magazine(0)
	reload_stages.clear()
	room.weapon.handling.connect(func(_at: Vector2, stage: StringName) -> void: reload_stages.append(stage))
	await pulse("reload")
	await ticks(72)
	check(reload_stages == [&"release", &"insert", &"slide"] and room.player.reserve_for(&"ammo.9mm") == 24, "empty reload includes the slide and fills only from reserve")
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
	await ticks(16)
	room.player.position = Vector2(680, 425)
	walker.position = Vector2(617, 425)
	var obstruction := room.add_solid(Rect2(633, 325, 10, 60), &"metal")
	last_material = &""
	await ticks(3)
	await pulse("bat")
	await ticks(13)
	check(room.weapon.bat_facing == -1 and last_material == &"metal" and walker.vitals.health == 65, "left bat respects nearest obstruction")
	obstruction.queue_free()
	await ticks(30)
	await pulse("bat")
	await ticks(13)
	check(last_material == &"melee" and walker.vitals.health == 34, "left bat contacts infected only when clear")
	# The earlier round trip verified an injured Walker. Verify a firearm kill
	# and a second round trip with zero Walker HP, not a live duplicate.
	await ticks(25)
	room.weapon.shoot()
	await ticks(16)
	check(walker.vitals.health == 10, "firearm still inflicts original damage after melee")
	room.weapon.shoot()
	await ticks(16)
	check(walker.vitals.is_depleted() and walker.collision_layer == 0, "firearm kill disables Walker collision")
	room.player.position = Vector2(703, 425)
	await ticks(3)
	await pulse("side_entrance")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(4)
	await pulse("side_entrance")
	await scene_changed
	room = current_scene as SideRoom
	await ticks(4)
	check(not room.indoor and not is_instance_valid(room.walker), "defeated Walker snapshot persists across both doors")
	unload_current_scene()
	await ticks(4)
	restore_preferences()
	if failures == 0:
		print("PASS: foundation freeze side-view movement, directional LMB/muzzle, finite sweep and contacts, reload, Walker/melee, audio routing, rain F2/persistence, portal and scale; authoritative vitals, immunity, defeat and restart")
	quit(0 if failures == 0 else 1)
