extends Node2D

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1440, 540), Color("24323a"))
	draw_rect(Rect2(80, 200, 1280, 250), Color("46565a"))
	for y in [200, 262, 325, 388, 450]:
		draw_dashed_line(Vector2(80, y), Vector2(1360, y), Color("85958a"), 2.0, 16.0)
