class_name DepotWeapon
extends Node2D

@export var capacity := 12
@export var reserve := 36
@export var bullet_damage := 24
var magazine: int
var reload_left := 0.0
var cooldown := 0.0
var flash := 0.0
var swing := 0.0
var aim := Vector2.RIGHT
var shot_aim := Vector2.RIGHT
var shot_origin := Vector2.ZERO
var trace_end := Vector2.ZERO
const LIFT := Vector2(0, -18)
var audio: ProofAudio
var pose_left := 0.0

func _ready() -> void:
	magazine = capacity

func _physics_process(delta: float) -> void:
	var offset := get_local_mouse_position() - LIFT
	if offset.length_squared() > 1:
		aim = offset.normalized()
	cooldown = maxf(0, cooldown - delta)
	flash = maxf(0, flash - delta)
	pose_left = maxf(0, pose_left - delta)
	swing = maxf(0, swing - delta)
	if reload_left > 0:
		reload_left -= delta
		if reload_left <= 0:
			var rounds := mini(capacity - magazine, reserve)
			magazine += rounds
			reserve -= rounds
	elif cooldown <= 0:
		if Input.is_action_just_pressed("reload") and magazine < capacity and reserve > 0:
			reload_left = 1.15
			audio.reload(global_position)
		elif Input.is_action_just_pressed("bat"):
			bat()
		elif Input.is_action_just_pressed("fire") and magazine > 0:
			shoot()
	queue_redraw()

# Cast in ground coordinates; the visual muzzle and tracer are lifted equally.
func cast(start: Vector2, finish: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(start, finish)
	query.exclude = [(get_parent() as CharacterBody2D).get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query)

func shoot() -> void:
	magazine -= 1
	cooldown = 0.23
	flash = 0.08
	pose_left = 0.15
	shot_aim = aim
	shot_origin = global_position
	var muzzle := global_position + aim * 19
	var end := muzzle + aim * 700
	var hit := cast(global_position, muzzle)
	if hit.is_empty():
		hit = cast(muzzle, end)
	if not hit.is_empty():
		end = hit.position
		audio.hit(end)
		if hit.collider is DepotZombie:
			hit.collider.hurt(bullet_damage, aim * 65)
	trace_end = end - global_position + LIFT
	audio.shot(global_position)

func bat() -> void:
	cooldown = 0.52
	swing = 0.19
	for node in get_tree().get_nodes_in_group("infected"):
		var enemy := node as DepotZombie
		var gap := enemy.global_position - global_position
		if gap.length() <= 53 and gap.normalized().dot(aim) > 0.45:
			var hit := cast(global_position, enemy.global_position)
			if hit.get("collider") == enemy:
				enemy.hurt(31, gap.normalized() * 220)
				audio.hit(enemy.global_position, true)

func _draw() -> void:
	var muzzle := LIFT + shot_aim * 19
	if flash > 0:
		var fixed_trail := shot_origin - global_position
		draw_line(muzzle + fixed_trail, trace_end + fixed_trail, Color(1, 0.79, 0.44, 0.38 * flash / 0.08), 1)
		var p := muzzle.round()
		draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(-2, -2),
			p + Vector2(0, -6), p + Vector2(2, -2), p + Vector2(6, 0), p + Vector2(2, 2),
			p + Vector2(0, 4), p + Vector2(-2, 2)]), Color("ffc06c"))
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color("fff3bb"))
	if swing > 0:
		# Phase 2's bat and arc remain the gameplay placeholder for this milestone.
		var angle := aim.angle() + lerpf(1, -1, swing / 0.19)
		draw_line(LIFT, LIFT + Vector2.from_angle(angle) * 43, Color("d7a872"), 5)
