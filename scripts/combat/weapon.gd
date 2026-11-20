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
var trace_end := Vector2.ZERO
const LIFT := Vector2(0, -18)
const SHOT := preload("res://assets/audio/shot.wav")
const RACK := preload("res://assets/audio/rack.wav")
const IMPACT := preload("res://assets/audio/impact.wav")
var sound := AudioStreamPlayer.new()

func _ready() -> void:
	magazine = capacity
	add_child(sound)

func _physics_process(delta: float) -> void:
	var offset := get_local_mouse_position() - LIFT
	if offset.length_squared() > 1:
		aim = offset.normalized()
	cooldown = maxf(0, cooldown - delta)
	flash = maxf(0, flash - delta)
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
			play_sound(RACK)
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
	var muzzle := global_position + aim * 19
	var end := muzzle + aim * 700
	var hit := cast(global_position, muzzle)
	if hit.is_empty():
		hit = cast(muzzle, end)
	if not hit.is_empty():
		end = hit.position
		if hit.collider is DepotZombie:
			hit.collider.hurt(bullet_damage, aim * 65)
	trace_end = end - global_position + LIFT
	play_sound(SHOT)

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
				play_sound(IMPACT)

func play_sound(clip: AudioStream) -> void:
	sound.stream = clip
	sound.play()

func _draw() -> void:
	var muzzle := LIFT + aim * 19
	draw_line(LIFT, muzzle - aim * (3 if flash > 0 else 0), Color("ccd5cb"), 4)
	if flash > 0:
		draw_line(muzzle, trace_end, Color(1,0.82,0.5,0.48), 1)
		draw_circle(muzzle, 5, Color("ffcf82"))
	if swing > 0:
		var angle := aim.angle() + lerpf(1,-1,swing/0.19)
		draw_line(LIFT, LIFT + Vector2.from_angle(angle)*43, Color("d7a872"), 5)
