extends BubbleTestCase

const Helpers = preload("res://tests/helpers/test_helpers.gd")
const BubbleGame = preload("res://scripts/gameplay/game.gd")

var _game: BubbleGame


func before_each() -> void:
	_game = BubbleGame.new()
	_game.board = Helpers.make_board(5, 6)
	_game.bubble_radius = 20.0
	_game.mobile_low_fx = true


func after_each() -> void:
	if _game != null:
		_game.free()
		_game = null


func test_resolution_phase_builder_filters_duplicate_cells_from_floating_phase() -> void:
	var shared_cell: Vector2i = Vector2i(1, 1)
	var resolution: Dictionary = {
		"cluster_bursts": [
			{"cell": shared_cell, "color": 0},
		],
		"floating_bursts": [
			{"cell": shared_cell, "color": 2},
			{"cell": Vector2i(2, 2), "color": 3},
		],
		"burst_row_parity_offset": 0,
	}
	var phases: Dictionary = _game.build_resolution_burst_phases(resolution, shared_cell, Vector2.ZERO)
	var cluster: Array[Dictionary] = phases["cluster"]
	var floating: Array[Dictionary] = phases["floating"]
	assert_eq(cluster.size(), 1, "Cluster phase should preserve the original matched cell")
	assert_eq(floating.size(), 1, "Floating phase should drop any cell that already belongs to the cluster phase")
	assert_eq(floating[0]["cell"], Vector2i(2, 2), "Only the genuinely detached floating cell should remain")


func test_preview_builder_deduplicates_same_cell_between_pending_and_deferred_lists() -> void:
	var pending: Array[Dictionary] = [
		{"burst_kind": "cluster", "cell": Vector2i(1, 1), "center": Vector2(10.0, 20.0)},
	]
	var deferred: Array[Dictionary] = [
		{"burst_kind": "floating", "cell": Vector2i(1, 1), "center": Vector2(10.0, 20.0)},
		{"burst_kind": "floating", "cell": Vector2i(2, 3), "center": Vector2(30.0, 40.0)},
	]
	var preview: Array[Dictionary] = BubbleBurstSequenceGuard.visible_preview_bursts(pending, deferred)
	assert_eq(preview.size(), 2, "Preview list should not duplicate a cell that already exists in the active pending phase")
	assert_eq(preview[0]["cell"], Vector2i(1, 1), "Pending cluster cell should stay visible")
	assert_eq(preview[1]["cell"], Vector2i(2, 3), "Only unique deferred floating cells should be added to the preview")
	assert_true(bool(preview[1].get("preview_only", false)), "Deferred-only preview entries should stay marked as preview-only")
