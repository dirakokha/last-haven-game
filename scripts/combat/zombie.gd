class_name DepotZombie
extends CharacterBody2D

signal strikes(amount: int)
signal fell

enum State { FOLLOW, WARN, LUNGE, REST }
@export var runner := false
var target: CharacterBody2D
var hp: int
var state := State.FOLLOW
var timer := 0.0
var heading := Vector2.RIGHT
var shove := Vector2.ZERO
var flash := 0.0
var delivered := false

func _ready() -> void:
	hp = 45 if runner else 65
	motion_mode = MOTION_MODE_FLOATING
	var footprint := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8
	footprint.shape = circle
	add_child(footprint)

func hurt(amount: int, push: Vector2) -> void:
	if hp <= 0:
		return
	hp -= amount
	flash = 0.14
	shove = push
	if hp <= 0:
		fell.emit()
		queue_free()

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	var gap := target.global_position - global_position
	timer -= delta
	flash = maxf(0, flash - delta)
	velocity = Vector2.ZERO
	match state:
		State.FOLLOW:
			heading = gap.normalized()
			velocity = heading * (91 if runner else 49)
			if gap.length() < (98 if runner else 28):
				state = State.WARN
				timer = 0.48 if runner else 0.58
				delivered = false
		State.WARN:
			if timer <= 0:
				state = State.LUNGE
				timer = 0.33 if runner else 0.16
		State.LUNGE:
			velocity = heading * (310 if runner else 46)
			if not delivered and gap.length() < 31 and gap.normalized().dot(heading) > 0:
				delivered = true
				strikes.emit(22 if runner else 15)
			if timer <= 0:
				state = State.REST
				timer = 1.15 if runner else 0.78
		State.REST:
			if timer <= 0:
				state = State.FOLLOW
	velocity += shove
	shove = shove.move_toward(Vector2.ZERO, 700 * delta)
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var tint := Color("a47460") if runner else Color("799586")
	if flash > 0:
		tint = Color.WHITE
	var lean := signf(heading.x) * (5 if runner else 2)
	draw_rect(Rect2(-7,-7,5,8), Color("283334"))
	draw_rect(Rect2(2,-7,5,8), Color("283334"))
	draw_rect(Rect2(-8,-24,16,19), tint.darkened(0.28))
	draw_rect(Rect2(lean-5,-34,10,11), tint)
	draw_rect(Rect2(lean-5,-31,10,3), Color("d7b868"))
	if state == State.WARN:
		draw_line(Vector2.ZERO, heading * (90 if runner else 28), Color("ff965d"), 2)
