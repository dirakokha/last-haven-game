class_name SideHUD
extends CanvasLayer

const FONT := preload("res://assets/fonts/Vazirmatn-Regular.ttf")
var vitals: Label
var ammo: Label
var prompt: Label
var result: Label
var veil: ColorRect
var failure := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	plate(Rect2(22, 22, 245, 60), "محوطهٔ بارگیری  /  ۰۴\nآخرین پناهگاه", 17)
	vitals = plate(Rect2(742, 22, 196, 60), "", 17)
	ammo = plate(Rect2(742, 457, 196, 60), "", 17)
	plate(Rect2(22, 457, 690, 60), "A / D حرکت   ·   فاصله پرش   ·   شیفت دویدن   ·   کنترل جاخالی   ·   ماوس نشانه و شلیک\nR خشاب   ·   F ضربه   ·   F2 باران   ·   F3 سایه   ·   F11 تمام‌صفحه", 15)
	prompt = plate(Rect2(312, 362, 336, 40), "", 19)
	prompt.hide()
	result = plate(Rect2(304, 202, 352, 112), "", 24)
	result.hide()
	veil = ColorRect.new()
	veil.color = Color("101822")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	fade_to(0.0)

func plate(bounds: Rect2, text: String, size: int) -> Label:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.038, 0.069, 0.092, 0.9)
	panel.border_color = Color("688789")
	panel.border_width_right = 2
	panel.border_width_bottom = 1
	var label := Label.new()
	label.position = bounds.position
	label.size = bounds.size
	label.text_direction = Control.TEXT_DIRECTION_RTL
	label.language = "fa"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_stylebox_override("normal", panel)
	label.add_theme_color_override("font_color", Color("e0e4d6"))
	label.text = text
	add_child(label)
	return label

func refresh(room: Node, entry: String) -> void:
	vitals.text = "سلامت   " + digits(room.health)
	if room.checkpoint_hp <= 0 and not room.indoor:
		vitals.text += "\nمحوطه امن شد"
	ammo.text = ("در حال تعویض خشاب" if room.weapon.reload_left > 0.0 else "خشاب  /  ذخیره") \
		+ "\n" + digits(room.weapon.magazine) + "  /  " + digits(room.weapon.reserve)
	prompt.visible = (entry != "" or failure) and not room.defeated
	prompt.text = "ورود در دسترس نیست" if failure else entrance_key() + " \u2014 " + entry
	result.visible = room.defeated or get_tree().paused
	if room.defeated:
		result.text = "بازمانده از پا افتاد\nانتر: شروع دوباره"
	elif get_tree().paused:
		result.text = "توقف\nگریز: ادامهٔ بازی"

func entrance_key() -> String:
	var keys := InputMap.action_get_events("side_entrance")
	if not keys.is_empty() and keys[0] is InputEventKey:
		return "\u2066" + OS.get_keycode_string(keys[0].physical_keycode) + "\u2069"
	return "کلید ورود"

func digits(n: int) -> String:
	var text := str(n)
	for i in range(10):
		text = text.replace(str(i), "۰۱۲۳۴۵۶۷۸۹"[i])
	return text

func fade_to(alpha: float) -> Signal:
	var tween := create_tween()
	tween.tween_property(veil, "color:a", alpha, 0.25)
	return tween.finished

func _unhandled_key_input(event: InputEvent) -> void:
	var room := get_parent()
	if event.is_action_pressed("pause") and not room.transitioning and not room.defeated:
		get_tree().paused = not get_tree().paused
		refresh(room, "")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and room.defeated:
		get_tree().change_scene_to_file("res://scenes/side/Court.tscn")
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F2:
				room.view.toggle_weather()
			KEY_F3:
				room.view.toggle_shadows()
			KEY_F11:
				var window := get_window()
				window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			_:
				return
		get_viewport().set_input_as_handled()
