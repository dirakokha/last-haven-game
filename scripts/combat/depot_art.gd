extends Node2D

# Original block-art backdrop; only the road between the curbs is traversable.
func _draw() -> void:
	draw_rect(Rect2(0,0,1440,196), Color("263a43"))
	for i in range(12):
		var x := i * 124
		var y := 80 + (i * 31) % 46
		draw_rect(Rect2(x,y,119,196-y), Color("33494e"))
		draw_rect(Rect2(x-2,y,123,5), Color("182d33"))
		for j in range(5):
			var lit := (i+j)%4 == 0
			draw_rect(Rect2(x+8+j*21,y+14,14,21), Color("ad9369") if lit else Color("203239"))
	draw_rect(Rect2(80,196,1280,4), Color("abb0a0"))
	for x in range(104,1360,64):
		draw_rect(Rect2(x,454,24,4), Color("be9967"))
