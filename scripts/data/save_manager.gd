class_name BubbleSaveManager
extends RefCounted

const SAVE_FILE := "user://save.cfg"
const SCORES_FILE := "user://scores.cfg"
const SETTINGS_FILE := "user://settings.cfg"
const MAX_HIGH_SCORES := 5
const DEFAULT_SETTINGS := {
	"sfx_enabled": true,
	"sfx_volume": 1.0,
	"show_fps_debug": true,
	"onboarding_complete": false,
}

static var _launch_request: Dictionary = {}


static func set_launch_request(request: Dictionary) -> void:
	_launch_request = request.duplicate(true)


static func consume_launch_request() -> Dictionary:
	var request: Dictionary = _launch_request.duplicate(true)
	_launch_request.clear()
	return request


static func load_settings() -> Dictionary:
	var config: ConfigFile = ConfigFile.new()
	var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
	if config.load(SETTINGS_FILE) != OK:
		return settings
	for key in settings.keys():
		settings[key] = config.get_value("settings", key, settings[key])
	return settings


static func save_settings(settings: Dictionary) -> void:
	var merged: Dictionary = DEFAULT_SETTINGS.duplicate(true)
	for key in settings.keys():
		merged[key] = settings[key]
	var config: ConfigFile = ConfigFile.new()
	for key in merged.keys():
		config.set_value("settings", key, merged[key])
	config.save(SETTINGS_FILE)


static func is_onboarding_complete() -> bool:
	return bool(load_settings()["onboarding_complete"])


static func set_onboarding_complete(is_complete: bool) -> void:
	var settings: Dictionary = load_settings()
	settings["onboarding_complete"] = is_complete
	save_settings(settings)


static func has_checkpoint() -> bool:
	return not load_checkpoint().is_empty()


static func load_checkpoint() -> Dictionary:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_FILE) != OK:
		return {}
	var checkpoint: Dictionary = {}
	for key in [
		"board_state",
		"current_color",
		"next_color",
		"wave",
		"score",
		"saved_at_unix",
	]:
		if config.has_section_key("run", key):
			checkpoint[key] = config.get_value("run", key)
	if not checkpoint.has("board_state"):
		return {}
	return checkpoint


static func save_checkpoint(checkpoint: Dictionary) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("run", "board_state", checkpoint.get("board_state", {}))
	config.set_value("run", "current_color", int(checkpoint.get("current_color", 0)))
	config.set_value("run", "next_color", int(checkpoint.get("next_color", 0)))
	config.set_value("run", "wave", int(checkpoint.get("wave", 1)))
	config.set_value("run", "score", int(checkpoint.get("score", 0)))
	config.set_value("run", "saved_at_unix", Time.get_unix_time_from_system())
	config.save(SAVE_FILE)


static func clear_checkpoint() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))


static func load_high_scores() -> Array[Dictionary]:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SCORES_FILE) != OK:
		return []
	var entries: Array[Dictionary] = []
	for entry in Array(config.get_value("scores", "entries", [])):
		if entry is Dictionary:
			entries.append(_normalize_score_entry(entry))
	return entries


static func record_score(entry: Dictionary) -> Dictionary:
	var entries: Array[Dictionary] = load_high_scores()
	var normalized_entry: Dictionary = _normalize_score_entry(entry)
	var previous_best: Dictionary = entries[0].duplicate(true) if not entries.is_empty() else {}
	entries.append(normalized_entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) == int(b["score"]):
			return int(a["wave"]) > int(b["wave"])
		return int(a["score"]) > int(b["score"])
	)
	if entries.size() > MAX_HIGH_SCORES:
		entries.resize(MAX_HIGH_SCORES)
	var config: ConfigFile = ConfigFile.new()
	config.set_value("scores", "entries", entries)
	config.save(SCORES_FILE)

	var rank: int = -1
	for index in range(entries.size()):
		if entries[index] == normalized_entry:
			rank = index + 1
			break

	return {
		"entries": entries,
		"rank": rank,
		"is_personal_best": _is_new_personal_best(normalized_entry, previous_best),
	}


static func _normalize_score_entry(entry: Dictionary) -> Dictionary:
	return {
		"score": int(entry.get("score", 0)),
		"wave": int(entry.get("wave", 1)),
		"timestamp": int(entry.get("timestamp", Time.get_unix_time_from_system())),
	}


static func _is_new_personal_best(entry: Dictionary, previous_best: Dictionary) -> bool:
	if previous_best.is_empty():
		return true
	var score: int = int(entry.get("score", 0))
	var wave: int = int(entry.get("wave", 1))
	var best_score: int = int(previous_best.get("score", 0))
	var best_wave: int = int(previous_best.get("wave", 1))
	if score > best_score:
		return true
	if score == best_score and wave > best_wave:
		return true
	return false
