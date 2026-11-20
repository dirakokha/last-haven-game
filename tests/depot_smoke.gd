extends SceneTree

const DEPOT := "res://scenes/combat/Depot.tscn"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Depot smoke: " + description)

func tick(count: int = 2) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func send_key(physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = InputEventKey.new()
	event.physical_keycode = physical
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	if change_scene_to_file(DEPOT) != OK:
		quit(1)
		return
	await scene_changed
	var depot := current_scene
	var actors := depot.get_node("Yard/FloorActors") as Node2D
	var player := actors.get_node("Player") as CharacterBody2D
	var hud := depot.get_node("HUD/Instruments") as ProofHUD
	var weather := depot.get_node("Yard/Weather") as ProofWeather
	var weapon: DepotWeapon
	var survivor: SurvivorArt
	for child in player.get_children():
		if child is DepotWeapon:
			weapon = child
		elif child is SurvivorArt:
			survivor = child
	if weapon == null or survivor == null:
		check(false, "weapon and presentation must attach to the same gameplay actor")
		quit(1)
		return
	check(root.content_scale_size == Vector2i(960, 540), "design viewport is 960×540")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT, "scale the pixel buffer, not individual items")
	check(root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER, "integer scale")
	if DisplayServer.get_name() == "headless":
		var original_size: Vector2i = root.size
		root.size = Vector2i(960, 540)
		check(root.get_final_transform().get_scale().is_equal_approx(Vector2.ONE), "native window maps each design pixel once")
		root.size = Vector2i(1920, 1080)
		check(root.get_final_transform().get_scale().is_equal_approx(Vector2(2, 2)), "double window maps design pixels at 2x")
		root.size = original_size
	check(actors.y_sort_enabled, "actors sort on their existing floor pins")
	var cargo := actors.get_node_or_null("CrateFeet/CargoArt") as Sprite2D
	check(cargo != null and cargo.is_visible_in_tree(), "obstacle sprite attached to original body")
	check(weapon.magazine == 12 and weapon.reserve == 36, "original ammunition")
	var enemies := get_nodes_in_group("infected")
	check(enemies.size() == 4, "original encounter composition")
	if enemies.size() != 4:
		quit(1)
		return
	# Freeze fixture AI only while exercising movement and the real direct-space query.
	for enemy in enemies:
		enemy.set_physics_process(false)
	var walker := enemies[0] as DepotZombie
	await tick()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		# Optional graphical capture before any fixture positions are changed.
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		check(image.get_size() == Vector2i(960, 540), "captured pixel buffer is native")
		print("Capture buffer ", image.get_size(), "; window ", root.size)
		image.save_png("user://depot_960_buffer.png")

	var start: Vector2 = player.position
	Input.action_press("move_right")
	await tick(12)
	Input.action_release("move_right")
	check(player.position.x > start.x + 20.0 and is_equal_approx(player.position.y, start.y), "horizontal movement")
	check(survivor.region_rect != Rect2(), "an atlas cel is selected on the moving actor")
	start = player.position
	Input.action_press("move_far")
	await tick(12)
	Input.action_release("move_far")
	check(player.position.y < start.y - 10.0, "independent depth movement")
	await tick()
	player.position = Vector2(490, 325)
	await tick()
	Input.action_press("move_right")
	await tick(20)
	Input.action_release("move_right")
	check(player.position.x > 505.0 and player.position.x < 510.0, "case still blocks the player's circle at the floor pin")
	await tick()

	send_key(KEY_F2)
	check(not weather.rain_enabled and not hud.rain and not weather.is_processing(), "rain toggle suspends particle work")
	send_key(KEY_F3)
	check(not depot.get_node("Yard/Footlights").visible and not hud.lamps, "optional glow toggles independently")
	send_key(KEY_ESCAPE)
	check(paused, "Phase 1 pause still works")
	send_key(KEY_ESCAPE)
	check(not paused, "Phase 1 resume still works")

	player.position = Vector2(420, 325)
	walker.position = Vector2(630, 325)
	await tick()
	weapon.aim = Vector2.RIGHT
	weapon.shoot()
	check(weapon.magazine == 11 and walker.hp == 65, "cover blocks the existing ray and still spends a round")

	player.position = Vector2(420, 299)
	walker.position = Vector2(630, 299)
	await tick()
	weapon.aim = Vector2.RIGHT
	weapon.shoot()
	check(weapon.magazine == 10 and walker.hp == 41, "clear ground-depth ray inflicts original damage")
	check(weapon.trace_end.is_equal_approx(Vector2(202, -18)), "hit tracer keeps its 18 px lift above the ground hit")
	await tick(17)
	# Drive the normal key handler, not the reload math, through one physics tick.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await tick()
	key = InputEventKey.new()
	key.physical_keycode = KEY_R
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(weapon.reload_left > 0.0, "reload has begun")
	await tick(72)
	check(weapon.magazine == 12 and weapon.reserve == 34, "reload transfers exactly two rounds")

	# Restore AI for an actual warning/lunge/contact check.
	walker.position = player.position + Vector2(24, 0)
	walker.set_physics_process(true)
	await tick(12)
	check(walker.state == DepotZombie.State.WARN, "Walker warns before lunging")
	check(walker.art.region_rect.position.y == 44.0, "warning selects the warning atlas sequence")
	await tick(34)
	check(hud.health == 85, "Walker attack uses original contact damage")
	walker.set_physics_process(false)
	await tick()

	for enemy in enemies:
		enemy.hurt(100, Vector2.ZERO)
	await tick()
	check(get_nodes_in_group("infected").is_empty(), "dead bodies leave combat immediately")
	check(hud.enemies == 0 and hud.result == 1, "victory state preserved")
	await create_timer(0.5).timeout
	var corpses := 0
	for child in actors.get_children():
		if child is WalkerArt and child.corpse:
			corpses += 1
			check(child.region_rect.position == Vector2(112, 132), "death finishes even under a frozen yard")
	check(corpses == 4, "inert depth-sorted death cels preserve every actor's last pin")

	unload_current_scene()
	await tick(3)
	if failures == 0:
		print("PASS: Depot input, viewport, cover, ammo/reload, Walker attack, death, and victory")
	quit(0 if failures == 0 else 1)
