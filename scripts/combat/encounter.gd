extends Node2D

@onready var yard: Node2D = $Yard
@onready var actors: Node2D = $Yard/FloorActors
@onready var player: CharacterBody2D = $Yard/FloorActors/Player
@onready var hud: ProofHUD = $HUD/Instruments
@onready var weather: ProofWeather = $Yard/Weather
@onready var audio: ProofAudio = $Audio
var weapon := DepotWeapon.new()
var health := 100
var remaining := 0
var immunity := 0.0
var finished := false
var rain_enabled := true
var lamps_enabled := true

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	player.get_node("Coat").hide()
	player.get_node("Head").hide()
	var survivor := SurvivorArt.new()
	survivor.weapon = weapon
	survivor.audio = audio
	player.add_child(survivor)
	weapon.audio = audio
	player.add_child(weapon)
	actors.get_node("CrateFeet/Crate").hide()
	actors.get_node("CrateFeet/Rim").hide()
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
	audio.hit(player.global_position, true)
	if health == 0:
		finish(false)

func enemy_fell() -> void:
	remaining -= 1
	if remaining == 0 and not finished:
		finish(true)

func finish(won: bool) -> void:
	finished = true
	update_hud()
	hud.finish(won)
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
	hud.update(health, weapon, remaining)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_F2:
			rain_enabled = not rain_enabled
		KEY_F3:
			lamps_enabled = not lamps_enabled
		_:
			return
	weather.set_effects(rain_enabled, lamps_enabled)
	$Yard/Footlights.visible = lamps_enabled
	hud.set_effects(rain_enabled, lamps_enabled)
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
