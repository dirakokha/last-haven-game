class_name SideRoom
extends Node2D

const COURT := "res://scenes/side/Court.tscn"
const FLOOR := 425.0
const TRANSFER := &"side_transfer"
@export var room_width := 1500
@export var indoor := false
var world := Node2D.new()
var player := SidePlayer.new()
var weapon := SideWeapon.new()
var camera := Camera2D.new()
var walker: SideWalker
var view := SideReviewView.new()
var audio := SideReviewAudio.new()
var hud := SideHUD.new()
var portals: Array[SidePortal] = []
var health := 100
var immune := 0.0
var checkpoint_hp := 65
var transitioning := false
var defeated := false

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	for node in get_children():
		if node is SidePortal:
			portals.append(node)
	var transfer := get_tree().get_meta(TRANSFER, {}) as Dictionary
	if get_tree().has_meta(TRANSFER):
		get_tree().remove_meta(TRANSFER)
	var marker := get_node_or_null(NodePath(String(transfer.get("arrival", &"Start")))) as Marker2D
	if marker == null:
		marker = $Start
	health = int(transfer.get("health", 100))
	weapon.magazine = int(transfer.get("magazine", SideWeapon.CAPACITY))
	weapon.reserve = int(transfer.get("reserve", 36))
	checkpoint_hp = int(transfer.get("walker_hp", 65))

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
	weapon.name = "Weapon"
	player.add_child(weapon)
	player.add_child(SideReviewArt.new())
	add_child(audio)
	audio.setup(not indoor)
	weapon.fired.connect(audio.fire)
	weapon.reloading.connect(audio.reload)
	weapon.hit.connect(audio.strike)
	player.footfall.connect(func(running: bool) -> void: audio.step(player.global_position, running))
	if not indoor and checkpoint_hp > 0:
		walker = SideWalker.new()
		walker.position = Vector2(876, FLOOR)
		walker.hp = checkpoint_hp
		walker.target = player
		walker.collision_layer = 4
		walker.collision_mask = 1 | 2
		add_shape(walker, Vector2(31, 99), Vector2(0, -49.5))
		walker.strikes.connect(take_damage)
		walker.warned.connect(audio.warning)
		walker.fell.connect(func() -> void: checkpoint_hp = 0)
		world.add_child(walker)
		walker.add_child(SideReviewArt.new())
	camera.limit_left = 0
	camera.limit_right = room_width
	camera.limit_top = 0
	camera.limit_bottom = 540
	camera.position = Vector2(clampf(player.position.x, 480.0, room_width - 480.0), 270.0)
	add_child(camera)
	camera.make_current()
	view.room = self
	add_child(view)
	add_child(hud)

func add_shape(body: CollisionObject2D, size: Vector2, offset: Vector2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = offset
	body.add_child(shape)

func add_solid(rect: Rect2, material: StringName) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.set_meta("surface", material)
	add_shape(body, rect.size, Vector2.ZERO)
	world.add_child(body)

func _process(delta: float) -> void:
	immune = maxf(0.0, immune - delta)
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
	if is_instance_valid(walker):
		checkpoint_hp = walker.hp
	get_tree().set_meta(TRANSFER, {"arrival": portal.arrival, "health": health,
		"magazine": weapon.magazine, "reserve": weapon.reserve, "walker_hp": checkpoint_hp})
	await hud.fade_to(1.0)
	if get_tree().change_scene_to_file(portal.destination) != OK:
		get_tree().remove_meta(TRANSFER)
		world.process_mode = Node.PROCESS_MODE_INHERIT
		transitioning = false
		hud.failure = true
		hud.fade_to(0.0)

func take_damage(amount: int) -> void:
	if immune > 0.0 or transitioning or defeated:
		return
	health = maxi(0, health - amount)
	immune = 0.7
	if health == 0:
		defeated = true
		world.process_mode = Node.PROCESS_MODE_DISABLED

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
