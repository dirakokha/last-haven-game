class_name SideReviewRain
extends Node2D

var drops := PackedVector2Array()

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 127
	for i in range(59):
		drops.append(Vector2(rng.randf_range(0.0, 1100.0), rng.randf_range(0.0, 490.0)))

func _process(delta: float) -> void:
	for i in range(drops.size()):
		var speed := 200.0 + float(i % 7) * 20.0
		drops[i] = Vector2(fposmod(drops[i].x - delta * speed * 0.10, 1100.0),
			fposmod(drops[i].y + delta * speed, 490.0))
	queue_redraw()

func _draw() -> void:
	for i in range(drops.size()):
		var p := drops[i].floor()
		var tint := Color(0.67, 0.82, 0.84, 0.18)
		if absf(p.x - 703.0) < 55.0 and p.y > 305.0 and p.y < 446.0:
			tint = Color(0.99, 0.72, 0.44, 0.29)
		draw_line(p, p + Vector2(-1, 7 + i % 5), tint)
