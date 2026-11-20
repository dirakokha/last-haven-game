class_name SideReviewView
extends Node2D

const COURT := preload("res://assets/side_review/court.png")
const CASE := preload("res://assets/side_review/review_case.png")
const LAMP := preload("res://assets/side_review/lamp.png")
var room: Node
var weather: SideReviewRain
var lamp: PointLight2D

func _ready() -> void:
	z_index = -2
	if room.indoor:
		return
	var obstacle := Sprite2D.new()
	obstacle.texture = CASE
	obstacle.centered = false
	obstacle.position = Vector2(465, 381)
	obstacle.light_mask = 2
	add_child(obstacle)
	lamp = PointLight2D.new()
	lamp.texture = LAMP
	lamp.texture_scale = 1.05
	lamp.color = Color("ffba6e")
	lamp.energy = 1.18
	lamp.position = Vector2(705, 331)
	lamp.range_item_cull_mask = 2
	lamp.shadow_enabled = true
	lamp.shadow_item_cull_mask = 2
	add_child(lamp)
	var occluder := LightOccluder2D.new()
	occluder.occluder_light_mask = 2
	occluder.occluder = OccluderPolygon2D.new()
	occluder.occluder.polygon = PackedVector2Array([Vector2(465, 383), Vector2(533, 383), Vector2(533, 425), Vector2(465, 425)])
	add_child(occluder)
	weather = SideReviewRain.new()
	weather.z_as_relative = false
	weather.z_index = 3
	add_child(weather)

func _process(_delta: float) -> void:
	queue_redraw()

func contact_shadow(x: float, distance: float) -> void:
	var opacity := 0.52 * (1.0 - clampf(distance / 180.0, 0.0, 0.75))
	var y := 425.0
	draw_colored_polygon(PackedVector2Array([Vector2(x-19,y), Vector2(x-12,y-3),
		Vector2(x+13,y-3), Vector2(x+21,y+1), Vector2(x+13,y+4), Vector2(x-12,y+4)]),
		Color(0.02, 0.04, 0.06, opacity))

func draw_actor_shadows() -> void:
	var actor: SidePlayer = room.player
	contact_shadow(actor.position.x, maxf(0.0, 425.0 - actor.position.y))
	if is_instance_valid(room.walker):
		var walker: SideWalker = room.walker
		contact_shadow(walker.position.x, maxf(0.0, 425.0 - walker.position.y))

func toggle_weather() -> void:
	if is_instance_valid(weather):
		weather.visible = not weather.visible
		weather.set_process(weather.visible)

func toggle_shadows() -> void:
	if is_instance_valid(lamp):
		lamp.shadow_enabled = not lamp.shadow_enabled

func _draw() -> void:
	if room == null:
		return
	if not room.indoor:
		draw_texture(COURT, Vector2.ZERO)
		draw_actor_shadows()
		return
	# The interior is a navigation fixture, not an expansion of the art milestone.
	var width := float(room.room_width)
	draw_rect(Rect2(0, 0, width, 540), Color("15232b"))
	for i in range(int(width / 120.0)):
		var x: float = i * 130.0
		draw_rect(Rect2(x, 132, 120, 290), Color("25343a"))
		draw_rect(Rect2(x, 132, 6, 290), Color("30434a"))
	draw_rect(Rect2(0, 425, width, 115), Color("20272c"))
	draw_rect(Rect2(0, 425, width, 3), Color("767364"))
	draw_rect(Rect2(196, 257, 84, 168), Color("161d25"))
	draw_rect(Rect2(193, 254, 90, 171), Color("807459"), false, 2)
	draw_actor_shadows()
