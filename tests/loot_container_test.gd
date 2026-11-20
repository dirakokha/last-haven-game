extends SceneTree

const COURT := "res://scenes/side/Court.tscn"
const WAREHOUSE := "res://scenes/side/Warehouse.tscn"
const SUPPLY := preload("res://assets/loot/warehouse_supply.tres")
const AMMO := &"ammo.9mm"
const HEAVY_AMMO := &"ammo.45acp"
const SCRAP := &"resource.scrap_metal"
const PICKUP := &"warehouse.pickup.9mm.01"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, context: String) -> void:
	if not value:
		failures += 1
		push_error(context)

func definitions_and_transfers() -> void:
	var catalog := ItemCatalog.new()
	var invalid_entry := LootEntryDef.new()
	check(not invalid_entry.is_valid(), "an entry without an item is invalid")
	invalid_entry.item = ItemDef.new()
	check(not invalid_entry.is_valid(), "an invalid item definition is rejected")
	invalid_entry.item = ItemCatalog.AMMO_9MM
	invalid_entry.quantity = 0
	check(not invalid_entry.is_valid() and SUPPLY.entries[0].is_valid(), "quantity must be positive")
	var bad := LootContainerDef.new()
	bad.definition_id = &"test.loot.invalid_recipe"
	bad.entries = [SUPPLY.entries[0], SUPPLY.entries[0]]
	check(bad.create_inventory(catalog) == null, "a recipe cannot contain duplicate item IDs")
	bad.entries = SUPPLY.entries.duplicate()
	bad.capacity = 0
	check(bad.create_inventory(catalog) == null, "zero container capacity is rejected")
	bad.capacity = 1
	check(bad.create_inventory(catalog) == null, "all authored quantities must fit")
	var conflicting := ItemCatalog.AMMO_9MM.duplicate() as ItemDef
	conflicting.max_stack = 40
	var incompatible := ItemCatalog.new([conflicting, ItemCatalog.SCRAP_METAL, ItemCatalog.AMMO_45ACP])
	check(SUPPLY.create_inventory(incompatible) == null, "a recipe cannot override catalog stack rules")
	var state := SideRunState.new()
	var source := state.container_inventory(&"test.a", SUPPLY)
	var other := state.container_inventory(&"test.b", SUPPLY)
	check(source != null and source.capacity == 4 and source.count(AMMO) == 24 and source.count(SCRAP) == 5,
		"the authored production recipe seeds both items")
	var destination := SideInventory.new(1)
	check(destination.add(AMMO, 43) and source.add(AMMO, 6), "fixture sets up exactly 7 rounds of destination space")
	var observations: Array[Vector2i] = []
	var observe := func() -> void:
		observations.append(Vector2i(source.count(AMMO), destination.count(AMMO)))
		check(not source.remove(AMMO, 1) and not destination.remove(AMMO, 1)
			and source.transfer_to(destination, AMMO, 1) == 0, "both inventories block reentrant mutation")
	source.changed.connect(observe)
	destination.changed.connect(observe)
	check(source != other and source.transfer_to(destination, AMMO, 30) == 7
		and other.count(AMMO) == 24, "partial transfer moves seven and does not affect a different placement")
	check(source.count(AMMO) == 23 and destination.count(AMMO) == 50 and observations == [Vector2i(23, 50), Vector2i(23, 50)],
		"both signals see fully committed quantities and conserve all 73 rounds")
	check(source.transfer_to(destination, AMMO, 1) == 0 and source.transfer_to(null, AMMO, 1) == 0
		and source.transfer_to(source, AMMO, 1) == 0 and source.transfer_to(destination, AMMO, 0) == 0
		and observations.size() == 2 and source.count(AMMO) == 23 and destination.count(AMMO) == 50,
		"full/invalid requests do not mutate or notify")
	source.changed.disconnect(observe)
	destination.changed.disconnect(observe)
	check(source.transfer_to(SideInventory.new(1, incompatible), AMMO, 10) == 0 and source.count(AMMO) == 23,
		"same ID with incompatible rules does not transfer")
	var bags := SideInventory.new(2)
	check(source.transfer_to(bags, SCRAP, 5, 1) == 5 and bags.count(SCRAP) == 5 and source.count(SCRAP) == 0,
		"a whole selected resource stack transfers unchanged")
	check(source.add(AMMO, 37) and source.transfer_to(bags, AMMO, 12, 0) == 12
		and source.stack_rows()[0].quantity == 38 and source.stack_rows()[2].quantity == 10,
		"slot-specific transfers deplete the selected stack first")
	check(state.container_inventory(&"test.a", SUPPLY) == source and state.reset()
		and source.count(AMMO) == 24 and source.count(SCRAP) == 5,
		"placement lookup reuses runtime state and reset restores its recipe")

func placement_identity() -> void:
	var state := SideRunState.new()
	var original := state.container_inventory(&"test.identity", SUPPLY)
	var copy := SUPPLY.duplicate() as LootContainerDef
	check(original != null and state.container_inventory(&"test.identity", SUPPLY) == original
		and state.container_inventory(&"test.identity", copy) == original,
		"identical authored values reuse the inventory even on a different definition resource instance")
	copy.definition_id = &"test.loot.conflict"
	check(state.container_inventory(&"test.identity", copy) == null, "same placement rejects a different definition ID")
	copy.definition_id = SUPPLY.definition_id
	copy.capacity += 1
	check(state.container_inventory(&"test.identity", copy) == null, "same placement and definition ID reject different capacity")
	copy.capacity = SUPPLY.capacity
	var entry := LootEntryDef.new()
	entry.item = ItemCatalog.AMMO_9MM
	entry.quantity = 23
	copy.entries = [entry, SUPPLY.entries[1], SUPPLY.entries[2]]
	check(state.container_inventory(&"test.identity", copy) == null, "same placement and definition ID reject different quantities")
	var different_rules := ItemCatalog.AMMO_9MM.duplicate() as ItemDef
	different_rules.max_stack -= 1
	entry.item = different_rules
	entry.quantity = 24
	check(state.container_inventory(&"test.identity", copy) == null, "same placement rejects incompatible item rules")
	copy.entries = SUPPLY.entries.duplicate()
	copy.definition_id = &""
	check(copy.create_inventory(ItemCatalog.new()) == null, "blank container definition ID is invalid")
	copy.definition_id = &"Bad..Loot"
	check(copy.create_inventory(ItemCatalog.new()) == null, "malformed container definition ID is invalid")
	var independent := state.container_inventory(&"test.other", SUPPLY)
	check(state.container_inventory(&"test.identity", SUPPLY) == original and original.count(AMMO) == 24
		and original.remove(AMMO, 1) and independent != original and independent.count(AMMO) == 24,
		"rejected requests never replace stock and different placement IDs stay independent")

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

func move_actor(room: SideRoom, point: Vector2) -> void:
	room.player.position = point
	room.player.velocity = Vector2.ZERO
	await settle()

func run() -> void:
	definitions_and_transfers()
	placement_identity()
	create_timer(20.0).timeout.connect(func() -> void:
		push_error("Loot integration timed out")
		quit(1))
	root.size = Vector2i(960, 540)
	if change_scene_to_file(COURT) != OK:
		quit(1)
		return
	await scene_changed
	var room := current_scene as SideRoom
	room.walker.active = false
	await move_actor(room, (room.get_node("WarehouseEntrance") as SidePortal).position)
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	await settle()
	var crate := room.get_node("SupplyCrate") as SideLootContainer
	var panel: SideLootPanel = room.hud.loot_panel
	var bag := room.player.inventory
	var stock := crate.contents
	var state := SideRunState.for_tree(self)
	await press(KEY_E)
	check(not panel.visible and not crate.activate(room.player), "E cannot open the crate outside its reach")
	await move_actor(room, (room.get_node("AmmoPickup") as SideAmmoPickup).position)
	await press(KEY_E)
	check(not panel.visible and bag.count(AMMO) == 48 and state.is_collected(PICKUP), "existing E pickup still grants twelve independently")
	check(room.player.take_reserve(AMMO, 5) == 5 and bag.add(SCRAP, 100), "fixture fills slots with exactly seven rounds of space")
	check(room.player.reserve_for(SCRAP) == 0 and room.player.take_reserve(SCRAP, 1) == 0,
		"production scrap is not firearm reserve")
	await move_actor(room, crate.position)
	check(room.select_interactable() == crate and room.hud.prompt.text == "\u2066E\u2069 — OPEN", "authored crate shows E — OPEN")
	await press(KEY_ESCAPE)
	await press(KEY_E)
	check(paused and not panel.visible and not crate.activate(room.player), "normal pause blocks opening loot")
	await press(KEY_ESCAPE)
	await press(KEY_E)
	check(panel.is_visible_in_tree() and paused and not room.hud.result.visible, "E opens the actual modal and freezes gameplay")
	var rect := panel.get_global_rect()
	check(rect.size.x >= 720 and rect.size.y >= 352 and root.get_visible_rect().encloses(rect),
		"actual Loot panel rectangle fits the viewport")
	check(panel.loot_title.text == "LOOT" and panel.inventory_title.text.begins_with("INVENTORY  ·  SLOTS")
		and panel.controls.text.contains("Enter — TAKE") and panel.controls.text.contains("Esc — CLOSE"), "standard UI terms remain English")
	check(panel.loot_list.get_item_text(0).contains("فشنگ ۹ میلی‌متری") and panel.loot_list.get_item_text(1).contains("قطعات فلزی"),
		"real production item names remain Persian")
	check(stock.count(AMMO) == 24 and stock.count(SCRAP) == 5 and bag.count(AMMO) == 43, "opening alone grants nothing")
	var origin := room.player.position
	await press(KEY_W)
	await press(KEY_E)
	await press(KEY_D)
	await press(KEY_TAB)
	check(room.player.position == origin and not room.transitioning and panel.visible and not room.hud.inventory_panel.visible,
		"the modal blocks walking, other interactions and Tab")
	await press(KEY_DOWN)
	check(panel.loot_list.is_selected(1), "Down highlights the scrap stack")
	await press(KEY_UP)
	check(panel.loot_list.is_selected(0), "Up selects ammunition")
	await press(KEY_ENTER)
	check(stock.count(AMMO) == 17 and bag.count(AMMO) == 50 and panel.loot_list.get_item_text(0).contains("\u206617\u2069")
		and panel.player_list.get_item_text(0).contains("\u206650\u2069") and panel.status.text == "INSUFFICIENT CAPACITY"
		and room.weapon.firearm.magazine == 12, "Enter shows a conserved partial grant immediately, with no magazine change")
	await press(KEY_ENTER)
	check(stock.count(AMMO) == 17 and bag.count(AMMO) == 50 and panel.status.text == "INVENTORY FULL",
		"a full destination preserves the remainder and reports the failure")
	await press(KEY_ESCAPE)
	check(not panel.visible and not paused and stock.count(AMMO) == 17, "Esc restores gameplay without changing stock")

	await move_actor(room, (room.get_node("CourtEntrance") as SidePortal).position)
	await press(KEY_W)
	room.player.position = crate.position # In range, but the actor is already frozen for the fade.
	await press(KEY_E)
	check(room.transitioning and not panel.visible and not crate.activate(room.player), "fade blocks loot even at the crate")
	await scene_changed
	room = current_scene as SideRoom
	room.walker.active = false
	await settle()
	await press(KEY_W)
	await scene_changed
	room = current_scene as SideRoom
	crate = room.get_node("SupplyCrate") as SideLootContainer
	panel = room.hud.loot_panel
	await move_actor(room, crate.position)
	check(crate.contents == stock and stock.count(AMMO) == 17 and stock.count(SCRAP) == 5 and room.player.inventory == bag
		and room.get_node_or_null("AmmoPickup") == null, "partial crate stock, player inventory and pickup flag survive the round trip")
	check(bag.remove(AMMO, 17) and bag.remove(SCRAP, 20), "fixture frees capacity for another transfer")
	await press(KEY_E)
	await press(KEY_ENTER)
	await press(KEY_ENTER)
	check(stock.count(AMMO) == 0 and stock.count(SCRAP) == 0 and bag.count(AMMO) == 50 and bag.count(SCRAP) == 85,
		"repeat transfers the remaining 9mm and scrap without altering their quantities")
	await press(KEY_ENTER)
	check(stock.count(HEAVY_AMMO) == 12 and panel.status.text == "INVENTORY FULL", "new ammo waits in the crate until space is available")
	check(bag.remove(SCRAP, 20), "fixture frees another slot")
	await press(KEY_ENTER)
	check(stock.occupied_slots() == 0 and bag.count(HEAVY_AMMO) == 12 and panel.status.text == "EMPTY",
		"taking the final stack empties the reconstructed crate")
	await press(KEY_ESCAPE)
	room.weapon.firearm.restore_magazine(10)
	await press(KEY_R)
	await settle(75)
	check(room.weapon.firearm.magazine == 12 and bag.count(AMMO) == 48, "the original reload consumes the looted reserve")
	if change_scene_to_file(WAREHOUSE) != OK:
		quit(1)
		return
	await scene_changed
	room = current_scene as SideRoom
	crate = room.get_node("SupplyCrate") as SideLootContainer
	panel = room.hud.loot_panel
	await move_actor(room, crate.position)
	await press(KEY_E)
	check(crate.contents == stock and panel.visible and panel.status.text == "EMPTY", "rebuilding Warehouse keeps the empty crate present")
	await press(KEY_ESCAPE)
	room.take_damage(100)
	await press(KEY_E)
	check(room.defeated and not panel.visible and not crate.activate(room.player), "defeat blocks opening loot")
	key_event(KEY_ENTER, true)
	await scene_changed
	key_event(KEY_ENTER, false)
	check(stock.count(AMMO) == 24 and stock.count(SCRAP) == 5 and bag.count(AMMO) == 36
		and bag.count(SCRAP) == 0 and not state.is_collected(PICKUP), "real defeat restart resets crate, player and pickup together")
	room = current_scene as SideRoom
	if room.audio.rain != null:
		room.audio.rain.stop()
	await settle(8)
	unload_current_scene()
	await settle()
	if failures == 0:
		print("PASS: loot definitions, atomic partial transfers, real E/Up/Down/Enter/Esc modal, persistence and defeat reset")
	quit(0 if failures == 0 else 1)
