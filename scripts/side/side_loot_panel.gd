class_name SideLootPanel
extends PanelContainer
## Read-only rows and selected-stack requests. SideHUD owns modal input and pause.

const FONT := preload("res://assets/fonts/Vazirmatn-Regular.ttf")
const INK := Color("dce1d6")
const ACCENT := Color("c9af79")
var loot_title: Label
var inventory_title: Label
var controls: Label
var status: Label
var loot_list: ItemList
var player_list: ItemList
var _source: SideInventory
var _destination: SideInventory
var _rows: Array[Dictionary] = []
var _selected := 0

func _ready() -> void:
	position = Vector2(120, 94)
	custom_minimum_size = Vector2(720, 352)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for edge in ["top", "bottom", "left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	var loot := _column(columns)
	loot_title = _label(loot, "LOOT", 21)
	loot_list = _list(loot)
	var player := _column(columns)
	inventory_title = _label(player, "INVENTORY", 21)
	player_list = _list(player)
	status = _label(layout, "", 15)
	status.custom_minimum_size.y = 24.0
	status.add_theme_color_override("font_color", ACCENT)
	controls = _label(layout, "Up / Down — SELECT    ·    Enter — TAKE    ·    Esc — CLOSE", 15)
	hide()

func open(source: SideInventory, destination: SideInventory) -> bool:
	if visible or source == null or destination == null or source == destination:
		return false
	_source = source
	_destination = destination
	_selected = 0
	_source.changed.connect(_refresh)
	_destination.changed.connect(_refresh)
	_refresh()
	show()
	return true

func close() -> void:
	if _source != null:
		_source.changed.disconnect(_refresh)
		_destination.changed.disconnect(_refresh)
	_source = null
	_destination = null
	_rows.clear()
	hide()

func move_selection(offset: int) -> void:
	if _rows.is_empty():
		return
	_selected = posmod(_selected + offset, _rows.size())
	_select_row()

func take_selected() -> void:
	if _rows.is_empty():
		return
	var row: Dictionary = _rows[_selected]
	var requested: int = row.quantity
	var moved := _source.transfer_to(_destination, row.id, requested, _selected)
	if moved < requested:
		status.text = "INVENTORY FULL" if moved == 0 and _destination.occupied_slots() == _destination.capacity \
			else "INSUFFICIENT CAPACITY"

func _refresh() -> void:
	_rows = _source.stack_rows()
	_fill(loot_list, _rows)
	var player_rows := _destination.stack_rows()
	_fill(player_list, player_rows)
	if player_rows.is_empty():
		player_list.add_item("EMPTY", null, false)
	inventory_title.text = "INVENTORY  ·  SLOTS %s" % _ltr("%d / %d" % [_destination.occupied_slots(), _destination.capacity])
	status.text = "EMPTY" if _rows.is_empty() else ""
	_selected = clampi(_selected, 0, maxi(0, _rows.size() - 1))
	_select_row()

func _select_row() -> void:
	if not _rows.is_empty():
		loot_list.select(_selected)
		loot_list.ensure_current_is_visible()

func _fill(list: ItemList, rows: Array[Dictionary]) -> void:
	list.clear()
	for row in rows:
		var index := list.add_item("%s  ×  %s" % [tr(row.name), _ltr(str(row.quantity))])
		list.set_item_text_direction(index, Control.TEXT_DIRECTION_RTL)
		list.set_item_language(index, "fa")

func _column(parent: HBoxContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	return column

func _list(parent: VBoxContainer) -> ItemList:
	var list := ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.focus_mode = Control.FOCUS_NONE
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_font_override("font", FONT)
	list.add_theme_font_size_override("font_size", 17)
	list.add_theme_color_override("font_color", INK)
	var selection := StyleBoxFlat.new()
	selection.bg_color = Color("303b3c")
	list.add_theme_stylebox_override("selected", selection)
	list.add_theme_stylebox_override("selected_focus", selection)
	parent.add_child(list)
	return list

func _label(parent: VBoxContainer, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.text_direction = Control.TEXT_DIRECTION_LTR
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	parent.add_child(label)
	return label

func _ltr(text: String) -> String:
	return "\u2066" + text + "\u2069"
