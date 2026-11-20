extends SceneTree

const COURT := "res://scenes/side/Court.tscn"
const PISTOL := preload("res://assets/weapons/pistol.tres")
const HEAVY := preload("res://assets/weapons/heavy_pistol.tres")
const AMMO_9 := &"ammo.9mm"
const AMMO_45 := &"ammo.45acp"
const PICKUP := &"warehouse.pickup.heavy_pistol.01"
var failures := 0
var shot_pin: Vector2
var shot_cooldown := 0.0
var contact_pin: Vector2
var contact_material: StringName

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, context: String) -> void:
	if not value:
		failures += 1
		push_error(context)

func model_checks() -> void:
	var loadout := WeaponLoadout.new()
	var pistol := loadout.weapon_at(1)
	check(loadout.active_slot == 1 and loadout.active_weapon == pistol and pistol.definition == PISTOL
		and pistol.magazine == 12 and loadout.weapon_at(2) == null and not loadout.equip(2), "only the original pistol starts owned")
	check(HEAVY.is_valid() and HEAVY.weapon_id == &"weapon.pistol.heavy" and HEAVY.display_name == "تپانچه سنگین"
		and HEAVY.ammo_id == AMMO_45 and HEAVY.magazine_capacity == 8 and is_equal_approx(HEAVY.reload_duration, 1.45)
		and is_equal_approx(HEAVY.fire_cooldown, 0.38) and HEAVY.damage == 34 and HEAVY.projectile_speed == 1760
		and HEAVY.projectile_range == 690 and HEAVY.muzzle_offset == Vector2(46, -78), "approved Heavy Pistol definition")
	var updates: Array[int] = []
	var observe := func() -> void: updates.append(loadout.active_slot)
	loadout.changed.connect(observe)
	check(not loadout.unlock(3, HEAVY) and not loadout.unlock(2, WeaponDef.new())
		and not loadout.unlock(2, PISTOL) and not loadout.equip(1), "reject invalid slots, invalid definitions, duplicate IDs and no-op selection")
	check(loadout.unlock(2, HEAVY) and not loadout.unlock(2, HEAVY) and loadout.weapon_at(2).magazine == 8,
		"unlock creates one full independent instance and cannot repeat")
	pistol.restore_magazine(4)
	check(loadout.equip(2) and loadout.active_weapon.consume_round() and loadout.weapon_at(2).magazine == 7
		and pistol.magazine == 4 and loadout.equip(1) and loadout.active_weapon == pistol and pistol.magazine == 4,
		"selection and firing keep magazines independent")
	loadout.reset()
	check(loadout.active_slot == 1 and loadout.weapon_at(2) == null and loadout.active_weapon.magazine == 12
		and updates == [1, 2, 1, 1], "only committed loadout operations notify and reset restores the seed")
	loadout.changed.disconnect(observe)

func settle(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func key_event(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func press(code: Key) -> void:
	key_event(code, true)
	await settle(2)
	key_event(code, false)

func click(cursor: Vector2) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.position = cursor
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	await settle(1)
	mouse = InputEventMouseButton.new()
	mouse.position = cursor
	mouse.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()

func move_actor(room: SideRoom, point: Vector2) -> void:
	room.player.position = point
	room.player.velocity = Vector2.ZERO
	await settle()
	await process_frame

func gunshot_checks(room: SideRoom, slot: int, config: WeaponDef, hp_before: int) -> void:
	var gun := room.weapon
	await press(KEY_1 if slot == 1 else KEY_2)
	await settle(14)
	check(gun.firearm.definition == config, "real slot key equips the production definition")
	await move_actor(room, Vector2(440, 425))
	room.player.facing = 1
	var tall_cover := room.add_solid(Rect2(470, 330, 55, 60), &"metal")
	await settle()
	check((gun.muzzle_for(1) - room.player.global_position).is_equal_approx(config.muzzle_offset)
		and (gun.muzzle_for(-1) - room.player.global_position).is_equal_approx(Vector2(-config.muzzle_offset.x, config.muzzle_offset.y)),
		"both actor-relative muzzle sides match the selected definition")
	contact_material = &""
	await click(Vector2(2, 2))
	check(contact_material == &"metal" and is_equal_approx(contact_pin.x, 470.0) and room.walker.vitals.health == hp_before
		and shot_pin.is_equal_approx(gun.muzzle_for(1)) and is_equal_approx(shot_cooldown, config.fire_cooldown),
		"rightward LMB uses the true muzzle, real cover and the active cooldown")
	tall_cover.queue_free()
	await settle(25)
	await move_actor(room, Vector2(790, 425))
	room.walker.position = Vector2(615, 425)
	room.player.facing = -1
	await click(Vector2(950, 500))
	var projectile: SideProjectile
	for child in room.world.get_children():
		if child is SideProjectile:
			projectile = child
	check(projectile != null and projectile.direction == -1 and projectile.speed == config.projectile_speed
		and is_equal_approx(projectile.distance_left + projectile.traveled, config.projectile_range)
		and projectile.damage == config.damage and is_equal_approx(projectile.global_position.y, shot_pin.y)
		and shot_pin.is_equal_approx(gun.muzzle_for(-1)), "same horizontal projectile carries the active speed, range, damage and left muzzle")
	await settle(10)
	check(contact_material == &"infected" and is_equal_approx(contact_pin.y, shot_pin.y)
		and room.walker.vitals.health == hp_before - config.damage, "horizontal sweep applies the active damage through real Walker vitals")
	await settle(17)

func run() -> void:
	model_checks()
	create_timer(24.0).timeout.connect(func() -> void:
		push_error("Weapon loadout integration timed out")
		quit(1))
	root.size = Vector2i(960, 540)
	if change_scene_to_file(COURT) != OK:
		quit(1)
		return
	await scene_changed
	var room := current_scene as SideRoom
	room.walker.active = false
	await settle()
	var state := SideRunState.for_tree(self)
	var loadout := state.loadout
	var pistol := room.weapon.firearm
	var player := room.player
	var original := pistol.definition
	check(room.weapon.loadout == loadout and original == PISTOL and original.weapon_id == &"weapon.pistol.basic"
		and original.display_name == "تپانچه" and original.ammo_id == AMMO_9 and original.magazine_capacity == 12
		and is_equal_approx(original.reload_duration, 1.15) and is_equal_approx(original.fire_cooldown, 0.23)
		and original.damage == 24 and original.projectile_speed == 1840 and original.projectile_range == 730
		and original.muzzle_offset == Vector2(42, -78) and pistol.magazine == 12 and player.reserve_for(AMMO_9) == 36,
		"the live starting pistol keeps all approved values")
	await press(KEY_2)
	check(loadout.active_slot == 1, "key 2 ignores the unowned slot")
	pistol.restore_magazine(9)
	await move_actor(room, (room.get_node("WarehouseEntrance") as SidePortal).position)
	await press(KEY_W)
	var transfer: Dictionary = get_meta(SideRoom.TRANSFER)
	check(not transfer.has("magazine"), "room travel no longer copies a single magazine")
	await scene_changed
	room = current_scene as SideRoom
	player = room.player
	check(room.weapon.firearm == pistol and pistol.magazine == 9, "Warehouse uses the exact Court pistol instance")
	var pickup := room.get_node("HeavyPistolPickup") as SideWeaponPickup
	await move_actor(room, pickup.position)
	check(room.hud.prompt.text == "\u2066E\u2069 — برداشتن تپانچه سنگین", "Persian pickup prompt keeps the E key")
	pickup.slot = 1
	await press(KEY_E)
	check(pickup.visible and not state.is_collected(PICKUP) and loadout.weapon_at(2) == null, "failed unlock does not consume the pickup")
	pickup.slot = 2
	await press(KEY_E)
	await press(KEY_E)
	var heavy := loadout.weapon_at(2)
	check(heavy != null and heavy.magazine == 8 and not is_instance_valid(pickup) and state.is_collected(PICKUP)
		and player.reserve_for(AMMO_45) == 0 and player.reserve_for(AMMO_9) == 36 and loadout.active_slot == 1,
		"real E acquires one full Heavy Pistol without granting reserves or auto-equipping")
	await press(KEY_2)
	await process_frame
	check(room.weapon.firearm == heavy and room.hud.instrument.text == "تپانچه سنگین" and room.hud.mag_count.text == "خشاب ۸"
		and room.hud.reserve_count.text == "ذخیره ۰" and room.hud.gear.text.contains("SLOT 2  ·  SWITCH 1 / 2"),
		"key 2 equips the Heavy Pistol and HUD identifies its slot and compatible ammo")
	heavy.restore_magazine(6)
	await press(KEY_R)
	check(room.weapon.reload_left == 0.0 and heavy.magazine == 6 and player.reserve_for(AMMO_9) == 36, "9mm cannot start a Heavy Pistol reload")
	await move_actor(room, (room.get_node("SupplyCrate") as SideLootContainer).position)
	await press(KEY_E)
	await press(KEY_1)
	check(room.hud.loot_panel.visible and paused and loadout.active_slot == 2 and not room.weapon.switch_to(1), "Loot pauses switching")
	await press(KEY_UP)
	await press(KEY_ENTER)
	await press(KEY_ESCAPE)
	check(player.reserve_for(AMMO_45) == 12 and player.reserve_for(AMMO_9) == 36, "real Loot TAKE moves .45 ACP into the existing Inventory")
	await settle(13) # The earlier switch lock was frozen while Loot was open.
	await press(KEY_1)
	check(loadout.active_slot == 1, "key 1 equips the original pistol")
	await press(KEY_2)
	check(loadout.active_slot == 1, "an immediate key 2 is blocked by the switch lock")
	await settle(13)
	await press(KEY_R)
	check(room.weapon.reload_left > 0.0, "R starts a 9mm reload")
	await press(KEY_2)
	check(room.weapon.firearm == heavy and room.weapon.reload_left == 0.0 and pistol.magazine == 9
		and player.reserve_for(AMMO_9) == 36, "switch cancels uncommitted reload without spending 9mm")
	await settle(13)
	await press(KEY_R)
	check(room.weapon.reload_left > 1.39, "Heavy Pistol uses the longer reload duration")
	await settle(91)
	await press(KEY_1)
	check(heavy.magazine == 8 and player.reserve_for(AMMO_45) == 10 and player.reserve_for(AMMO_9) == 36,
		"switch after completion preserves the Heavy Pistol reload and its exact .45 debit")
	await settle(13)
	check(player.take_reserve(AMMO_9, 36) == 36, "fixture leaves only incompatible .45 reserve")
	await press(KEY_R)
	check(room.weapon.reload_left == 0.0 and pistol.magazine == 9 and player.reserve_for(AMMO_45) == 10,
		".45 ACP cannot start a 9mm pistol reload")
	check(player.add_reserve(AMMO_9, 36), "fixture restores 9mm reserve for the live reload")
	await press(KEY_R)
	await settle(75)
	check(pistol.magazine == 12 and player.reserve_for(AMMO_9) == 33 and player.reserve_for(AMMO_45) == 10,
		"fresh 9mm reload debits only 9mm after the prior cancellation")
	await press(KEY_TAB)
	await press(KEY_2)
	check(room.hud.inventory_panel.visible and paused and loadout.active_slot == 1, "Inventory pauses switching")
	await press(KEY_ESCAPE)
	await press(KEY_ESCAPE)
	await press(KEY_2)
	check(paused and loadout.active_slot == 1, "normal pause blocks switching")
	await press(KEY_ESCAPE)
	await press(KEY_F)
	await press(KEY_2)
	check(loadout.active_slot == 1 and room.weapon.bat_phase != SideWeapon.BatPhase.NONE, "slot key cannot interrupt an active bat sequence")
	await settle(33)
	await press(KEY_2)
	await settle(13)
	await click(Vector2(0, 0))
	await press(KEY_1)
	var blocked_cooldown: float = room.weapon.cooldown
	await click(Vector2(0, 0))
	check(loadout.active_slot == 1 and blocked_cooldown > 0.0 and heavy.magazine == 7 and pistol.magazine == 12,
		"switch during Heavy Pistol cooldown cannot fire the newly equipped pistol early")
	await settle(25)
	await click(Vector2(0, 0))
	await press(KEY_2)
	check(pistol.magazine == 11 and heavy.magazine == 7 and loadout.active_slot == 2,
		"both independent magazines retain fired rounds before travel")

	await move_actor(room, (room.get_node("CourtEntrance") as SidePortal).position)
	await press(KEY_W)
	await press(KEY_1)
	check(room.transitioning and loadout.active_slot == 2 and not room.weapon.switch_to(1), "fade blocks switching")
	await scene_changed
	room = current_scene as SideRoom
	room.walker.active = false
	await settle(5)
	check(room.weapon.loadout == loadout and room.weapon.firearm == heavy and pistol.magazine == 11
		and heavy.magazine == 7 and loadout.active_slot == 2 and room.player.reserve_for(AMMO_45) == 10,
		"return to Court preserves equip, both loaded magazines and .45 reserve")
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	await settle(5)
	check(room.weapon.firearm == heavy and loadout.weapon_at(1) == pistol and heavy.magazine == 7 and pistol.magazine == 11
		and room.get_node_or_null("HeavyPistolPickup") == null, "return to Warehouse cannot reseed weapons or the pickup")
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	room.walker.active = false
	var court_weapon := room.weapon
	court_weapon.fired.connect(func(at: Vector2, _side: int) -> void:
		shot_pin = at
		shot_cooldown = court_weapon.cooldown)
	room.weapon.hit.connect(func(at: Vector2, material: StringName) -> void:
		contact_pin = at
		contact_material = material)
	await gunshot_checks(room, 1, PISTOL, 65)
	await gunshot_checks(room, 2, HEAVY, 41)
	room.take_damage(100)
	await press(KEY_1)
	check(room.defeated and loadout.active_slot == 2 and not room.weapon.switch_to(1), "defeat blocks weapon switching")
	key_event(KEY_ENTER, true)
	await scene_changed
	key_event(KEY_ENTER, false)
	room = current_scene as SideRoom
	room.walker.active = false
	check(room.weapon.loadout == loadout and room.weapon.firearm.definition == PISTOL and room.weapon.firearm.magazine == 12
		and loadout.active_slot == 1 and loadout.weapon_at(2) == null and room.player.reserve_for(AMMO_9) == 36
		and room.player.reserve_for(AMMO_45) == 0 and not state.is_collected(PICKUP), "defeat restart restores the original pistol-only loadout")
	await move_actor(room, (room.get_node("WarehouseEntrance") as SidePortal).position)
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	var restored := room.get_node_or_null("HeavyPistolPickup") as SideWeaponPickup
	check(restored != null and restored.visible, "Heavy Pistol pickup reappears after explicit restart")
	room.audio.warehouse.stop()
	await settle(8)
	unload_current_scene()
	await settle()
	if failures == 0:
		print("PASS: run-owned weapon slots, live acquisition and ammo, guarded switching/reload, both production firearms, travel and defeat reset")
	quit(0 if failures == 0 else 1)
