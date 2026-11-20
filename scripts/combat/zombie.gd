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
var art: WalkerArt

func _ready() -> void:
	hp = 45 if runner else 65
	motion_mode = MOTION_MODE_FLOATING
	var footprint := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8
	footprint.shape = circle
	add_child(footprint)
	art = WalkerArt.new()
	art.runner = runner
	add_child(art)

func hurt(amount: int, push: Vector2) -> void:
	if hp <= 0:
		return
	hp -= amount
	flash = 0.14
	shove = push
	if hp <= 0:
		# Inert visual at the original Y-sort pin. The actor still frees this frame.
		var body := WalkerArt.new()
		body.corpse = true
		body.runner = runner
		body.facing_left = art.facing_left
		body.position = position
		# Play the last death even when the winning result disables the yard.
		body.process_mode = Node.PROCESS_MODE_PAUSABLE
		get_parent().add_child(body)
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
	art.state = state
	art.state_left = timer
	art.hit_left = flash
	art.heading = heading
	art.moving = get_real_velocity().length_squared() > 1.0
	queue_redraw()

func _draw() -> void:
	if state == State.WARN:
		var distance := 90.0 if runner else 28.0
		var tangent := heading.orthogonal()
		var end := heading * distance
		draw_line(heading * 9.0, end, Color(0.99, 0.57, 0.29, 0.44), 1)
		draw_polyline(PackedVector2Array([end - heading * 5.0 + tangent * 4.0,
			end, end - heading * 5.0 - tangent * 4.0]), Color("eeb57d"), 1)
