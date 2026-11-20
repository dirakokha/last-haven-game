class_name SurvivorArt
extends Sprite2D

const SIDE := preload("res://assets/art/survivor_side.png")
const FRONT := preload("res://assets/art/survivor_front.png")
const BACK := preload("res://assets/art/survivor_back.png")
const AIM := preload("res://assets/art/survivor_aim.png")
const CELL := Vector2i(56, 44)
const ORIGIN := Vector2(28, 40)

var weapon: DepotWeapon
var audio: ProofAudio
var body: CharacterBody2D
var gait := 0.0
var idle := 0.0
var last_step := -1
var settled := Vector2.RIGHT
var last_position := Vector2.ZERO

func _ready() -> void:
	body = get_parent() as CharacterBody2D
	last_position = body.position
	centered = false
	offset = -ORIGIN
	region_enabled = true
	region_filter_clip_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ContactShadow.new())
	apply_cell(SIDE, 0, 8)

func _process(delta: float) -> void:
	var traveled := body.position - last_position
	last_position = body.position
	var stepping := traveled.length_squared() > 0.001
	var running := Input.is_action_pressed("sprint")
	var stride := 96.0 if running else 77.0
	if stepping:
		settled = traveled.normalized()
		gait = fposmod(gait + traveled.length() * 8.0 / stride, 8.0)
		var step := int(gait) >> 2
		if step != last_step:
			audio.step(body.global_position, running)
		last_step = step
		idle = 0.0
	else:
		idle += delta
		# Render frames between physics ticks must not restart the gait or duplicate steps.
		if body.get_real_velocity().length_squared() < 1.0:
			gait = 0.0
			last_step = -1
	var moving := stepping or body.get_real_velocity().length_squared() > 1.0
	var leg := int(gait) + (9 if running else 1) if moving else 0
	var aiming := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or weapon.pose_left > 0.0
	if aiming:
		var heading: Vector2 = weapon.shot_aim if weapon.pose_left > 0.0 else weapon.aim
		var sector := posmod(roundi(atan2(heading.x, heading.y) * 8.0 / PI), 16)
		var recoil := clampi(1 + int((0.15 - weapon.pose_left) / 0.05), 1, 3) if weapon.pose_left > 0.0 else 0
		flip_h = false
		offset = -ORIGIN
		apply_cell(AIM, sector * 68 + recoil * 17 + leg, 17)
	else:
		var source: Texture2D = SIDE
		if absf(settled.y) > absf(settled.x) * 1.15:
			source = FRONT if settled.y > 0.0 else BACK
		flip_h = settled.x < 0.0
		offset = -ORIGIN + (Vector2.RIGHT if flip_h else Vector2.ZERO)
		apply_cell(source, leg + 3 if moving else int(idle * 4.0) % 4, 8)

func apply_cell(source: Texture2D, index: int, columns: int) -> void:
	texture = source
	region_rect = Rect2(Vector2(index % columns, floori(float(index) / columns)) * Vector2(CELL), Vector2(CELL))
