class_name SideRoom
extends Node2D

const PISTOL := preload("res://assets/weapons/pistol.tres")
const STARTING_PISTOL_RESERVE := 36
const COURT := "res://scenes/side/Court.tscn"
const FLOOR := 425.0
const TRANSFER := &"side_transfer"
@export var room_width := 1500
@export var indoor := false
var world := Node2D.new()
var player: SidePlayer
var weapon := SideWeapon.new(PISTOL)
var camera := Camera2D.new()
var walker: SideWalker
var view := SideReviewView.new()
var audio := SideReviewAudio.new()
var hud := SideHUD.new()
var effects := SideEffects.new()
var rain_enabled := true
var portals: Array[SidePortal] = []
# This snapshot is only needed in a room with no live Walker instance.
var _absent_walker_hp := 0
var transitioning := false
var defeated: bool:
	get:
		return player != null and player.vitals.is_depleted()

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	for node in get_children():
		if node is SidePortal:
			portals.append(node)
	rain_enabled = SideWeatherPreferences.read()
	var transfer := get_tree().get_meta(TRANSFER, {}) as Dictionary
	if get_tree().has_meta(TRANSFER):
		get_tree().remove_meta(TRANSFER)
	var marker := get_node_or_null(NodePath(String(transfer.get("arrival", &"Start")))) as Marker2D
	if marker == null:
		marker = $Start
	player = SidePlayer.new(int(transfer.get("health", SidePlayer.MAX_HEALTH)))
	player.vitals.depleted.connect(_on_player_depleted)
	weapon.firearm.restore_magazine(int(transfer.get("magazine", PISTOL.magazine_capacity)))
	player.add_reserve(PISTOL.ammo_id, int(transfer.get("reserve", STARTING_PISTOL_RESERVE)))
	var walker_spawn_hp := int(transfer.get("walker_hp", SideWalker.MAX_HEALTH))

	add_child(world)
	add_solid(Rect2(0, FLOOR, room_width, 120), &"concrete")
	add_solid(Rect2(-32, 0, 32, 545), &"concrete")
	add_solid(Rect2(room_width, 0, 32, 545), &"concrete")
	if not indoor:
		add_solid(Rect2(465, FLOOR - 44, 70, 44), &"metal")
	player.position = marker.position
	player.collision_layer = 2
	player.collision_mask = 1 | 4
	add_shape(player, Vector2(32, 96), Vector2(0, -48))
	world.add_child(player)
	var listener := AudioListener2D.new()
	player.add_child(listener)
	listener.make_current()
	weapon.name = "Weapon"
	player.add_child(weapon)
	player.add_child(SideReviewArt.new())
	add_child(audio)
	audio.setup(not indoor, rain_enabled)
	effects.z_index = 2
	effects.weapon = weapon
	world.add_child(effects)
	weapon.fired.connect(audio.fire)
	weapon.fired.connect(effects.firing)
	weapon.handling.connect(audio.handling)
	weapon.hit.connect(audio.impact)
	weapon.hit.connect(effects.impact)
	effects.casing_landed.connect(audio.casing)
	player.footfall.connect(func(running: bool, surface: StringName) -> void: audio.step(player.global_position, running, surface))
	player.exerted.connect(func() -> void: audio.breath(player.global_position))
	player.damaged.connect(func(_amount: int) -> void: audio.pain(player.global_position))
	if not indoor and walker_spawn_hp > 0:
		walker = SideWalker.new(walker_spawn_hp)
		walker.position = Vector2(876, FLOOR)
		walker.target = player
		walker.collision_layer = 4
		walker.collision_mask = 1 | 2
		add_shape(walker, Vector2(31, 99), Vector2(0, -49.5))
		walker.strikes.connect(take_damage)
		walker.vocal.connect(audio.vocal)
		world.add_child(walker)
		walker.add_child(SideReviewArt.new())
	else:
		_absent_walker_hp = walker_spawn_hp
	camera.limit_left = 0
	camera.limit_right = room_width
	camera.limit_top = 0
	camera.limit_bottom = 540
	camera.position = Vector2(clampf(player.position.x, 480.0, room_width - 480.0), 270.0)
	add_child(camera)
	camera.make_current()
	view.room = self
	add_child(view)
	view.set_weather(rain_enabled)
	add_child(hud)
	if defeated:
		_on_player_depleted()

func add_shape(body: CollisionObject2D, size: Vector2, offset: Vector2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = offset
	body.add_child(shape)

func add_solid(rect: Rect2, material: StringName) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.set_meta("surface", material)
	add_shape(body, rect.size, Vector2.ZERO)
	world.add_child(body)
	return body

func _process(delta: float) -> void:
	var target := clampf(player.position.x + 70.0 * player.facing, 480.0, room_width - 480.0)
	camera.position.x = lerpf(camera.position.x, target, 1.0 - exp(-delta * 9.0))
	var prompt := ""
	if not transitioning and not defeated:
		for portal in portals:
			if portal.in_reach(player):
				prompt = portal.entrance_text
				if Input.is_action_just_pressed("side_entrance"):
					travel(portal)
				break
	hud.refresh(self, prompt)

func travel(portal: SidePortal) -> void:
	if transitioning or defeated or not portal.in_reach(player):
		return
	if not ResourceLoader.exists(portal.destination, "PackedScene"):
		hud.failure = true
		return
	transitioning = true
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var walker_hp := walker.vitals.health if is_instance_valid(walker) else _absent_walker_hp
	get_tree().set_meta(TRANSFER, {"arrival": portal.arrival, "health": player.vitals.health,
		"magazine": weapon.firearm.magazine, "reserve": player.reserve_for(PISTOL.ammo_id), "walker_hp": walker_hp})
	await hud.fade_to(1.0)
	if get_tree().change_scene_to_file(portal.destination) != OK:
		get_tree().remove_meta(TRANSFER)
		world.process_mode = Node.PROCESS_MODE_INHERIT
		transitioning = false
		hud.failure = true
		hud.fade_to(0.0)

func take_damage(amount: int) -> void:
	if not transitioning:
		player.take_damage(amount)

func _on_player_depleted() -> void:
	# Freeze game rules; the separately processing art/HUD show defeat.
	world.process_mode = Node.PROCESS_MODE_DISABLED

func toggle_rain() -> void:
	rain_enabled = not rain_enabled
	view.set_weather(rain_enabled)
	audio.set_rain(rain_enabled)
	SideWeatherPreferences.save(rain_enabled)
