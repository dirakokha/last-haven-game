class_name WeaponDef
extends Resource
## Shared firearm configuration. Author in the editor; treat as immutable at runtime.

@export var weapon_id: StringName
@export var display_name: String
@export var ammo_id: StringName
@export var magazine_capacity: int
@export var reload_duration: float
@export var fire_cooldown: float
@export var damage: int
@export var projectile_speed: float
@export var projectile_range: float
## Relative to the actor pin, facing right. Only X mirrors when facing left.
@export var muzzle_offset: Vector2

func is_valid() -> bool:
	return _valid_id(weapon_id) and _valid_id(ammo_id) and not display_name.strip_edges().is_empty() \
		and magazine_capacity > 0 and damage > 0 \
		and is_finite(reload_duration) and reload_duration > 0.0 \
		and is_finite(fire_cooldown) and fire_cooldown > 0.0 \
		and is_finite(projectile_speed) and projectile_speed > 0.0 \
		and is_finite(projectile_range) and projectile_range > 0.0 \
		and muzzle_offset.is_finite() and muzzle_offset.x > 0.0

static func _valid_id(id: StringName) -> bool:
	var text := String(id)
	return not text.is_empty() and text == text.strip_edges()
