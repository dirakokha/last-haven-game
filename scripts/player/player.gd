extends CharacterBody2D

@export var walk_speed: float = 155.0
@export var sprint_multiplier: float = 1.6

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_far", "move_near")
	direction.y *= 0.65
	velocity = direction * walk_speed
	if Input.is_action_pressed("sprint"):
		velocity *= sprint_multiplier
	move_and_slide()
