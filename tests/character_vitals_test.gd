extends SceneTree

var failures := 0
var changes: Array[Vector2i] = []
var deaths := 0
var subject: CharacterVitals

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("CharacterVitals: " + label)

func run() -> void:
	subject = CharacterVitals.new(100, 80)
	subject.health_changed.connect(func(previous: int, current: int) -> void:
		changes.append(Vector2i(previous, current)))
	subject.depleted.connect(func() -> void:
		deaths += 1
		check(subject.is_depleted(), "depletion listener sees committed state")
		# One callback cannot restart this life before other listeners see death.
		subject.reset())
	check(subject.max_health == 100 and subject.health == 80, "configured initial health")
	check(subject.apply_damage(0) == 0 and subject.apply_damage(-5) == 0, "invalid damage is ignored")
	check(subject.apply_healing(0) == 0 and subject.apply_healing(-5) == 0, "invalid healing is ignored")
	check(subject.apply_damage(15) == 15 and subject.health == 65, "normal damage")
	check(subject.apply_healing(10) == 10 and subject.health == 75, "normal healing")
	check(subject.apply_healing(1000) == 25 and subject.health == 100, "healing clamps at maximum")
	check(subject.apply_healing(1) == 0, "already at maximum")
	check(subject.apply_damage(1000) == 100 and subject.health == 0, "overkill clamps at zero")
	check(subject.apply_damage(1) == 0 and subject.apply_healing(20) == 0 and deaths == 1,
		"one death per life; no postmortem damage or healing")
	subject.reset()
	check(subject.health == 80 and not subject.is_depleted(), "reset restores configured starting health")
	subject.reset()
	check(subject.apply_damage(80) == 80 and deaths == 2, "new life can die once again")
	check(changes == [Vector2i(80, 65), Vector2i(65, 75), Vector2i(75, 100),
		Vector2i(100, 0), Vector2i(0, 80), Vector2i(80, 0)], "only real changes notify, with old and new HP")

	var initially_depleted := CharacterVitals.new(65, -1)
	check(initially_depleted.is_depleted() and initially_depleted.apply_damage(1) == 0,
		"an initially depleted instance does not take damage")
	var clamped := CharacterVitals.new(65, 100)
	check(clamped.health == 65, "oversized initial health is clamped")

	var player := SidePlayer.new()
	var walker := SideWalker.new()
	check(player.vitals.health == 100 and walker.vitals.health == 65, "each actor has its original starting health")
	check(player.vitals.apply_damage(15) == 15 and walker.vitals.health == 65, "player damage does not affect Walker")
	check(walker.vitals.apply_damage(24) == 24 and player.vitals.health == 85, "Walker damage does not affect player")
	subject = null
	player.free()
	walker.free()
	if failures == 0:
		print("PASS: CharacterVitals initialization, damage/healing bounds, reset, notifications and independent actors")
	quit(0 if failures == 0 else 1)
