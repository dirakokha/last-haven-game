class_name SideReviewArt
extends Sprite2D

const SURVIVOR := preload("res://assets/side_review/review_survivor.png")
const WALKER := preload("res://assets/side_review/review_walker.png")
const CELL := Vector2(144, 128)
const ORIGIN := Vector2(68, 114)
enum Hero { GUARD, CONTACT, AIR, LOW, RUN, RELOAD, PASS, BAT_IMPACT, DODGE,
	BAT_READY, BAT_WINDUP, BAT_SWING, BAT_FOLLOW, BAT_RECOVER }
const BAT_POSES := {
	SideWeapon.BatPhase.READY: Hero.BAT_READY,
	SideWeapon.BatPhase.WINDUP: Hero.BAT_WINDUP,
	SideWeapon.BatPhase.SWING: Hero.BAT_SWING,
	SideWeapon.BatPhase.IMPACT: Hero.BAT_IMPACT,
	SideWeapon.BatPhase.FOLLOW: Hero.BAT_FOLLOW,
	SideWeapon.BatPhase.RECOVER: Hero.BAT_RECOVER,
}
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

func _physics_process(_delta: float) -> void:
	var actor := get_parent()
	if actor is SidePlayer:
		player_pose(actor, actor.get_node("Weapon") as SideWeapon)
	elif actor is SideWalker:
		walker_pose(actor)

func player_pose(actor: SidePlayer, gun: SideWeapon) -> void:
	var key := locomotion_pose(actor)
	var recoil := 0.0
	var side: int = actor.facing
	if actor.down:
		key = Hero.LOW
	elif gun.bat_phase != SideWeapon.BatPhase.NONE:
		key = BAT_POSES[gun.bat_phase]
		side = gun.bat_facing
	elif gun.recoil_left > 0.0:
		# Keep registered gait/air keys through recoil. The brief flash still
		# faces the shot's side even if A/D changes on the following tick.
		key = armed_pose(actor)
		if gun.showing_shot_flash():
			side = gun.shot_facing
		elif gun.recoil_left > 0.06:
			recoil = -side
	elif actor.injury_left > 0.0:
		key = Hero.LOW if actor.is_on_floor() else Hero.AIR
	elif gun.reload_left > 0.08:
		key = Hero.RELOAD
	pose(key, side < 0)
	offset.x += recoil
	modulate = Color("e2b4ad") if actor.injury_left > 0.0 and not actor.down else Color.WHITE

func locomotion_pose(actor: SidePlayer) -> int:
	if actor.dodge_left > 0.0:
		return Hero.DODGE
	if not actor.is_on_floor() and actor.jump_pose_left > 0.0:
		return Hero.LOW
	if actor.is_on_floor() and actor.land_pose_left > 0.0:
		return Hero.LOW
	return armed_pose(actor)

func armed_pose(actor: SidePlayer) -> int:
	if not actor.is_on_floor():
		return Hero.AIR
	if not actor.gait_moving:
		return Hero.GUARD
	# One distance phase for the cadence and the sound. An actual footfall
	# starts the contact key; sprint and reversal keep that phase continuous.
	if actor.stride < 0.32:
		return Hero.CONTACT
	return Hero.RUN if actor.gait_running else Hero.PASS

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
