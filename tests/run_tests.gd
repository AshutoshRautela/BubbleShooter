extends SceneTree

const TEST_SCRIPTS := [
	"res://tests/unit/test_wave_config.gd",
	"res://tests/unit/test_wave_spawn.gd",
	"res://tests/unit/test_board_state.gd",
	"res://tests/unit/test_burst_sequence_guard.gd",
	"res://tests/unit/test_burst_phases.gd",
	"res://tests/unit/test_save_manager.gd",
	"res://tests/unit/test_shot_planner.gd",
]


func _initialize() -> void:
	var total_cases: int = 0
	var total_failures: int = 0

	for script_path in TEST_SCRIPTS:
		var script: GDScript = load(script_path)
		if script == null:
			push_error("Failed to load test script: %s" % script_path)
			total_failures += 1
			continue
		var test_case = script.new()
		if not test_case.has_method("run_tests"):
			push_error("Invalid test case script: %s" % script_path)
			total_failures += 1
			continue
		var result: Dictionary = test_case.run_tests()
		total_cases += int(result["cases"])
		total_failures += int(result["failures"].size())

	print("TEST SUMMARY: %d cases, %d failures" % [total_cases, total_failures])
	quit(0 if total_failures == 0 else 1)
