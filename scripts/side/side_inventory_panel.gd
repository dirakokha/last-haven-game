class_name SideInventoryPanel
extends PanelContainer
## Read-only placeholder. The HUD owns input and pause; this view owns no item state.

const FONT := preload("res://assets/fonts/Vazirmatn-Regular.ttf")
var slots: Label
var items: Label
var _inventory: SideInventory

func _ready() -> void:
	position = Vector2(255, 106)
	custom_minimum_size = Vector2(450, 304)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for edge in ["top", "bottom", "left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	label(column, tr("موجودی"), 22)
	slots = label(column, "", 16)
	items = label(column, "", 16)
	items.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label(column, tr("بستن: %s یا %s") % [_ltr("Tab"), _ltr("Esc")], 14)
	hide()

func bind(inventory: SideInventory) -> void:
	_inventory = inventory
	_inventory.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	slots.text = tr("خانه‌های پُر: %s") % _ltr("%d / %d" % [_inventory.occupied_slots(), _inventory.capacity])
	var lines := PackedStringArray()
	for row in _inventory.stack_rows():
		lines.append(tr("%s  ×  %s  ·  %s") % [tr(row.name), _ltr(str(row.quantity)), _ltr(String(row.id))])
	items.text = tr("موجودی خالی است") if lines.is_empty() else "\n".join(lines)

func label(parent: VBoxContainer, text: String, font_size: int) -> Label:
	var item := Label.new()
	item.text_direction = Control.TEXT_DIRECTION_RTL
	item.language = "fa"
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_override("font", FONT)
	item.add_theme_font_size_override("font_size", font_size)
	item.text = text
	parent.add_child(item)
	return item

func _ltr(text: String) -> String:
	return "\u2066" + text + "\u2069"
