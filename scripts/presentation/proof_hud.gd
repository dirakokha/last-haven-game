class_name ProofHUD
extends Node2D

const FONT := preload("res://assets/fonts/Vazirmatn-Regular.ttf")
const INK := Color("e3e7dc")
const SOFT := Color("a4b7b7")
const AMBER := Color("edbf79")
const TEAL := Color("7ac0af")
const RED := Color("e08671")
const PANEL := Color(0.047, 0.083, 0.107, 0.94)
const RULE := Color("3b5258")

var health := 100
var loaded := 12
var reserve := 36
var capacity := 12
var enemies := 4
var loading := 0
var rain := true
var lamps := true
var result := 0

func update(health_now: int, weapon: DepotWeapon, count: int) -> void:
	var reload_progress := clampi(int(30.0 * (1.0 - weapon.reload_left / 1.15)), 1, 30) if weapon.reload_left > 0.0 else 0
	if health == health_now and loaded == weapon.magazine and reserve == weapon.reserve \
		and capacity == weapon.capacity and enemies == count and loading == reload_progress:
		return
	health = health_now
	loaded = weapon.magazine
	reserve = weapon.reserve
	capacity = weapon.capacity
	enemies = count
	loading = reload_progress
	queue_redraw()

func set_effects(rain_on: bool, lamps_on: bool) -> void:
	rain = rain_on
	lamps = lamps_on
	queue_redraw()

func finish(won: bool) -> void:
	result = 1 if won else -1
	queue_redraw()

func words(at: Vector2, string: String, size: int, color: Color = INK) -> void:
	draw_string(FONT, at, string, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func slab(x: int, y: int, w: int, h: int, accent: Color) -> void:
	var shape := PackedVector2Array([Vector2(x, y), Vector2(x+w, y), Vector2(x+w, y+h-7),
		Vector2(x+w-7, y+h), Vector2(x, y+h)])
	draw_colored_polygon(shape, PANEL)
	shape.append(Vector2(x, y))
	draw_polyline(shape, RULE, 1)
	draw_rect(Rect2(x, y, 2, h), accent)

func _draw() -> void:
	slab(22, 17, 234, 64, TEAL)
	words(Vector2(36, 37), "L A S T   H A V E N   /   Y A R D   0 4", 12, TEAL)
	words(Vector2(36, 62), "North Quay", 23)
	words(Vector2(158, 61), "·   NIGHT SHIFT", 10, SOFT)
	slab(767, 17, 171, 51, AMBER)
	words(Vector2(782, 37), "CONTAINMENT", 11, AMBER)
	words(Vector2(782, 55), "INFECTED", 11, SOFT)
	words(Vector2(905, 54), "%02d" % enemies, 19)

	# The instrument strip is entirely below the near gameplay curb.
	slab(22, 477, 212, 46, RED if health < 40 else TEAL)
	words(Vector2(36, 494), "VITALS", 11, SOFT)
	words(Vector2(184, 496), "%03d" % health, 15)
	for i in range(10):
		var lit := clampf((health - i*10) / 10.0, 0.0, 1.0)
		draw_rect(Rect2(36 + i*18, 503, 15, 6), RULE)
		if lit > 0:
			draw_rect(Rect2(36 + i*18, 503, ceili(lit*15), 6), RED if health < 40 else TEAL)

	slab(246, 477, 460, 46, RULE)
	words(Vector2(259, 495), "WASD Move   Shift Run   RMB Aim   LMB Fire   R Reload   F Bat   Esc Pause", 11)
	words(Vector2(259, 512), "F2 Rain: %s     /     F3 Lamps: %s" % ["ON" if rain else "OFF", "ON" if lamps else "OFF"], 11, SOFT)

	slab(718, 477, 220, 46, AMBER)
	words(Vector2(732, 494), "RELOADING" if loading else "PISTOL  /  RESERVE", 11, AMBER)
	words(Vector2(864, 499), "%02d / %02d" % [loaded, reserve], 17, RED if loaded == 0 else INK)
	if loading:
		draw_rect(Rect2(732, 505, 189, 3), RULE)
		draw_rect(Rect2(732, 505, loading * 6.3, 3), AMBER)
	else:
		for i in range(capacity):
			var width := 189.0 / maxi(1, capacity)
			draw_rect(Rect2(732.0 + i * width, 505, width - 3, 3), AMBER if i < loaded else RULE)

	if result:
		var accent := TEAL if result > 0 else RED
		slab(320, 222, 320, 95, accent)
		words(Vector2(340, 243), "NORTH QUAY   /   STATUS REPORT", 12, accent)
		words(Vector2(340, 273), "Yard secured" if result > 0 else "Survivor down", 24)
		words(Vector2(340, 300), "ENTER   •   Restart encounter", 13, SOFT)
