class_name ItemCatalog
extends RefCounted
## Explicit definition lookup, not a singleton and never a source of counts.

const AMMO_9MM := preload("res://assets/items/ammo_9mm.tres")
const AMMO_45ACP := preload("res://assets/items/ammo_45acp.tres")
const SCRAP_METAL := preload("res://assets/items/scrap_metal.tres")
var _by_id: Dictionary[StringName, ItemDef] = {}
var _valid := false

func _init(definitions: Array[ItemDef] = [AMMO_9MM, AMMO_45ACP, SCRAP_METAL]) -> void:
	for definition in definitions:
		if definition == null or not definition.is_valid() or _by_id.has(definition.item_id):
			_by_id.clear()
			return
		_by_id[definition.item_id] = definition
	_valid = true

func is_valid() -> bool:
	return _valid

func definition_for(id: StringName) -> ItemDef:
	return _by_id.get(id)
