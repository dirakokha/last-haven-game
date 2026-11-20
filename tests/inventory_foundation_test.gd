extends SceneTree

const COURT := "res://scenes/side/Court.tscn"
const AMMO := &"ammo.9mm"
const PICKUP := &"warehouse.pickup.9mm.01"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, context: String) -> void:
	if not value:
		failures += 1
		push_error(context)

func sample_item(id: StringName, limit: int) -> ItemDef:
	var item := ItemDef.new()
	item.item_id = id
	item.display_name = "Test item"
	item.max_stack = limit
	return item

func inventory_model() -> void:
	var ammo: ItemDef = ItemCatalog.AMMO_9MM
	var bandage := sample_item(&"test.item", 4)
	var invalid := sample_item(&" Bad..ID", 1)
	var zero_limit := sample_item(&"test.zero", 0)
	var duplicate := sample_item(bandage.item_id, 9)
	var rejected_catalog := ItemCatalog.new([bandage, duplicate])
	var catalog := ItemCatalog.new([ammo, bandage])
	check(ammo.is_valid() and ammo.item_id == preload("res://assets/weapons/pistol.tres").ammo_id
		and catalog.definition_for(AMMO) == ammo, "production 9mm definition resolves the pistol's exact ID")
	check(not invalid.is_valid() and not ItemCatalog.new([invalid]).is_valid(), "malformed IDs are rejected")
	check(not zero_limit.is_valid() and not ItemCatalog.new([zero_limit]).is_valid(), "zero stack limit is rejected")
	check(not rejected_catalog.is_valid() and rejected_catalog.definition_for(bandage.item_id) == null,
		"duplicates reject the whole catalog, never overriding a definition")

	var id := bandage.item_id
	var inventory := SideInventory.new(2, catalog)
	var observed: Array[int] = []
	var observe := func() -> void:
		observed.append(inventory.count(id))
		check(not inventory.add(id, 1), "observer may read committed state but not mutate it reentrantly")
	inventory.changed.connect(observe)
	check(inventory.capacity == 2 and inventory.occupied_slots() == 0, "configured capacity starts empty")
	check(inventory.can_add(id, 3) and inventory.add(id, 3) and inventory.occupied_slots() == 1, "add in an empty slot")
	check(inventory.add(id, 1) and inventory.stack_rows()[0].quantity == 4, "adds merge up to the limit")
	check(inventory.add(id, 3) and inventory.occupied_slots() == 2 and inventory.stack_rows()[1].quantity == 3,
		"overflow creates another stack and preserves the exact total")
	var layout := inventory.stack_rows()
	check(not inventory.can_add(id, 2) and not inventory.add(id, 2) and not inventory.add(AMMO, 1),
		"full slots cannot accept another stack, even when one unit would fit in an existing stack")
	check(not inventory.add(id, 0) and not inventory.add(&"unknown", 1) and inventory.stack_rows() == layout,
		"invalid or partially fitting transactions leave every slot unchanged")
	layout[0].quantity = 0
	check(inventory.count(id) == 7, "UI snapshots cannot mutate live stack quantities")
	check(not inventory.can_remove(id, 8) and not inventory.remove(id, 8)
		and inventory.can_remove(id, 4) and inventory.remove(id, 4) and inventory.count(id) == 3
		and inventory.occupied_slots() == 1, "reject over-removal and remove exactly across stacks")
	check(observed == [3, 4, 7, 3], "one notification after each successful transaction, none on rejected input")
	# Explicitly disconnect the listener capturing its inventory in this fixture.
	inventory.changed.disconnect(observe)
	var initial: Dictionary[StringName, int] = {id: 3}
	var seeded := SideInventory.new(2, catalog, initial)
	initial[id] = 7
	check(seeded.count(id) == 3 and seeded.remove(id, 1) and inventory.count(id) == 3,
		"inventories share definitions but not mutable stack quantities")
	seeded.clear()
	check(seeded.occupied_slots() == 0 and seeded.add(AMMO, 12) and seeded.reset()
		and seeded.count(id) == 3 and seeded.count(AMMO) == 0, "reset replaces live stock with copied initial values")
	var invalid_initial: Dictionary[StringName, int] = {id: 2, AMMO: 100}
	var bad_seed := SideInventory.new(1, catalog, invalid_initial)
	check(bad_seed.occupied_slots() == 0 and bad_seed.add(id, 1) and not bad_seed.reset()
		and bad_seed.count(id) == 1, "an invalid loadout never partially commits or clears live stock")
	var player := SidePlayer.new(SidePlayer.MAX_HEALTH, seeded)
	check(player.reserve_for(id) == 0 and not player.add_reserve(id, 1) and player.take_reserve(id, 1) == 0,
		"reserve API rejects non-ammunition definitions even when present in inventory")
	player.free()

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
	inventory_model()
	create_timer(16.0).timeout.connect(func() -> void:
		push_error("Inventory integration timed out")
		quit(1))
	root.size = Vector2i(960, 540)
	if change_scene_to_file(COURT) != OK:
		quit(1)
		return
	await scene_changed
	var room := current_scene as SideRoom
	room.walker.active = false
	await settle()
	var run_state := SideRunState.for_tree(self)
	var inventory := room.player.inventory
	var panel: SideInventoryPanel = room.hud.inventory_panel
	check(inventory == run_state.inventory and inventory.count(AMMO) == 36 and room.player.reserve_for(AMMO) == 36
		and room.weapon.firearm.magazine == 12, "live Court player uses the run inventory and approved loadout")
	await press(KEY_TAB)
	check(panel.visible and paused and not room.hud.result.visible, "Tab opens the panel and pauses gameplay")
	var origin := room.player.position
	await press(KEY_D)
	check(room.player.position == origin, "paused gameplay does not move while the panel is open")
	check(panel.slots.text.contains("1 / 6") and panel.items.text.contains("فشنگ ۹ میلی‌متری")
		and panel.items.text.contains("\u206636\u2069") and panel.items.text.contains("\u2066ammo.9mm\u2069"),
		"panel shows real slot count, localized name, isolated quantity and ID")
	inventory.clear()
	check(panel.items.text == "موجودی خالی است" and panel.slots.text.contains("0 / 6"), "committed clear refreshes the empty state immediately")
	inventory.reset()
	check(panel.items.text.contains("\u206636\u2069"), "committed reset refreshes counts immediately")
	await press(KEY_TAB)
	check(not panel.visible and not paused, "Tab closes and restores live gameplay")
	await press(KEY_TAB)
	await press(KEY_ESCAPE)
	check(not panel.visible and not paused, "Esc closes inventory instead of opening the pause screen")
	await press(KEY_ESCAPE)
	await press(KEY_TAB)
	check(paused and panel.visible, "inventory can overlay an existing pause")
	await press(KEY_ESCAPE)
	check(not panel.visible and paused and room.hud.result.visible, "closing inventory preserves the previous pause")
	await press(KEY_ESCAPE)

	Input.action_press("fire")
	await settle(2)
	Input.action_release("fire")
	check(room.weapon.firearm.magazine == 11 and inventory.count(AMMO) == 36, "one live shot consumes only a loaded round")
	await settle(16) # The unchanged pistol rejects reload during shot cooldown.
	await press(KEY_R)
	check(room.weapon.reload_left > 0.0, "R starts an actual inventory-backed reload once cooldown ends")
	await settle(75)
	check(room.weapon.firearm.magazine == 12 and inventory.count(AMMO) == 35
		and room.player.reserve_for(AMMO) + room.weapon.firearm.magazine == 47,
		"reload removes exactly what was loaded, totaling initial ammunition minus one shot")

	await move_actor(room, (room.get_node("WarehouseEntrance") as SidePortal).position)
	await press(KEY_W)
	await press(KEY_TAB)
	check(room.transitioning and not panel.visible and not paused, "Tab cannot open during the fade")
	var transfer: Dictionary = get_meta(SideRoom.TRANSFER)
	check(not transfer.has("reserve"), "room payload does not duplicate reserve ownership")
	await scene_changed
	room = current_scene as SideRoom
	await move_actor(room, Vector2(410, 425))
	var pickup := room.get_node("AmmoPickup") as SideAmmoPickup
	check(room.player.inventory == inventory and inventory.count(AMMO) == 35 and room.weapon.firearm.magazine == 12,
		"Warehouse receives the same inventory and magazine without re-seeding")
	var nearly_full: int = inventory.capacity * ItemCatalog.AMMO_9MM.max_stack - 11
	check(room.player.add_reserve(AMMO, nearly_full - 35) and inventory.occupied_slots() == inventory.capacity,
		"fixture fills all slots with only eleven rounds of room left")
	await press(KEY_E)
	check(pickup.visible and room.select_interactable() == pickup and not pickup.activate(room.player)
		and not run_state.is_collected(PICKUP)
		and inventory.count(AMMO) == nearly_full, "failed pickup stays in the world and makes no partial grant")
	check(room.player.take_reserve(AMMO, nearly_full - 35) == nearly_full - 35, "free reserve space across stacks")
	await press(KEY_E)
	await press(KEY_E)
	check(run_state.is_collected(PICKUP) and room.get_node_or_null("AmmoPickup") == null
		and inventory.count(AMMO) == 47 and room.weapon.firearm.magazine == 12, "the same box grants twelve once, never to the magazine")
	await move_actor(room, (room.get_node("CourtEntrance") as SidePortal).position)
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	room.walker.active = false
	await settle()
	check(room.player.inventory == inventory and room.player.reserve_for(AMMO) == 47 and room.weapon.firearm.magazine == 12,
		"the exact inventory and reload state survive the round trip")
	room.take_damage(100)
	await press(KEY_TAB)
	check(room.defeated and not room.hud.inventory_panel.visible and not paused, "Tab cannot open after defeat")
	key_event(KEY_ENTER, true)
	await scene_changed
	key_event(KEY_ENTER, false)
	room = current_scene as SideRoom
	await settle()
	check(room.player.inventory == inventory and inventory.count(AMMO) == 36 and inventory.occupied_slots() == 1
		and room.weapon.firearm.magazine == 12 and not run_state.is_collected(PICKUP),
		"explicit defeat restart resets inventory and collected placements without adding a second loadout")
	if room.audio.rain != null:
		room.audio.rain.stop()
	await settle(8)
	unload_current_scene()
	await settle()
	if failures == 0:
		print("PASS: item definitions, inventory transactions and signals, live ammunition, capacity-safe pickup, run ownership and Tab/Esc panel")
	quit(0 if failures == 0 else 1)
