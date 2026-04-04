extends BubbleTestCase


func test_floating_bursts_wait_while_cluster_is_pending() -> void:
	var pending: Array[Dictionary] = [
		{"burst_kind": "cluster", "delay": 0.0},
		{"burst_kind": "floating", "delay": 0.0},
	]
	var active: Array[Dictionary] = []
	assert_false(
		BubbleBurstSequenceGuard.can_activate_floating_burst(pending, active),
		"Floating bursts must not activate while any cluster burst is still pending"
	)


func test_floating_bursts_wait_while_cluster_animation_is_active() -> void:
	var pending: Array[Dictionary] = [
		{"burst_kind": "floating", "delay": 0.0},
	]
	var active: Array[Dictionary] = [
		{"burst_kind": "cluster", "age": 0.12},
	]
	assert_false(
		BubbleBurstSequenceGuard.can_activate_floating_burst(pending, active),
		"Floating bursts must not activate while cluster burst animations are still active"
	)


func test_floating_phase_starts_after_cluster_animation_window() -> void:
	var delay: float = BubbleBurstSequenceGuard.floating_start_delay(5, 0.042, 0.28, 0.07)
	assert_true(
		delay > 0.28,
		"Floating burst phase should begin after the final cluster bubble has had time to finish animating"
	)


func test_floating_bursts_can_start_once_cluster_phase_is_fully_done() -> void:
	var pending: Array[Dictionary] = [
		{"burst_kind": "floating", "delay": 0.0},
	]
	var active: Array[Dictionary] = [
		{"burst_kind": "floating", "age": 0.04},
	]
	assert_true(
		BubbleBurstSequenceGuard.can_activate_floating_burst(pending, active),
		"Floating bursts may continue once no cluster bursts remain pending or active"
	)


func test_deferred_floating_phase_waits_until_cluster_phase_is_gone() -> void:
	var deferred: Array[Dictionary] = [
		{"burst_kind": "floating", "delay": 0.0},
	]
	var pending: Array[Dictionary] = [
		{"burst_kind": "cluster", "delay": 0.0},
	]
	var active: Array[Dictionary] = []
	assert_false(
		BubbleBurstSequenceGuard.should_start_floating_phase(deferred, pending, active),
		"Detached floating phase must not start while cluster bubbles still exist in the active sequence"
	)


func test_deferred_floating_phase_starts_after_cluster_phase_finishes() -> void:
	var deferred: Array[Dictionary] = [
		{"burst_kind": "floating", "delay": 0.0},
	]
	var pending: Array[Dictionary] = []
	var active: Array[Dictionary] = []
	assert_true(
		BubbleBurstSequenceGuard.should_start_floating_phase(deferred, pending, active),
		"Detached floating phase should begin only after the cluster phase has fully finished"
	)


func test_visible_preview_bursts_keep_deferred_floating_bubbles_visible_without_merging_phases() -> void:
	var pending: Array[Dictionary] = [
		{"burst_kind": "cluster", "center": Vector2(10.0, 20.0)},
	]
	var deferred: Array[Dictionary] = [
		{"burst_kind": "floating", "center": Vector2(30.0, 40.0)},
	]
	var preview: Array[Dictionary] = BubbleBurstSequenceGuard.visible_preview_bursts(pending, deferred)
	assert_eq(preview.size(), 2, "Preview should include both active cluster bubbles and deferred floating bubbles")
	assert_eq(String(preview[0]["burst_kind"]), "cluster", "Cluster entries should stay first in the preview list")
	assert_false(bool(preview[0].get("preview_only", false)), "Active cluster entries should not be marked as preview-only")
	assert_eq(String(preview[1]["burst_kind"]), "floating", "Deferred floating entries should remain floating in preview")
	assert_true(bool(preview[1].get("preview_only", false)), "Deferred floating entries should be marked preview-only so they are not treated as active cluster bursts")
