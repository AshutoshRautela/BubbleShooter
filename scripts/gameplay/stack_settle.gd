extends RefCounted

const EMPTY := -1


static func deepest_occupied_row(grid: Array[Array], column_count: int) -> int:
	for row in range(grid.size() - 1, -1, -1):
		for col in range(column_count):
			if int(grid[row][col]) != EMPTY:
				return row
	return -1


## Extra downward shift to apply to board_top (grid ceiling anchor) after pops — not a second visual layer.
static func compute_anchor_slide_delta(
	board_top: float,
	bubble_radius: float,
	row_height: float,
	lose_line_y: float,
	column_count: int,
	grid: Array[Array]
) -> float:
	if grid.is_empty():
		return 0.0
	var deepest_row: int = deepest_occupied_row(grid, column_count)
	if deepest_row < 0:
		return 0.0
	var natural_bottom: float = board_top + bubble_radius + float(deepest_row) * row_height + bubble_radius
	var available_slack: float = lose_line_y - row_height * 3.0 - natural_bottom
	return maxf(0.0, available_slack * 0.22)
