class_name SideReviewArt
extends Sprite2D

const SURVIVOR := preload("res://assets/side_review/review_survivor.png")
const WALKER := preload("res://assets/side_review/review_walker.png")
const CELL := Vector2(144, 128)
const ORIGIN := Vector2(68, 114)
enum Hero { GUARD, CONTACT, AIR, LOW, RUN, RELOAD, PASS, BAT, DODGE }
enum Infected { GUARD, WARN, STEP, ATTACK, HIT, DEATH }
var pose_index := 0

func _ready() -> void:
	texture = SURVIVOR if get_parent() is SidePlayer else WALKER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	light_mask = 2
	centered = false
	region_enabled = true
	region_filter_clip_enabled = true
	# World is disabled on defeat; the pose can still present the frozen state.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if get_parent() is SidePlayer:
		z_index = 1
	pose(0, false)

func _process(_delta: float) -> void:
	var actor := get_parent()
	if actor is SidePlayer:
		player_pose(actor, actor.get_node("Weapon") as SideWeapon)
	elif actor is SideWalker:
		walker_pose(actor)

func player_pose(actor: SidePlayer, gun: SideWeapon) -> void:
	var key := Hero.GUARD
	var recoil := 0.0
	if actor.down:
		key = Hero.LOW
	elif gun.recoil_left > 0.0:
		# During the flash use only measured barrel-registered keys. Afterwards a
		# brief two-pixel kick is a transform, not an additional authored cel.
		key = Hero.GUARD if actor.is_on_floor() else Hero.AIR
		if gun.recoil_left < 0.097:
			recoil = -actor.facing * (2.0 if gun.recoil_left > 0.06 else 1.0)
	elif actor.injury_left > 0.0:
		key = Hero.LOW if actor.is_on_floor() else Hero.AIR
	elif gun.swing_left > 0.0:
		key = Hero.BAT
	elif gun.reload_left > 0.0:
		key = Hero.RELOAD
	elif actor.dodge_left > 0.0:
		key = Hero.DODGE
	elif not actor.is_on_floor():
		key = Hero.LOW if actor.jump_pose_left > 0.0 else Hero.AIR
	elif actor.land_pose_left > 0.0:
		key = Hero.LOW
	elif actor.gait_moving:
		# This same phase resets at each physics footfall. The first key is contact;
		# the subsequent pose recovers toward the next stride.
		if actor.gait_running:
			key = Hero.CONTACT if actor.stride < 0.27 else Hero.RUN
		else:
			key = Hero.CONTACT if actor.stride < 0.38 else Hero.PASS
	pose(key, actor.facing < 0)
	offset.x += recoil
	modulate = Color("e2b4ad") if actor.injury_left > 0.0 and not actor.down else Color.WHITE

func walker_pose(actor: SideWalker) -> void:
	var key := Infected.GUARD
	if actor.hp <= 0:
		key = Infected.HIT if actor.death_left > 0.0 else Infected.DEATH
	elif actor.hit_left > 0.0:
		key = Infected.HIT
	elif actor.mode == SideWalker.Motion.WARN:
		key = Infected.WARN
	elif actor.mode == SideWalker.Motion.LUNGE:
		key = Infected.ATTACK
	elif actor.mode == SideWalker.Motion.RECOVER:
		key = Infected.WARN
	elif actor.mode == SideWalker.Motion.FOLLOW and actor.gait < 0.61 and absf(actor.get_real_velocity().x) > 1.0:
		key = Infected.STEP
	pose(key, actor.direction > 0)

func pose(index: int, reflect: bool) -> void:
	pose_index = index
	region_rect = Rect2(Vector2(index * CELL.x, 0), CELL)
	flip_h = reflect
	# Mirror through the foot pin, not the artwork rectangle center. A pixel in
	# column 68 maps back to the same position on either side.
	offset = Vector2(ORIGIN.x - CELL.x + 1.0, -ORIGIN.y) if reflect else -ORIGIN
