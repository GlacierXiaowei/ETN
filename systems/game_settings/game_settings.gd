extends Node

var debug_mode: bool = false
var settings_path: String = "user://settings.json"

signal debug_mode_changed(enabled: bool)

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			debug_mode = data.get("debug_mode", false)
			print("[GameSettings] Loaded: debug_mode=%s" % debug_mode)
		else:
			print("[GameSettings] Parse error, using defaults")
	else:
		print("[GameSettings] No settings file, using defaults")
		save_settings()

func save_settings() -> void:
	var data = {
		"debug_mode": debug_mode
	}
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		print("[GameSettings] Saved: debug_mode=%s" % debug_mode)

func set_debug_mode(enabled: bool) -> void:
	if debug_mode != enabled:
		debug_mode = enabled
		save_settings()
		debug_mode_changed.emit(enabled)
		print("[GameSettings] Debug mode changed: %s" % enabled)

func get_debug_mode() -> bool:
	return debug_mode