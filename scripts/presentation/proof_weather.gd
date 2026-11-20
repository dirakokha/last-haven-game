class_name ProofWeather
extends Node2D

const VIEW := Vector2(960, 540)
const RAIN_BOUNDS := Vector2(984, 564)
var rain_enabled := true
var lamps_enabled := true
var drops := PackedVector2Array()
var speeds := PackedFloat32Array()
var splash_points := PackedVector2Array()
var splash_phase := PackedFloat32Array()

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 740
	for i in range(148):
		drops.append(Vector2(rng.randf_range(0, RAIN_BOUNDS.x), rng.randf_range(0, RAIN_BOUNDS.y)))
		speeds.append(rng.randf_range(210.0, 422.0))
	for i in range(22):
		splash_points.append(Vector2(rng.randi_range(88, 1350), rng.randi_range(205, 445)))
		splash_phase.append(rng.randf())

func set_effects(rain: bool, lamps: bool) -> void:
	rain_enabled = rain
	lamps_enabled = lamps
	set_process(rain)
	queue_redraw()

func _process(delta: float) -> void:
	for i in drops.size():
		var speed := speeds[i]
		drops[i] = Vector2(fposmod(drops[i].x - delta * speed * 0.24, RAIN_BOUNDS.x),
			fposmod(drops[i].y + delta * speed, RAIN_BOUNDS.y))
	for i in splash_phase.size():
		splash_phase[i] = fposmod(splash_phase[i] + delta * (0.42 + i * 0.019), 1.0)
	queue_redraw()

func _draw() -> void:
	if not rain_enabled:
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var left := roundf(camera.get_screen_center_position().x - VIEW.x * 0.5)
	for i in drops.size():
		var start := drops[i].floor() + Vector2(left - 10, -10)
		var size := 5 + i % 8
		var warm := lamps_enabled and start.y > 115 and start.y < 292 and (
			absf(start.x - 514) < 35 or absf(start.x - 1064) < 35)
		var tint := Color(0.99, 0.77, 0.48, 0.22) if warm else Color(0.59, 0.77, 0.80, 0.10 + i % 4 * 0.033)
		draw_line(start, start + Vector2(-roundi(size * 0.24), size), tint)
	for i in splash_points.size():
		var at := splash_points[i]
		var phase := splash_phase[i]
		if phase > 0.24 or at.x < left or at.x > left + VIEW.x:
			continue
		var radius := 2 + int(phase * 22.0)
		var tint := Color(0.52, 0.70, 0.73, (0.24 - phase) * 1.1)
		draw_rect(Rect2(at - Vector2(radius, 0), Vector2(3, 1)), tint)
		draw_rect(Rect2(at + Vector2(radius - 3, 0), Vector2(3, 1)), tint)
		draw_rect(Rect2(at + Vector2(-1, 1), Vector2(3, 1)), tint)
