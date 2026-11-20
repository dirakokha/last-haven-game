class_name SideReviewAudio
extends Node2D

const SHOTS: Array[AudioStream] = [preload("res://assets/side_review/gate_pistol_1.wav"), preload("res://assets/side_review/gate_pistol_2.wav")]
const STEPS: Array[AudioStream] = [preload("res://assets/side_review/gate_step_1.wav"), preload("res://assets/side_review/gate_step_2.wav")]
const VOCAL: Array[AudioStream] = [preload("res://assets/side_review/gate_walker_1.wav"), preload("res://assets/side_review/gate_walker_2.wav")]
const IMPACT: Array[AudioStream] = [preload("res://assets/side_review/gate_impact_1.wav"), preload("res://assets/side_review/gate_impact_2.wav")]
const RACK := preload("res://assets/audio/proof/rack_1.wav")
const RAIN := preload("res://assets/audio/proof/rain.wav")
var voices: Array[AudioStreamPlayer2D] = []
var index := 0
var shot_index := 0
var step_index := 0

func setup(exterior: bool) -> void:
	for i in range(6):
		var voice := AudioStreamPlayer2D.new()
		voice.max_distance = 920.0
		voice.attenuation = 0.36
		add_child(voice)
		voices.append(voice)
	if exterior:
		var bed := AudioStreamPlayer.new()
		var loop := RAIN.duplicate() as AudioStreamWAV
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
		bed.stream = loop
		bed.volume_db = -6.0
		add_child(bed)
		bed.play()

func fire(at: Vector2) -> void:
	play(SHOTS[shot_index], at, -2.0)
	shot_index = 1 - shot_index

func step(at: Vector2, running: bool) -> void:
	play(STEPS[step_index], at, -4.5 if running else -6.5, 1.08 if running else 1.0)
	step_index = 1 - step_index

func warning(at: Vector2, runner: bool) -> void:
	play(VOCAL[1 if runner else 0], at, 0.0)

func reload(at: Vector2) -> void:
	play(RACK, at, -4.0)

func strike(at: Vector2, surface: StringName) -> void:
	play(IMPACT[1 if surface == &"metal" else 0], at, -6.0 if surface == &"concrete" else -3.0)

func play(stream: AudioStream, at: Vector2, volume: float, pitch: float = 1.0) -> void:
	var voice := voices[index]
	index = (index + 1) % voices.size()
	voice.global_position = at
	voice.stream = stream
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.play()
