extends BubbleTestCase


func before_each() -> void:
	BubbleSaveManager.clear_checkpoint()
	if FileAccess.file_exists(BubbleSaveManager.SCORES_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BubbleSaveManager.SCORES_FILE))


func test_personal_best_requires_strict_improvement_not_tie() -> void:
	var first_result: Dictionary = BubbleSaveManager.record_score({
		"score": 1000,
		"wave": 10,
		"timestamp": 10,
	})
	assert_true(bool(first_result["is_personal_best"]), "First recorded score should count as the personal best")

	var tied_result: Dictionary = BubbleSaveManager.record_score({
		"score": 1000,
		"wave": 10,
		"timestamp": 20,
	})
	assert_false(bool(tied_result["is_personal_best"]), "A tied top score should not be flagged as a new personal best")


func test_personal_best_allows_better_wave_on_tied_score() -> void:
	BubbleSaveManager.record_score({
		"score": 1000,
		"wave": 10,
		"timestamp": 10,
	})
	var improved_result: Dictionary = BubbleSaveManager.record_score({
		"score": 1000,
		"wave": 11,
		"timestamp": 20,
	})
	assert_true(bool(improved_result["is_personal_best"]), "Matching the score but reaching a higher wave should count as a new personal best")
