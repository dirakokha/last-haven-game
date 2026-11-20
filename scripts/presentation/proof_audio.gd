class_name ProofAudio
extends Node2D

const RAIN := preload("res://assets/audio/proof/rain.wav")
const RACK := preload("res://assets/audio/proof/rack_1.wav")
const STEPS: Array[AudioStream] = [preload("res://assets/audio/proof/step_1.wav"), preload("res://assets/audio/proof/step_2.wav"), preload("res://assets/audio/proof/step_3.wav"), preload("res://assets/audio/proof/step_4.wav")]
const SHOTS: Array[AudioStream] = [preload("res://assets/audio/proof/pistol_1.wav"), preload("res://assets/audio/proof/pistol_2.wav"), preload("res://assets/audio/proof/pistol_3.wav")]
const HITS: Array[AudioStream] = [preload("res://assets/audio/proof/impact_1.wav"), preload("res://assets/audio/proof/impact_2.wav"), preload("res://assets/audio/proof/impact_3.wav")]

var rng := RandomNumberGenerator.new()
var voices: Array[AudioStreamPlayer2D] = []
var cursor := 0
var last := {"step": -1, "shot": -1, "hit": -1}

func _ready() -> void:
	rng.randomize()
	var bed := AudioStreamPlayer.new()
	var loop := RAIN.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	bed.stream = loop
	bed.volume_db = -5.0
	add_child(bed)
	bed.play()
	for i in range(8):
		var voice := AudioStreamPlayer2D.new()
		voice.max_distance = 760.0
		voice.attenuation = 0.48
		voice.panning_strength = 0.55
		add_child(voice)
		voices.append(voice)

func step(at: Vector2, running: bool) -> void:
	play(pick("step", STEPS), at, -7.0 if running else -11.0, 1.07 if running else 1.0)

func shot(at: Vector2) -> void:
	play(pick("shot", SHOTS), at, -2.0, 1.0)

func hit(at: Vector2, heavy: bool = false) -> void:
	play(pick("hit", HITS), at, -3.0 if heavy else -8.0, 0.86 if heavy else 1.0)

func reload(at: Vector2) -> void:
	play(RACK, at, -4.0, 1.0)

func pick(key: String, clips: Array[AudioStream]) -> AudioStream:
	var old: int = last[key]
	var index := rng.randi_range(0, clips.size() - 1 - int(old >= 0))
	if old >= 0 and index >= old:
		index += 1
	last[key] = index
	return clips[index]

func play(clip: AudioStream, at: Vector2, db: float, pitch: float) -> void:
	var voice := voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice.global_position = at
	voice.stream = clip
	voice.pitch_scale = pitch * rng.randf_range(0.96, 1.04)
	voice.volume_db = db
	voice.play()
