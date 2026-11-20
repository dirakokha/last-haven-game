class_name SideReviewArt
extends Sprite2D

const SURVIVOR := preload("res://assets/side_review/review_survivor.png")
const WALKER := preload("res://assets/side_review/review_walker.png")
const CELL := Vector2(144, 128)
const ORIGIN := Vector2(68, 114)
var stride_position := 0.0
var last_x := 0.0

func _ready() -> void:
	texture = SURVIVOR if get_parent() is SidePlayer else WALKER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	light_mask = 2
	centered = false
	region_enabled = true
	region_filter_clip_enabled = true
	last_x = global_position.x
	cel(0, false)

func _process(_delta: float) -> void:
	var actor := get_parent()
	if actor is SidePlayer:
		var weapon: SideWeapon = actor.get_node("Weapon")
		var moved := absf(last_x - global_position.x)
		if moved > 0.0:
			stride_position = fposmod(stride_position + moved, 53.0)
		var pose := 0
		if not actor.is_on_floor():
			pose = 2
		elif absf(actor.get_real_velocity().x) > 1.0 and stride_position < 25.0:
			pose = 1
		cel(pose, weapon.aim.x < 0.0)
	elif actor is SideWalker:
		cel(1 if actor.mode == SideWalker.Motion.WARN else 0, actor.direction > 0)
	last_x = global_position.x

func cel(pose: int, reflect: bool) -> void:
	region_rect = Rect2(Vector2(pose * CELL.x, 0), CELL)
	flip_h = reflect
	# Mirroring with Sprite2D reflects through the cell center, not the artwork pin.
	offset = Vector2(ORIGIN.x - CELL.x + 1.0, -ORIGIN.y) if reflect else -ORIGIN
