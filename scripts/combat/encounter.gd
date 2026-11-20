extends Node2D

@onready var yard: Node2D = $Yard
@onready var actors: Node2D = $Yard/FloorActors
@onready var player: CharacterBody2D = $Yard/FloorActors/Player
@onready var hud: Label = $HUD/Status
var weapon := DepotWeapon.new()
var health := 100
var remaining := 0
var immunity := 0.0
var finished := false
var impact := AudioStreamPlayer.new()

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	player.add_child(weapon)
	add_child(impact)
	impact.stream = preload("res://assets/audio/growl.wav")
	var second := actors.get_node("CrateFeet").duplicate() as StaticBody2D
	second.position = Vector2(900,398)
	actors.add_child(second)
	spawn(Vector2(690,265), false)
	spawn(Vector2(950,356), true)
	spawn(Vector2(1120,435), false)
	spawn(Vector2(175,235), false)

func spawn(at: Vector2, fast: bool) -> void:
	var zombie := DepotZombie.new()
	zombie.target = player
	zombie.runner = fast
	zombie.position = at
	zombie.strikes.connect(take_damage)
	zombie.fell.connect(enemy_fell)
	actors.add_child(zombie)
	zombie.add_to_group("infected")
	remaining += 1

func take_damage(amount: int) -> void:
	if finished or immunity > 0:
		return
	health = maxi(0, health - amount)
	immunity = 0.7
	impact.play()
	if health == 0:
		finish(false)

func enemy_fell() -> void:
	remaining -= 1
	if remaining == 0 and not finished:
		finish(true)

func finish(won: bool) -> void:
	finished = true
	update_hud()
	$HUD/Result.text = ("محوطه امن شد" if won else "سقوط کردی") + "\nشروع دوباره: Enter"
	$HUD/Result.show()
	# Freeze only the yard. The restart handler stays alive.
	yard.process_mode = Node.PROCESS_MODE_DISABLED
	$Yard/Pause.process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if finished:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	immunity = maxf(0, immunity - delta)
	player.modulate = Color("ff978a") if immunity > 0 else Color.WHITE
	update_hud()

func update_hud() -> void:
	hud.text = "سلامت: %d    |    خشاب: %d    |    ذخیره: %d    |    آلوده: %d" % [health, weapon.magazine, weapon.reserve, remaining]
	if weapon.reload_left > 0:
		hud.text += "    •    تعویض خشاب…"

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
