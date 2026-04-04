extends RefCounted


static func make_board(column_count: int = 9, palette_size: int = 6) -> BubbleBoardState:
	var config: BubbleWaveConfig = BubbleWaveConfig.new(palette_size)
	return BubbleBoardState.new(column_count, palette_size, config)


static func set_grid(board: BubbleBoardState, rows: Array[Array], parity_offset: int = 0) -> void:
	board.grid.clear()
	for source_row in rows:
		var row_copy: Array[int] = []
		for value in source_row:
			row_copy.append(int(value))
		board.grid.append(row_copy)
	board.row_parity_offset = parity_offset


static func cells_from_bursts(bursts: Array[Dictionary]) -> Array[String]:
	var cells: Array[String] = []
	for burst in bursts:
		var cell: Vector2i = burst["cell"]
		cells.append("%d,%d" % [cell.x, cell.y])
	return cells


static func occupied_cells(board: BubbleBoardState) -> Array[String]:
	var cells: Array[String] = []
	for row in range(board.grid.size()):
		for col in range(board.column_count):
			if board.grid[row][col] == BubbleBoardState.EMPTY_CELL:
				continue
			cells.append("%d,%d" % [row, col])
	return cells


static func make_shot_planner(board: BubbleBoardState, layout_overrides: Dictionary = {}) -> BubbleShotPlanner:
	var planner: BubbleShotPlanner = BubbleShotPlanner.new()
	var gl: BubbleGridLayout = BubbleGridLayout.new()
	var bubble_radius: float = float(layout_overrides.get("bubble_radius", 20.0))
	gl.bubble_radius = bubble_radius
	gl.bubble_diameter = bubble_radius * 2.0
	gl.board_left = float(layout_overrides.get("board_left", 100.0))
	gl.board_right = float(layout_overrides.get("board_right", gl.board_left + gl.bubble_diameter * float(board.column_count) + bubble_radius))
	gl.board_top = float(layout_overrides.get("board_top", 120.0))
	gl.row_height = float(layout_overrides.get("row_height", bubble_radius * 1.72))
	gl.max_rows_visible = int(layout_overrides.get("max_rows_visible", 12))
	gl.cannon_position = layout_overrides.get("cannon_position", Vector2(290.0, 620.0))
	gl.stack_visual_offset = float(layout_overrides.get("stack_visual_offset", 0.0))
	planner.sync_layout(board, gl)
	return planner
