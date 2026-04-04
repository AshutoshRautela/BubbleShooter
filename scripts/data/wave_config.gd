class_name BubbleWaveConfig
extends RefCounted

const MIN_COLORS := 4
const DEFAULT_DATA_PATH := "res://data/waves_v0_1.json"

var max_palette_size: int
var data_path: String
var waves: Array[Dictionary] = []


func _init(palette_size: int, source_path: String = DEFAULT_DATA_PATH) -> void:
	max_palette_size = maxi(MIN_COLORS, palette_size)
	data_path = source_path
	_load_wave_table()


func get_wave_data(wave_number: int) -> Dictionary:
	if waves.is_empty():
		return {}
	var clamped_wave: int = clampi(wave_number, 1, waves.size())
	return waves[clamped_wave - 1].duplicate(true)


func get_defined_wave_count() -> int:
	return waves.size()


func _load_wave_table() -> void:
	waves.clear()
	var json_text: String = _read_wave_json()
	if json_text.is_empty():
		push_error("Wave config file is empty: %s" % data_path)
		return

	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Array:
		push_error("Wave config must be an array: %s" % data_path)
		return

	for entry in parsed:
		if not entry is Dictionary:
			push_error("Invalid wave entry in %s" % data_path)
			continue
		var normalized: Dictionary = _normalize_wave_entry(entry)
		if normalized.is_empty():
			continue
		waves.append(normalized)

	if waves.is_empty():
		push_error("No valid waves loaded from %s" % data_path)
		return

	waves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["wave"]) < int(b["wave"])
	)
	_validate_wave_sequence()


func _read_wave_json() -> String:
	if not FileAccess.file_exists(data_path):
		push_error("Missing wave config file: %s" % data_path)
		return ""
	var file: FileAccess = FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open wave config file: %s" % data_path)
		return ""
	return file.get_as_text()


func _normalize_wave_entry(entry: Dictionary) -> Dictionary:
	if not entry.has("wave"):
		push_error("Wave entry missing wave number in %s" % data_path)
		return {}

	return {
		"wave": maxi(int(entry.get("wave", 1)), 1),
		"colors": clampi(int(entry.get("colors", MIN_COLORS)), MIN_COLORS, max_palette_size),
		"shots_per_shift": maxi(int(entry.get("shots_per_shift", 5)), 1),
		"start_rows": maxi(int(entry.get("start_rows", 6)), 1),
		"board_density": clampf(float(entry.get("board_density", 0.82)), 0.55, 1.0),
		"push_density": clampf(float(entry.get("push_density", 0.9)), 0.55, 1.0),
		"board_type": String(entry.get("board_type", "random")),
		"score_multiplier": maxf(float(entry.get("score_multiplier", 1.0)), 1.0),
		"badge": String(entry.get("badge", "")),
		"cannon_power_pool": Array(entry.get("cannon_power_pool", []), TYPE_STRING, &"", null),
	}


func _validate_wave_sequence() -> void:
	var seen: Dictionary = {}
	var expected_wave: int = 1
	for entry in waves:
		var wave_number: int = int(entry["wave"])
		if seen.has(wave_number):
			push_error("Duplicate wave %d in %s" % [wave_number, data_path])
			continue
		seen[wave_number] = true
		if wave_number != expected_wave:
			push_warning("Expected wave %d but found wave %d in %s" % [expected_wave, wave_number, data_path])
			expected_wave = wave_number
		expected_wave += 1
