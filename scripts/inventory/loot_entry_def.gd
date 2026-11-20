class_name LootEntryDef
extends Resource
## An authored starting quantity, not a live stack.

@export var item: ItemDef
@export var quantity: int = 1

func is_valid() -> bool:
	return item != null and item.is_valid() and quantity > 0
