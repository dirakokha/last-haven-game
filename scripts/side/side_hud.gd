class_name SideHUD
extends CanvasLayer

const FONT := preload("res://assets/fonts/Vazirmatn-Regular.ttf")
const INK := Color("dce1d6")
const MUTED := Color("a4b4ac")
const ACCENT := Color("c9af79")
var location: Label
var weather: Label
var vitals: Label
var condition: Label
var instrument: Label
var mag_count: Label
var reserve_count: Label
var gear: Label
var prompt: Label
var result: Label
var veil: ColorRect
var health_track: ColorRect
var health_fill: ColorRect
var failure := false
var inventory_panel: SideInventoryPanel
var _paused_before_inventory := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	frame(Rect2(22, 22, 178, 54))
	location = label(Rect2(30, 25, 162, 26), "", 16)
	weather = label(Rect2(30, 49, 162, 19), "", 13, MUTED)
	frame(Rect2(744, 22, 194, 76))
	vitals = label(Rect2(755, 26, 172, 26), "", 18)
	health_track = rule(Rect2(756, 56, 170, 4), Color("303b3c"))
	health_fill = rule(Rect2(756, 56, 170, 4), Color("87a291"))
	condition = label(Rect2(755, 64, 172, 24), "", 14, MUTED)
	frame(Rect2(723, 429, 215, 89))
	instrument = label(Rect2(734, 432, 193, 26), "", 17)
	rule(Rect2(735, 461, 190, 1), Color("4c5450"))
	mag_count = label(Rect2(821, 464, 106, 24), "", 16, ACCENT)
	reserve_count = label(Rect2(734, 464, 84, 24), "", 14, MUTED)
	gear = label(Rect2(734, 489, 193, 21), "", 13, MUTED)
	label(Rect2(22, 468, 544, 20), tr("حرکت %s   ·   پرش: فاصله   ·   دویدن: شیفت   ·   جاخالی: کنترل") % ltr("A / D"), 14, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	label(Rect2(22, 492, 544, 20), tr("شلیک: کلیک چپ   ·   تعویض خشاب %s   ·   ضربه %s") % [ltr("R"), ltr("F")], 14, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	prompt = label(Rect2(312, 366, 336, 38), "", 18)
	prompt.add_theme_stylebox_override("normal", backing())
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.hide()
	result = label(Rect2(304, 202, 352, 112), "", 23)
	result.add_theme_stylebox_override("normal", backing())
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.hide()
	inventory_panel = SideInventoryPanel.new()
	inventory_panel.add_theme_stylebox_override("panel", backing())
	add_child(inventory_panel)
	inventory_panel.bind(get_parent().player.inventory)
	veil = ColorRect.new()
	veil.color = Color("101822")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	fade_to(0.0)

func backing() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.042, 0.064, 0.073, 0.94)
	panel.border_color = Color("75837a")
	panel.border_width_right = 2
	panel.border_width_bottom = 1
	return panel

func frame(bounds: Rect2) -> void:
	var panel := Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", backing())
	add_child(panel)

func rule(bounds: Rect2, tint: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = bounds.position
	rect.size = bounds.size
	rect.color = tint
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect

func label(bounds: Rect2, text: String, size: int, tint: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT) -> Label:
	var item := Label.new()
	item.position = bounds.position
	item.size = bounds.size
	item.text_direction = Control.TEXT_DIRECTION_RTL
	item.language = "fa"
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_override("font", FONT)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", tint)
	item.text = text
	add_child(item)
	return item

func refresh(room: Node, entry: SideInteractable = null) -> void:
	var player_vitals: CharacterVitals = room.player.vitals
	var hp := player_vitals.health
	location.text = tr("انبار" if room.indoor else "محوطهٔ بارگیری")
	weather.text = tr("باران روشن %s" if room.rain_enabled else "باران خاموش %s") % ltr("F2")
	vitals.text = tr("سلامت  %s") % digits(hp)
	health_fill.size.x = health_track.size.x * clampf(float(hp) / player_vitals.max_health, 0.0, 1.0)
	health_fill.color = Color("a0544e") if hp <= 30 else Color("87a291")
	condition.text = tr("از پا افتاده" if room.defeated else ("آسیب‌دیده" if hp < player_vitals.max_health else "سالم"))
	var firearm: WeaponInstance = room.weapon.firearm
	var name_text := tr(firearm.definition.display_name)
	if room.weapon.bat_phase != SideWeapon.BatPhase.NONE and not room.defeated:
		instrument.text = tr("چوب‌دست  ·  ضربه")
	elif room.weapon.reload_left > 0.0 and not room.defeated:
		instrument.text = tr("%s  ·  تعویض خشاب") % name_text
	else:
		instrument.text = tr("%s  ·  خشاب خالی") % name_text if firearm.magazine == 0 else name_text
	mag_count.text = tr("خشاب %s") % digits(firearm.magazine)
	reserve_count.text = tr("ذخیره %s") % digits(room.player.reserve_for(firearm.definition.ammo_id))
	gear.text = tr("چوب‌دست  ·  ضربه %s") % ltr("F")
	var message := ""
	if not room.defeated and not room.transitioning and not get_tree().paused:
		if entry != null:
			message = tr("%s — %s") % [action_key(entry.input_action), entry.interaction_prompt()]
		elif failure:
			message = tr("ورود در دسترس نیست")
	if prompt.text != message:
		prompt.text = message
	prompt.visible = not message.is_empty()
	result.visible = room.defeated or (get_tree().paused and not inventory_panel.visible)
	if room.defeated:
		result.text = tr("بازمانده از پا افتاد\nانتر: شروع دوباره")
	elif get_tree().paused:
		result.text = tr("توقف\nگریز: ادامهٔ بازی")

func ltr(text: String) -> String:
	return "\u2066" + text + "\u2069"

func action_key(action: StringName) -> String:
	for binding in InputMap.action_get_events(action):
		if binding is InputEventKey:
			var code: Key = binding.physical_keycode if binding.physical_keycode != 0 else binding.keycode
			return ltr(OS.get_keycode_string(code))
	return tr("کلید تعامل")

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
	if inventory_panel.visible and (event.is_action_pressed("side_inventory") or event.is_action_pressed("pause")):
		inventory_panel.hide()
		get_tree().paused = _paused_before_inventory
		refresh(room)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("side_inventory") and not room.transitioning and not room.defeated:
		_paused_before_inventory = get_tree().paused
		get_tree().paused = true
		inventory_panel.show()
		refresh(room)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and not room.transitioning and not room.defeated:
		get_tree().paused = not get_tree().paused
		refresh(room)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and room.defeated:
		get_viewport().set_input_as_handled()
		room.restart_after_defeat()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F2:
				room.toggle_rain()
				refresh(room)
			KEY_F3:
				room.view.toggle_shadows()
			KEY_F11:
				var window := get_window()
				window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			_:
				return
		get_viewport().set_input_as_handled()
