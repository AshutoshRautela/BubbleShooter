extends BubbleTestCase


func test_loads_first_25_waves() -> void:
	var config: BubbleWaveConfig = BubbleWaveConfig.new(6)
	assert_eq(config.get_defined_wave_count(), 25, "Wave config should load 25 authored waves")


func test_phase_two_color_ramp_matches_design() -> void:
	var config: BubbleWaveConfig = BubbleWaveConfig.new(6)
	for wave_number in range(21, 25):
		var wave_data: Dictionary = config.get_wave_data(wave_number)
		assert_eq(int(wave_data["colors"]), 6, "Phase 2 late waves should unlock the 6th color")


func test_milestone_multiplier_is_loaded() -> void:
	var config: BubbleWaveConfig = BubbleWaveConfig.new(6)
	var wave_ten: Dictionary = config.get_wave_data(10)
	var wave_twenty: Dictionary = config.get_wave_data(20)
	assert_eq(float(wave_ten["score_multiplier"]), 2.0, "Wave 10 multiplier should be loaded from data")
	assert_eq(float(wave_twenty["score_multiplier"]), 2.0, "Wave 20 multiplier should be loaded from data")
