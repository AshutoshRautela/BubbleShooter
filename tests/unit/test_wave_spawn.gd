extends BubbleTestCase

const Helpers = preload("res://tests/helpers/test_helpers.gd")

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 424242


func test_wave_1_spawn_has_large_same_color_clusters() -> void:
	var board = Helpers.make_board(9, 6)
	board.wave = 1
	board._spawn_wave(rng)
	assert_true(
		_largest_cluster_size(board) >= 4,
		"Wave 1 should open with readable same-color pockets instead of fully noisy randomness"
	)


func test_wave_5_checkerboard_uses_two_colors_and_multiple_pop_blocks() -> void:
	var board = Helpers.make_board(9, 6)
	board.wave = 5
	board._spawn_wave(rng)
	assert_eq(board.available_grid_colors().size(), 2, "Wave 5 checker-block board should intentionally use two dominant colors")
	assert_true(
		_largest_cluster_size(board) >= 4,
		"Wave 5 should still contain satisfying pop-ready blocks, not single isolated checker dots"
	)


func test_wave_10_pyramid_centers_the_mass() -> void:
	var board = Helpers.make_board(9, 6)
	board.wave = 10
	board._spawn_wave(rng)
	var center_columns: int = 0
	var edge_columns: int = 0
	for row in range(board.grid.size()):
		for col in range(board.column_count):
			if board.grid[row][col] == BubbleBoardState.EMPTY_CELL:
				continue
			if col >= 2 and col <= 6:
				center_columns += 1
			else:
				edge_columns += 1
	assert_true(
		center_columns > edge_columns,
		"Wave 10 pyramid should keep more bubbles in the middle than on the outer edges"
	)


func test_large_wave_rows_are_split_into_active_chunk_and_reserve() -> void:
	var board = Helpers.make_board(9, 6)
	board.wave = 1
	board._spawn_wave(rng)
	assert_eq(board.grid.size(), board.current_wave_visible_rows(), "Only the visible chunk should stay active on the board")
	assert_true(board.reserve_rows.size() > 0, "Large waves should keep additional rows in reserve instead of making them hittable off-screen")


func _largest_cluster_size(board) -> int:
	var seen: Dictionary = {}
	var best: int = 0
	for row in range(board.grid.size()):
		for col in range(board.column_count):
			var cell: Vector2i = Vector2i(row, col)
			if board.grid[row][col] == BubbleBoardState.EMPTY_CELL or seen.has(cell):
				continue
			var cluster: Array[Vector2i] = board.collect_cluster(cell, int(board.grid[row][col]))
			for member in cluster:
				seen[member] = true
			best = maxi(best, cluster.size())
	return best
