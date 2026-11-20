class_name WalkerArt
extends Sprite2D

const ATLAS := preload("res://assets/art/walker.png")
var corpse := false
var state := 0
var state_left := 0.0
var hit_left := 0.0
var heading := Vector2.RIGHT
var moving := false
var runner := false
var facing_left := false
var age := 0.0
var gait := 0.0
var last_position := Vector2.ZERO

func _ready() -> void:
	texture = ATLAS
	centered = false
	region_enabled = true
	region_filter_clip_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	last_position = global_position
	var shadow := ContactShadow.new()
	shadow.prone = corpse
	add_child(shadow)
	show_cell(23 if corpse else 0)

func show_cell(index: int) -> void:
	region_rect = Rect2(Vector2(index % 8, index >> 3) * Vector2(56, 44), Vector2(56, 44))
	flip_h = facing_left
	offset = Vector2(-27 if facing_left else -28, -40)
	self_modulate = Color("dfb6aa") if runner else Color.WHITE

func _process(delta: float) -> void:
	age += delta
	if corpse:
		show_cell(23 + mini(int(age / 0.10), 3))
		if age >= 0.4:
			set_process(false)
		return
	var moved := global_position.distance_to(last_position)
	last_position = global_position
	if absf(heading.x) > 0.13:
		facing_left = heading.x < 0.0
	var index := int(age * 3.0) % 4
	match state:
		0: # Follow
			if moved > 0.001 or moving:
				gait = fposmod(gait + moved * 8.0 / (55.0 if runner else 43.0), 8.0)
				index = 4 + int(gait)
		1: # Warning
			index = 12 + clampi(int((1.0 - state_left / (0.48 if runner else 0.58)) * 4.0), 0, 3)
		2: # Lunge
			index = 16 + clampi(int((1.0 - state_left / (0.33 if runner else 0.16)) * 5.0), 0, 4)
	if hit_left > 0.0:
		index = 21 if hit_left > 0.07 else 22
	show_cell(index)
