extends SceneTree

const COURT := "res://scenes/side/Court.tscn"
const AMMO := &"ammo.9mm"
const PICKUP := &"warehouse.pickup.9mm.01"
const BOX_POSITION := Vector2(410, 425)
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func settle(count: int = 3) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func key_event(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func press(code: Key) -> void:
	key_event(code, true)
	await settle(2)
	key_event(code, false)

func move_actor(room: SideRoom, point: Vector2) -> void:
	room.player.position = point
	room.player.velocity = Vector2.ZERO
	await settle()

func run() -> void:
	create_timer(16.0).timeout.connect(func() -> void:
		push_error("Side interaction test timed out")
		quit(1))
	root.size = Vector2i(960, 540)
	var unrelated := preload("res://tests/fixtures/unrelated_ammo.tres")
	set_meta(SideRunState.KEY, SideRunState.new(ItemCatalog.new([ItemCatalog.AMMO_9MM, unrelated])))
	if change_scene_to_file(COURT) != OK:
		quit(1)
		return
	await scene_changed
	var room := current_scene as SideRoom
	room.walker.active = false
	await settle()
	check(room.select_interactable() == null and not room.hud.prompt.visible, "no interaction at Court spawn")
	var portal := room.get_node("WarehouseEntrance") as SidePortal
	await move_actor(room, portal.position)
	check(room.select_interactable() == portal and portal.input_action == &"side_entrance",
		"room discovers the authored portal with side_entrance")
	check(room.hud.prompt.visible and room.hud.prompt.text == "\u2066W\u2069 — ورود به انبار",
		"Persian portal prompt displays isolated W")
	await press(KEY_E)
	check(not room.transitioning, "E cannot activate the selected W door")
	var destination := portal.destination
	portal.destination = "res://scenes/side/Missing.tscn"
	await press(KEY_W)
	check(room.select_interactable() == null and not room.transitioning and not portal.activate(room.player),
		"an invalid portal destination cannot start travel")
	portal.destination = destination
	room.weapon.firearm.restore_magazine(7)
	await press(KEY_W)
	check(room.transitioning and not portal.activate(room.player), "W starts only one transition")
	await scene_changed
	room = current_scene as SideRoom
	await settle()
	var pickup := room.get_node("AmmoPickup") as SideAmmoPickup
	check(room.indoor and room.player.position.is_equal_approx(Vector2(265, 425)), "W arrives at the Warehouse marker")
	check(room.select_interactable() == room.get_node("CourtEntrance") and room.hud.prompt.text == "\u2066W\u2069 — خروج به محوطه",
		"Warehouse return portal uses W and its Persian prompt")
	await press(KEY_E)
	check(not pickup.activate(room.player) and room.player.reserve_for(AMMO) == 36,
		"E and a direct request outside pickup reach do not grant reserve")

	await move_actor(room, BOX_POSITION)
	check(room.select_interactable() == pickup and pickup.input_action == &"side_interact",
		"room discovers generic E interaction")
	check(room.hud.prompt.visible and room.hud.prompt.text == "\u2066E\u2069 — برداشتن فشنگ ۹ میلی‌متری",
		"Persian pickup prompt displays isolated E")
	await press(KEY_W)
	check(not room.transitioning and room.player.reserve_for(AMMO) == 36, "W cannot activate the selected pickup")

	var other := SideAmmoPickup.new()
	other.position = BOX_POSITION + Vector2(10, 0)
	other.placement_id = &"test.pickup"
	room.add_child(other)
	check(room.select_interactable() == pickup, "nearest valid interaction wins regardless of ID")
	other.position = BOX_POSITION
	check(room.select_interactable() == other, "equal distance uses stable lexical placement ID")
	other.position.y -= other.vertical_tolerance + 1.0
	check(room.select_interactable() == pickup and not other.activate(room.player), "vertical tolerance excludes another level")
	other.position = BOX_POSITION
	other.enabled = false
	check(room.select_interactable() == pickup and not other.activate(room.player), "disabled entries are ignored")
	other.queue_free()
	var outsider := SideAmmoPickup.new()
	outsider.placement_id = &"outside.current.room"
	outsider.position = BOX_POSITION
	root.add_child(outsider)
	check(room.select_interactable() == pickup, "other scene branches cannot win room selection")
	outsider.queue_free()

	await press(KEY_ESCAPE)
	await press(KEY_E)
	check(paused and not room.hud.prompt.visible and not pickup.activate(room.player)
		and room.player.reserve_for(AMMO) == 36, "pause blocks E and direct activation")
	await press(KEY_ESCAPE)
	await press(KEY_SPACE)
	await press(KEY_E)
	check(not room.player.is_on_floor() and room.select_interactable() == null and not pickup.activate(room.player)
		and room.player.reserve_for(AMMO) == 36, "airborne E cannot collect the pickup")

	# Start a real fade, then move the frozen actor to the box to exercise the
	# transition guard independently of the distance and grounded checks.
	var return_portal := room.get_node("CourtEntrance") as SidePortal
	await move_actor(room, return_portal.position)
	await press(KEY_W)
	check(room.transitioning and room.player.is_on_floor(), "W starts the real return fade from the floor")
	room.player.position = BOX_POSITION
	await press(KEY_E)
	check(room.transitioning and room.select_interactable() == null and not pickup.activate(room.player)
		and room.player.reserve_for(AMMO) == 36, "the fade blocks pickup even at the box")
	await scene_changed
	room = current_scene as SideRoom
	room.walker.active = false
	await settle()
	check(not room.indoor and room.player.position.is_equal_approx(Vector2(680, 425)), "W returns to the Court marker")
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	await move_actor(room, BOX_POSITION)
	pickup = room.get_node("AmmoPickup") as SideAmmoPickup
	var rounds: int = pickup.rounds
	var duplicate := pickup.duplicate() as SideAmmoPickup
	duplicate.name = "DuplicatePlacement"
	check(rounds == 12 and pickup.placement_id == PICKUP and pickup.visible, "authored box offers exactly 12 rounds")
	room.player.add_reserve(&"ammo.test.unrelated", 3)
	pickup.rounds = 0
	await press(KEY_E)
	check(is_instance_valid(pickup) and room.player.reserve_for(AMMO) == 36, "invalid grant does not consume the placement")
	pickup.rounds = rounds
	await press(KEY_E)
	check(room.player.reserve_for(AMMO) == 36 + rounds and room.weapon.firearm.magazine == 7
		and room.player.reserve_for(&"ammo.test.unrelated") == 3, "E adds only configured 9mm reserve, not magazine or other ammo")
	check(room.hud.reserve_count.text == "ذخیره ۴۸" and not room.hud.prompt.visible, "HUD updates reserve and clears consumed prompt")
	room.add_child(duplicate)
	check(not duplicate.visible and not duplicate.activate(room.player), "the same placement ID is rejected immediately on rebuild")
	await press(KEY_E)
	check(not is_instance_valid(pickup) and not is_instance_valid(duplicate) and room.player.reserve_for(AMMO) == 48,
		"repeated E cannot grant ammo twice")

	await move_actor(room, (room.get_node("CourtEntrance") as SidePortal).position)
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	room.walker.active = false
	await settle()
	check(room.player.reserve_for(AMMO) == 48 and room.weapon.firearm.magazine == 7, "added ammo crosses into Court")
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	await move_actor(room, BOX_POSITION)
	check(room.get_node_or_null("AmmoPickup") == null and room.select_interactable() == null,
		"collected placement stays absent on return")
	await press(KEY_E)
	check(room.player.reserve_for(AMMO) == 48, "round trip preserves added ammo without a second grant")

	room.take_damage(100)
	check(room.defeated, "defeat permits explicit restart")
	key_event(KEY_ENTER, true)
	await scene_changed
	key_event(KEY_ENTER, false)
	room = current_scene as SideRoom
	room.walker.active = false
	await move_actor(room, (room.get_node("WarehouseEntrance") as SidePortal).position)
	check(not room.defeated and room.player.reserve_for(AMMO) == 36 and room.weapon.firearm.magazine == 12,
		"Enter starts a fresh life with the approved loadout")
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	await move_actor(room, BOX_POSITION)
	pickup = room.get_node_or_null("AmmoPickup") as SideAmmoPickup
	check(pickup != null and room.select_interactable() == pickup, "defeat restart restores the collected placement")
	room.take_damage(100)
	await press(KEY_E)
	check(room.defeated and room.select_interactable() == null and pickup != null and not pickup.activate(room.player)
		and room.player.reserve_for(AMMO) == 36, "defeated actor cannot collect an unconsumed pickup")
	# Let the audio server release the room's ambient playback before exit.
	room.audio.warehouse.stop()
	await settle(8)
	unload_current_scene()
	await settle()
	if failures == 0:
		print("PASS: shared interaction discovery, W/E prompts and guards, 9mm transaction, return persistence and defeat reset")
	quit(0 if failures == 0 else 1)
