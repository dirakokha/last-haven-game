class_name SideReviewAudio
extends Node2D

const RAIN := preload("res://assets/audio/proof/rain.wav")
const CLIPS := {
	&"breath": preload("res://assets/side_review/recorded/breath.wav"),
	&"casing_0": preload("res://assets/side_review/recorded/casing_0.wav"),
	&"casing_1": preload("res://assets/side_review/recorded/casing_1.wav"),
	&"concrete": preload("res://assets/side_review/recorded/concrete.wav"),
	&"hurt": preload("res://assets/side_review/recorded/hurt.wav"),
	&"infected": preload("res://assets/side_review/recorded/infected.wav"),
	&"mag_insert": preload("res://assets/side_review/recorded/mag_insert.wav"),
	&"mag_release": preload("res://assets/side_review/recorded/mag_release.wav"),
	&"melee": preload("res://assets/side_review/recorded/melee.wav"),
	&"metal": preload("res://assets/side_review/recorded/metal.wav"),
	&"report_0": preload("res://assets/side_review/recorded/report_0.wav"),
	&"report_1": preload("res://assets/side_review/recorded/report_1.wav"),
	&"report_2": preload("res://assets/side_review/recorded/report_2.wav"),
	&"report_3": preload("res://assets/side_review/recorded/report_3.wav"),
	&"runner_attack": preload("res://assets/side_review/recorded/runner_attack.wav"),
	&"runner_breath": preload("res://assets/side_review/recorded/runner_breath.wav"),
	&"runner_damage": preload("res://assets/side_review/recorded/runner_damage.wav"),
	&"runner_death": preload("res://assets/side_review/recorded/runner_death.wav"),
	&"runner_warn": preload("res://assets/side_review/recorded/runner_warn.wav"),
	&"slide": preload("res://assets/side_review/recorded/slide.wav"),
	&"step_case": preload("res://assets/side_review/recorded/step_case.wav"),
	&"step_stone": preload("res://assets/side_review/recorded/step_stone.wav"),
	&"walker_attack": preload("res://assets/side_review/recorded/walker_attack.wav"),
	&"walker_breath": preload("res://assets/side_review/recorded/walker_breath.wav"),
	&"walker_damage": preload("res://assets/side_review/recorded/walker_damage.wav"),
	&"walker_death": preload("res://assets/side_review/recorded/walker_death.wav"),
	&"walker_warn": preload("res://assets/side_review/recorded/walker_warn.wav"),
	&"warehouse": preload("res://assets/side_review/recorded/warehouse.wav"),
}
var pools := {}
var rain: AudioStreamPlayer
var warehouse: AudioStreamPlayer
var report_index := 0
var casing_index := 0
var steps := 0

func setup(exterior: bool, rain_enabled: bool) -> void:
	add_pool(&"Weapons", 6, 780.0, 0.36)
	add_pool(&"Player", 4, 590.0, 0.46)
	add_pool(&"Zombies", 3, 470.0, 0.75)
	if exterior:
		rain = bed(RAIN, -11.0)
		set_rain(rain_enabled)
	else:
		warehouse = bed(CLIPS[&"warehouse"], -15.0)
		warehouse.play()

func add_pool(bus: StringName, count: int, distance: float, falloff: float) -> void:
	var voices: Array[AudioStreamPlayer2D] = []
	for i in range(count):
		var voice := AudioStreamPlayer2D.new()
		voice.bus = bus
		voice.max_distance = distance
		voice.attenuation = falloff
		add_child(voice)
		voices.append(voice)
	pools[bus] = voices

func bed(source: AudioStreamWAV, level: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var loop := source.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	player.stream = loop
	player.bus = &"Environment"
	player.volume_db = level
	add_child(player)
	return player

func set_rain(enabled: bool) -> void:
	if rain == null:
		return
	if enabled and not rain.playing:
		rain.play()
	elif not enabled:
		rain.stop()

func fire(at: Vector2, _direction: int) -> void:
	play(StringName("report_%d" % report_index), &"Weapons", at, -1.0, 1.0, true)
	report_index = (report_index + 1) % 4

func casing(at: Vector2) -> void:
	play(StringName("casing_%d" % casing_index), &"Weapons", at, -12.0)
	casing_index = 1 - casing_index

func step(at: Vector2, running: bool, surface: StringName) -> void:
	steps += 1
	var cue := &"step_case" if surface == &"metal" else &"step_stone"
	var level := -7.0 if running else -10.0
	if cue == &"step_case":
		level -= 4.0
	play(cue, &"Player", at, level, (1.06 if running else 0.98) + (0.038 if steps % 2 == 0 else -0.018))

func breath(at: Vector2) -> void:
	play(&"breath", &"Player", at, -15.0)

func pain(at: Vector2) -> void:
	play(&"hurt", &"Player", at, -8.0, 1.09)

func vocal(at: Vector2, runner: bool, event: StringName) -> void:
	var warning := event == &"warn" or event == &"attack"
	play(StringName(("runner_" if runner else "walker_") + str(event)), &"Zombies", at,
		-17.0 if event == &"breath" else (-5.0 if warning else -9.0), 1.12 if runner else 0.91,
		event == &"death")

func handling(at: Vector2, stage: StringName) -> void:
	var cue := &"mag_release" if stage == &"release" else (&"mag_insert" if stage == &"insert" else &"slide")
	play(cue, &"Weapons", at, -8.0)

func impact(at: Vector2, material: StringName) -> void:
	play(material, &"Weapons", at, -9.0 if material == &"metal" else -7.0)

func play(cue: StringName, bus: StringName, at: Vector2, level: float, pitch: float = 1.0, priority: bool = false) -> void:
	if not CLIPS.has(cue):
		return
	var voices: Array[AudioStreamPlayer2D] = pools[bus]
	var voice: AudioStreamPlayer2D
	for slot in voices:
		if not slot.playing:
			voice = slot
			break
	if voice == null:
		if not priority:
			return
		voice = voices[0]
		voice.stop()
	voice.global_position = at
	voice.stream = CLIPS[cue]
	voice.volume_db = level
	voice.pitch_scale = pitch
	voice.play()
