class_name ContactShadow
extends Node2D

var prone := false

func _ready() -> void:
	show_behind_parent = true

func _draw() -> void:
	var width := 18 if prone else 13
	var outer := PackedVector2Array([Vector2(-width + 2, -3), Vector2(width - 3, -3),
		Vector2(width + 2, 0), Vector2(width - 4, 4), Vector2(4 - width, 4), Vector2(-width - 2, 1)])
	draw_colored_polygon(outer, Color(0.026, 0.055, 0.078, 0.27))
	draw_rect(Rect2(-width + 4, -1, width * 2 - 8, 3), Color(0.026, 0.055, 0.078, 0.35))
