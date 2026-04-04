extends BubbleTestCase

const _S := preload("res://scripts/gameplay/stack_settle.gd")


func test_empty_grid_delta_is_zero() -> void:
	assert_eq(
		_S.compute_anchor_slide_delta(100.0, 32.0, 56.0, 800.0, 9, []),
		0.0,
		"empty grid"
	)


func test_all_empty_cells_delta_is_zero() -> void:
	var grid: Array[Array] = [[-1, -1, -1], [-1, -1, -1]]
	assert_eq(
		_S.compute_anchor_slide_delta(100.0, 32.0, 56.0, 800.0, 3, grid),
		0.0,
		"all empty"
	)


func test_deepest_occupied_row() -> void:
	var grid: Array[Array] = [
		[-1, -1, -1],
		[0, -1, 0],
		[-1, -1, -1],
	]
	assert_eq(_S.deepest_occupied_row(grid, 3), 1, "middle row")


func test_slack_produces_positive_delta() -> void:
	var br: float = 32.0
	var rh: float = 56.0
	var bt: float = 100.0
	var lose_y: float = 900.0
	var row0: Array = []
	for _i in range(9):
		row0.append(0)
	var grid: Array[Array] = [row0]
	var d: float = _S.compute_anchor_slide_delta(bt, br, rh, lose_y, 9, grid)
	assert_true(d > 10.0, "slack should yield downward slide delta")


func test_tight_pack_delta_near_zero() -> void:
	var br: float = 32.0
	var rh: float = 56.0
	var bt: float = 100.0
	var row0: Array = []
	for _i in range(9):
		row0.append(0)
	var grid: Array[Array] = []
	for _r in range(14):
		grid.append(row0.duplicate())
	var deepest: float = bt + br + float(13) * rh + br
	var lose_y: float = deepest + rh * 3.0 + 2.0
	var d: float = _S.compute_anchor_slide_delta(bt, br, rh, lose_y, 9, grid)
	assert_true(d < 1.0, "no slack means no slide")
