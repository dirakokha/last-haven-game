class_name ItemDef
extends Resource
## Author once; treat definition resources as immutable during a run.

enum Category { OTHER, AMMUNITION }

@export var item_id: StringName
@export var display_name: String
@export var max_stack: int = 1
@export var category: Category = Category.OTHER

func is_valid() -> bool:
	if item_id == &"" or display_name.strip_edges().is_empty() or max_stack <= 0 \
		or category not in [Category.OTHER, Category.AMMUNITION]:
		return false
	# Lowercase ASCII ID segments; punctuation is only allowed inside a segment.
	for segment in String(item_id).split("."):
		if segment.is_empty() or not _alphanumeric(segment.unicode_at(0)) \
			or not _alphanumeric(segment.unicode_at(segment.length() - 1)):
			return false
		for i in range(segment.length()):
			if not _alphanumeric(segment.unicode_at(i)) and segment[i] not in ["_", "-"]:
				return false
	return true

static func _alphanumeric(code: int) -> bool:
	return (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
