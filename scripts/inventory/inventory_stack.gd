class_name InventoryStack
extends RefCounted
## Private to its owning SideInventory. Definition data is shared, quantities are not.

var definition: ItemDef
var quantity: int

func _init(item: ItemDef, units: int) -> void:
	definition = item
	quantity = units
