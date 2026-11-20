class_name SideEffects
extends Node2D

signal casing_landed(at: Vector2)
var flecks: Array[Fleck] = []
var weapon: SideWeapon
var rng := RandomNumberGenerator.new()

class Fleck:
	var p: Vector2
	var v: Vector2
	var left: float
	var life: float
	var tint: Color
	var kind: StringName
	var gravity: float
	var facing: int

func burst(at: Vector2, velocity: Vector2, time: float, color: Color, kind: StringName, gravity: float, facing: int = 1) -> void:
	if flecks.size() >= 120:
		flecks.pop_front()
	var fleck := Fleck.new()
	fleck.p = at
	fleck.v = velocity
	fleck.left = time
	fleck.life = time
	fleck.tint = color
	fleck.kind = kind
	fleck.gravity = gravity
	fleck.facing = facing
	flecks.append(fleck)
	queue_redraw()

func firing(at: Vector2, direction: int) -> void:
	burst(at, Vector2.ZERO, SideWeapon.SHOT_FLASH_TIME, Color("ffc16f"), &"flash", 0.0, direction)
	for i in range(4):
		burst(at + Vector2(direction * (4 + i), 0), Vector2(direction * (12 + i*5), -11 - i*3),
			0.20 + 0.035*i, Color(0.72, 0.69, 0.61, 0.46), &"smoke", 0.0)
	burst(at - Vector2(direction * 9, 1), Vector2(-direction*88, -112), 1.18, Color("d6a357"), &"brass", 555.0)

func impact(at: Vector2, material: StringName) -> void:
	match material:
		&"infected":
			for i in range(7):
				burst(at, Vector2(rng.randf_range(-91, 91), rng.randf_range(-105, -27)),
					rng.randf_range(0.18, 0.36), Color("9c3938") if i < 4 else Color("62282e"), &"blood", 400.0)
		&"metal":
			for i in range(7):
				burst(at, Vector2(rng.randf_range(-115, 115), rng.randf_range(-130, 35)),
					rng.randf_range(0.07, 0.19), Color("e8b268"), &"spark", 210.0)
		&"melee":
			burst(at, Vector2.ZERO, 0.10, Color("d8cca8"), &"strike", 0.0)
		_:
			for i in range(5):
				burst(at, Vector2(rng.randf_range(-53, 53), rng.randf_range(-64, -14)),
					rng.randf_range(0.12, 0.26), Color("929a93"), &"dust", 120.0)

func _physics_process(delta: float) -> void:
	if flecks.is_empty():
		return
	for i in range(flecks.size() - 1, -1, -1):
		var f := flecks[i]
		f.left -= delta
		f.v.y += f.gravity * delta
		var previous := f.p
		f.p += f.v * delta
		if f.kind == &"brass" and f.v.y > 0.0:
			var probe := PhysicsRayQueryParameters2D.create(previous, f.p, 1)
			var contact := get_world_2d().direct_space_state.intersect_ray(probe)
			if not contact.is_empty() and contact.normal.y < -0.6:
				casing_landed.emit(contact.position)
				f.kind = &"settled"
				f.p = contact.position - Vector2(0, 2)
				f.v = Vector2.ZERO
				f.gravity = 0.0
				f.left = 0.50
		if f.left <= 0.0:
			flecks.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for f in flecks:
		var point := f.p
		if f.kind == &"flash" and is_instance_valid(weapon):
			point = weapon.muzzle_for(f.facing)
		var p := to_local(point.round())
		var tint := f.tint
		tint.a *= minf(1.0, 1.5 * f.left / f.life)
		match f.kind:
			&"flash":
				var x := float(f.facing)
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(3*x,-3), p+Vector2(3*x,-7),
					p+Vector2(8*x,-3), p+Vector2(17*x,0), p+Vector2(7*x,3), p+Vector2(3*x,6)]), tint)
				draw_line(p, p+Vector2(9*x,0), Color(1,0.95,0.69,tint.a), 2.0)
			&"smoke":
				var r := 2 + roundi(4.0 * (1.0 - f.left / f.life))
				draw_rect(Rect2(p - Vector2(r, r), Vector2(2*r, 2*r)), tint)
			&"spark":
				draw_line(p, p - f.v.normalized() * 4.0, tint, 1.0)
			&"strike":
				draw_line(p - Vector2(3,5), p + Vector2(3,4), tint, 2.0)
				draw_line(p - Vector2(4,-4), p + Vector2(6,-5), tint, 1.0)
			&"brass", &"settled":
				draw_rect(Rect2(p, Vector2(4, 2)), tint)
			_:
				draw_rect(Rect2(p, Vector2(2, 2)), tint)
