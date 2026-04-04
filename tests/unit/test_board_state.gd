extends BubbleTestCase

const Helpers = preload("res://tests/helpers/test_helpers.gd")

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 1337


func test_top_row_bubbles_are_never_floating() -> void:
	var board = Helpers.make_board(5, 6)
	Helpers.set_grid(board, [
		[0, BubbleBoardState.EMPTY_CELL, 1, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	])

	var removed: Array[Dictionary] = board.remove_floating_bubbles()
	assert_eq(removed.size(), 0, "Top-row bubbles should remain attached")
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,0", "0,2"],
		"Top-row bubbles should still exist after floating check"
	)


func test_remove_floating_preserves_mixed_color_attached_cluster() -> void:
	var board = Helpers.make_board(5, 6)
	Helpers.set_grid(board, [
		[0, 3, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[1, 2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 4, 5],
	])

	var removed: Array[Dictionary] = board.remove_floating_bubbles()
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(removed),
		["2,3", "2,4"],
		"Only the detached island should fall"
	)
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,0", "0,1", "1,0", "1,1"],
		"Attached mixed-color support path should stay on the board"
	)


func test_zigzag_support_path_counts_as_attached() -> void:
	var board = Helpers.make_board(6, 6)
	Helpers.set_grid(board, [
		[BubbleBoardState.EMPTY_CELL, 0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, 1, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 3, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 5],
	])

	var removed: Array[Dictionary] = board.remove_floating_bubbles()
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(removed),
		["3,5"],
		"Only the truly detached tail bubble should be removed"
	)
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,1", "1,1", "2,2", "3,2"],
		"Zig-zag support path should remain attached through hex parity rules"
	)


func test_odd_parity_support_path_stays_attached() -> void:
	var board = Helpers.make_board(5, 6)
	Helpers.set_grid(board, [
		[BubbleBoardState.EMPTY_CELL, 0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, 1, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, 2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 4],
	], 1)

	var removed: Array[Dictionary] = board.remove_floating_bubbles()
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(removed),
		["3,4"],
		"Odd parity support chain should preserve attached bubbles and drop only detached tail cells"
	)
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,1", "1,1", "2,1"],
		"Odd parity traversal should keep the vertical support chain attached"
	)


func test_resolve_keeps_nonmatching_top_attached_bubbles() -> void:
	var board = Helpers.make_board(4, 6)
	Helpers.set_grid(board, [
		[0, 2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	])

	var result: Dictionary = board.resolve_placed_bubble(Vector2i(1, 1), 0, rng)
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(result["cluster_bursts"]),
		["0,0", "1,0", "1,1"],
		"Only the same-color matched cluster should pop"
	)
	assert_eq(result["floating_bursts"].size(), 0, "Attached top-row nonmatching bubble should not fall")
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,1"],
		"Nonmatching top-attached bubble should remain after resolution"
	)


func test_resolve_keeps_same_color_bubble_when_it_is_not_connected_to_the_popped_cluster() -> void:
	var board = Helpers.make_board(5, 6)
	Helpers.set_grid(board, [
		[0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0, 0],
	])

	var result: Dictionary = board.resolve_placed_bubble(Vector2i(0, 4), 0, rng)
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(result["cluster_bursts"]),
		["0,3", "0,4", "1,3", "1,4"],
		"Only the connected same-color cluster should pop"
	)
	assert_eq(result["floating_bursts"].size(), 0, "The isolated top-left same-color bubble should not be treated as floating")
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,0"],
		"An isolated same-color bubble must remain if it is not actually connected to the popped cluster"
	)


func test_left_wall_same_color_bubble_with_mixed_support_does_not_pop_with_distant_cluster() -> void:
	var board = Helpers.make_board(5, 6)
	Helpers.set_grid(board, [
		[2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[0, 2, BubbleBoardState.EMPTY_CELL, 0, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0, 0],
	])

	var result: Dictionary = board.resolve_placed_bubble(Vector2i(1, 4), 0, rng)
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(result["cluster_bursts"]),
		["1,3", "1,4", "2,3", "2,4"],
		"Only the right-side connected cluster should pop"
	)
	assert_eq(result["floating_bursts"].size(), 0, "The left-wall bubble is still attached through a mixed-color support path and must not fall")
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,0", "1,0", "1,1"],
		"The left-wall bubble should remain after a distant same-color cluster bursts"
	)


func test_milestone_multiplier_applies_to_board_clear_bonus() -> void:
	var board = Helpers.make_board(4, 6)
	board.wave = 10
	Helpers.set_grid(board, [
		[0, 0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	])

	var result: Dictionary = board.resolve_placed_bubble(Vector2i(0, 2), 0, rng)
	assert_true(bool(result["board_cleared"]), "Resolving the final cluster should clear the board")
	assert_eq(board.score, 360, "Wave 10 clear should apply the 2x board-clear multiplier")


func test_baseline_refill_after_chain_reaction() -> void:
	var board = Helpers.make_board(4, 6)
	board.wave = 1
	board.playfield_visible_row_target = 4
	Helpers.set_grid(board, [
		[0, 0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	])
	board.reserve_rows.clear()
	for source_row in [
		[1, 1, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[2, 2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	]:
		var row_copy: Array[int] = []
		for value in source_row:
			row_copy.append(int(value))
		board.reserve_rows.append(row_copy)

	var result: Dictionary = board.resolve_placed_bubble(Vector2i(0, 2), 0, rng)
	assert_false(bool(result["board_cleared"]), "Wave not cleared while reserve rows remain")
	assert_eq(board.reserve_rows.size(), 2, "Reserve must stay untouched until followup")

	board.apply_resolution_followup(result, rng)
	assert_true(board.grid.size() > 0, "Baseline refill should fill grid from reserve after chain cleared it")
	assert_eq(board.reserve_rows.size(), 0, "Both reserve rows consumed to reach baseline")


func test_shift_counter_pushes_extra_row() -> void:
	var board = Helpers.make_board(9, 6)
	board.wave = 1
	board.playfield_visible_row_target = 12
	board.shots_until_shift = 1
	var initial_rows: int = 6
	var rows: Array[Array] = []
	for _r in range(initial_rows):
		var row: Array[int] = []
		for _c in range(9):
			row.append(0)
		rows.append(row)
	Helpers.set_grid(board, rows)
	board.reserve_rows.clear()
	var reserve_row: Array[int] = []
	for _c in range(9):
		reserve_row.append(1)
	board.reserve_rows.append(reserve_row.duplicate())

	var grid_before: int = board.grid.size()
	var shifted: int = board.try_push_shift_row()
	assert_eq(shifted, 1, "Counter at 1 should fire and push 1 row")
	assert_eq(board.grid.size(), grid_before + 1, "Grid should grow by 1 after shift")
	assert_eq(board.reserve_rows.size(), 0, "Reserve row consumed")
	assert_eq(board.shots_until_shift, board.shots_per_shift, "Counter should reset after firing")


func test_shift_counter_does_not_fire_early() -> void:
	var board = Helpers.make_board(9, 6)
	board.wave = 1
	board.shots_until_shift = 3
	var rows: Array[Array] = []
	for _r in range(4):
		var row: Array[int] = []
		for _c in range(9):
			row.append(0)
		rows.append(row)
	Helpers.set_grid(board, rows)
	board.reserve_rows.clear()
	var reserve_row: Array[int] = []
	for _c in range(9):
		reserve_row.append(1)
	board.reserve_rows.append(reserve_row.duplicate())

	var grid_before: int = board.grid.size()
	var shifted: int = board.try_push_shift_row()
	assert_eq(shifted, 0, "Counter at 3 should not fire yet")
	assert_eq(board.grid.size(), grid_before, "Grid should not change when counter > 1")
	assert_eq(board.reserve_rows.size(), 1, "Reserve should stay untouched")


func test_yellow_bridge_pops_detached_blues_should_fall() -> void:
	# Regression: cluster popped beside a color bridge; any island not connected to row 0 must drop.
	var board = Helpers.make_board(9, 6)
	Helpers.set_grid(board, [
		[0, 0, 0, 0, 0, 0, 0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 1, 1, 1],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0, BubbleBoardState.EMPTY_CELL],
	])
	var result: Dictionary = board.resolve_placed_bubble(Vector2i(1, 7), 1, rng)
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(result["cluster_bursts"]),
		["1,6", "1,7", "1,8"],
		"Yellow bridge cluster should be three adjacent cells on row 1"
	)
	assert_array_eq_unordered(
		Helpers.cells_from_bursts(result["floating_bursts"]),
		["2,8", "3,7"],
		"Blues hanging only off the bridge must be removed as floating"
	)
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,0", "0,1", "0,2", "0,3", "0,4", "0,5", "0,6"],
		"Only top-row ceiling blues should remain"
	)


func test_yellow_bridge_pops_detached_blues_odd_parity() -> void:
	var board = Helpers.make_board(9, 6)
	Helpers.set_grid(board, [
		[0, 0, 0, 0, 0, 0, 0, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 1, 1, 1],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0, BubbleBoardState.EMPTY_CELL],
	], 1)
	var result: Dictionary = board.resolve_placed_bubble(Vector2i(1, 7), 1, rng)
	assert_eq(result["floating_bursts"].size(), 2, "Odd row_parity_offset must still detect floating island")
	assert_array_eq_unordered(
		Helpers.occupied_cells(board),
		["0,0", "0,1", "0,2", "0,3", "0,4", "0,5", "0,6"],
		"Only top-row ceiling blues should remain under odd parity"
	)


func test_wave_preview_rows_keep_upper_reserve_before_visible_chunk() -> void:
	var board = Helpers.make_board(4, 6)
	Helpers.set_grid(board, [
		[7, 7, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	])
	board.reserve_rows.clear()
	for source_row in [
		[1, 1, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
		[2, 2, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL],
	]:
		var row_copy: Array[int] = []
		for value in source_row:
			row_copy.append(int(value))
		board.reserve_rows.append(row_copy)

	var preview_rows: Array[Array] = board.wave_preview_rows()
	assert_eq(int(preview_rows[0][0]), 7, "Preview is top-to-bottom: active grid (ceiling chunk) first")
	assert_eq(int(preview_rows[1][0]), 1, "Then reserve rows in wave order toward the cannon")
	assert_eq(int(preview_rows[2][0]), 2, "Reserve order preserved")


func test_compact_grid_trims_leading_empty_rows_and_parity() -> void:
	var board = Helpers.make_board(5, 6)
	var empty: int = BubbleBoardState.EMPTY_CELL
	Helpers.set_grid(board, [
		[empty, empty, empty, empty, empty],
		[empty, empty, empty, empty, empty],
		[0, 0, 0, 0, 0],
	], 1)
	board.compact_grid()
	assert_eq(board.grid.size(), 1, "Leading empty rows should be removed")
	assert_eq(board.row_parity_offset, 1, "Removing two rows should toggle parity twice from starting 1")
	for col in range(5):
		assert_eq(int(board.grid[0][col]), 0, "Expected compact row to preserve cell at col %d" % col)


func test_compact_grid_trailing_empty_does_not_flip_parity() -> void:
	var board = Helpers.make_board(5, 6)
	var empty: int = BubbleBoardState.EMPTY_CELL
	Helpers.set_grid(board, [
		[0, 0, 0, 0, 0],
		[empty, empty, empty, empty, empty],
	], 0)
	board.compact_grid()
	assert_eq(board.grid.size(), 1, "Only trailing empty row removed")
	assert_eq(board.row_parity_offset, 0, "No bubble moved down a row index")


func test_compact_grid_squeezes_middle_gap_and_flips_parity() -> void:
	var board = Helpers.make_board(5, 6)
	var empty: int = BubbleBoardState.EMPTY_CELL
	Helpers.set_grid(board, [
		[0, 0, 0, 0, 0],
		[empty, empty, empty, empty, empty],
		[1, 1, 1, 1, 1],
	], 0)
	board.compact_grid()
	assert_eq(board.grid.size(), 2, "Middle air row removed")
	assert_eq(board.row_parity_offset, 1, "Rows below gap shift up by one")
