class_name SideWeatherPreferences
extends RefCounted

const FILE := "user://side_preferences.cfg"

static func read() -> bool:
	var config := ConfigFile.new()
	if config.load(FILE) != OK:
		return true
	return bool(config.get_value("weather", "rain", true))

static func save(enabled: bool) -> void:
	var config := ConfigFile.new()
	config.load(FILE)
	config.set_value("weather", "rain", enabled)
	var error := config.save(FILE)
	if error != OK:
		push_warning("Could not write rain preference: %s" % error)
