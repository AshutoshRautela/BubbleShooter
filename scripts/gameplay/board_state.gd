class_name BubbleBoardState
extends RefCounted

const EMPTY_CELL := -1

var column_count: int
var wave_config: BubbleWaveConfig
var shots_per_shift: int
var max_palette_size: int

var grid: Array[Array] = []
var reserve_rows: Array[Array] = []
var row_parity_offset: int = 0
var score: int = 0
var wave: int = 1
var shots_until_shift: int
var status_message: String = ""

# When set, floating detection uses bubble-center distances so it matches on-screen layout
# (viewport / hex spacing). Purely combinatorial neighbors can disagree after resize.
var _float_adj_board_left: float = 0.0
var _float_adj_board_top: float = 0.0
var _float_adj_bubble_radius: float = 32.0
var _float_adj_bubble_diameter: float = 64.0
var _float_adj_row_height: float = 56.0
var _float_adjacency_ready: bool = false


func _init(columns: int, palette_size: int, config: BubbleWaveConfig) -> void:
	column_count = columns
	max_palette_size = palette_size
	wave_config = config
	_sync_wave_settings()
	shots_until_shift = shots_per_shift


func start_new_game(rng: RandomNumberGenerator) -> void:
	score = 0
	wave = 1
	_sync_wave_settings()
	shots_until_shift = shots_per_shift
	status_message = ""
	_spawn_wave(rng)


func resolve_placed_bubble(snap: Vector2i, bubble_color: int, rng: RandomNumberGenerator) -> Dictionary:
	ensure_row(snap.x)
	grid[snap.x][snap.y] = bubble_color

	var pop_result: Dictionary = pop_cluster_from(snap)
	var total_removed: int = pop_result["total_removed"]
	var board_cleared: bool = false
	var row_pushed: bool = false
	var chunk_advanced: bool = false
	var chunk_rows_promoted: int = 0
	var burst_row_parity_offset: int = row_parity_offset

	compact_grid()
	chunk_advanced = grid.is_empty() and not reserve_rows.is_empty()
	if chunk_advanced:
		chunk_rows_promoted = mini(current_wave_visible_rows(), reserve_rows.size())

	if total_removed == 0:
		score += 5

	if count_total_wave_bubbles() == 0:
		score += int(round(150.0 * current_wave_score_multiplier()))
		wave += 1
		_sync_wave_settings()
		shots_until_shift = shots_per_shift
		status_message = "Board cleared. Wave %d begins." % wave
		board_cleared = true
	else:
		shots_until_shift -= 1
		if total_removed == 0:
			status_message = "No match. New row in %d shots." % [maxi(shots_until_shift, 0)]
		if shots_until_shift <= 0:
			_sync_wave_settings()
			shots_until_shift = shots_per_shift
			row_pushed = true

	return {
		"cluster_bursts": pop_result["cluster_bursts"],
		"floating_bursts": pop_result["floating_bursts"],
		"total_removed": total_removed,
		"board_cleared": board_cleared,
		"chunk_advanced": chunk_advanced,
		"chunk_rows_promoted": chunk_rows_promoted,
		"row_pushed": row_pushed,
		"burst_row_parity_offset": burst_row_parity_offset,
	}


func apply_resolution_followup(result: Dictionary, rng: RandomNumberGenerator) -> void:
	if result["board_cleared"]:
		_spawn_wave(rng)
		return

	if result.get("chunk_advanced", false):
		_promote_next_wave_chunk()

	if result["row_pushed"]:
		push_row_from_ceiling(rng)


func export_state() -> Dictionary:
	return {
		"grid": grid.duplicate(true),
		"reserve_rows": reserve_rows.duplicate(true),
		"row_parity_offset": row_parity_offset,
		"score": score,
		"wave": wave,
		"shots_until_shift": shots_until_shift,
		"status_message": status_message,
	}


func import_state(data: Dictionary) -> void:
	grid.clear()
	for source_row in Array(data.get("grid", [])):
		var row_copy: Array[int] = []
		for value in Array(source_row):
			row_copy.append(int(value))
		grid.append(row_copy)
	reserve_rows.clear()
	for source_row in Array(data.get("reserve_rows", [])):
		var reserve_copy: Array[int] = []
		for value in Array(source_row):
			reserve_copy.append(int(value))
		reserve_rows.append(reserve_copy)
	row_parity_offset = int(data.get("row_parity_offset", 0))
	score = int(data.get("score", 0))
	wave = maxi(int(data.get("wave", 1)), 1)
	_sync_wave_settings()
	shots_until_shift = maxi(int(data.get("shots_until_shift", shots_per_shift)), 1)
	status_message = String(data.get("status_message", ""))


func current_palette_size() -> int:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		return mini(max_palette_size, 4)
	return clampi(int(wave_data["colors"]), 1, max_palette_size)


func current_wave_data() -> Dictionary:
	if wave_config == null:
		return {}
	return wave_config.get_wave_data(wave)


func current_wave_start_rows() -> int:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		return 6
	return maxi(int(wave_data["start_rows"]), 1)


func current_wave_visible_rows() -> int:
	var total_rows: int = current_wave_start_rows()
	return clampi(int(round(float(total_rows) / 5.0)), 6, 8)


func current_wave_board_density() -> float:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		return 0.82
	return clampf(float(wave_data["board_density"]), 0.0, 1.0)


func current_wave_push_density() -> float:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		return 0.9
	return clampf(float(wave_data["push_density"]), 0.0, 1.0)


func current_wave_score_multiplier() -> float:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		return 1.0
	return maxf(float(wave_data["score_multiplier"]), 1.0)


func current_wave_board_type() -> String:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		return "random"
	return String(wave_data.get("board_type", "random"))


func pick_shoot_color(rng: RandomNumberGenerator) -> int:
	var options: Array[int] = available_grid_colors()
	if options.is_empty():
		for color_index in range(current_palette_size()):
			options.append(color_index)
	return options[rng.randi_range(0, options.size() - 1)]


func available_grid_colors() -> Array[int]:
	var found: Dictionary = {}
	for row in range(grid.size()):
		for col in range(column_count):
			var bubble_color: int = grid[row][col]
			if bubble_color != EMPTY_CELL:
				found[bubble_color] = true

	var options: Array[int] = []
	for key in found.keys():
		options.append(int(key))
	options.sort()

	if options.is_empty():
		for color_index in range(current_palette_size()):
			options.append(color_index)

	return options


func wave_preview_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for source_row in reserve_rows:
		rows.append(source_row.duplicate())
	for source_row in grid:
		rows.append(source_row.duplicate())
	return rows


func row_shift_parity(row: int) -> int:
	return (row + row_parity_offset) % 2


## Call from gameplay with the same layout used for drawing / shot planner (e.g. after resize).
func sync_float_adjacency(board_left: float, board_top: float, bubble_radius: float, bubble_diameter: float, row_height: float) -> void:
	_float_adj_board_left = board_left
	_float_adj_board_top = board_top
	_float_adj_bubble_radius = maxf(bubble_radius, 0.001)
	_float_adj_bubble_diameter = maxf(bubble_diameter, 0.001)
	_float_adj_row_height = maxf(row_height, 0.001)
	_float_adjacency_ready = true


func _float_world_center(row: int, col: int) -> Vector2:
	var shift: float = float(row_shift_parity(row)) * _float_adj_bubble_radius
	return Vector2(
		_float_adj_board_left + _float_adj_bubble_radius + float(col) * _float_adj_bubble_diameter + shift,
		_float_adj_board_top + _float_adj_bubble_radius + float(row) * _float_adj_row_height
	)


func _build_float_support_graph(occupied: Array[Vector2i]) -> Dictionary:
	var adjacency: Dictionary = {}
	for cell in occupied:
		adjacency[cell] = []

	if _float_adjacency_ready:
		var limit: float = _float_adj_bubble_diameter * 1.02
		for index_a in range(occupied.size()):
			var a: Vector2i = occupied[index_a]
			var position_a: Vector2 = _float_world_center(a.x, a.y)
			for index_b in range(index_a + 1, occupied.size()):
				var b: Vector2i = occupied[index_b]
				if position_a.distance_to(_float_world_center(b.x, b.y)) <= limit:
					adjacency[a].append(b)
					adjacency[b].append(a)
	else:
		for cell in occupied:
			for neighbor in get_neighbors(cell.x, cell.y):
				if not cell_occupied(neighbor.x, neighbor.y):
					continue
				adjacency[cell].append(neighbor)

	return adjacency


func get_neighbors(row: int, col: int) -> Array[Vector2i]:
	var deltas: Array[Vector2i] = []
	if row_shift_parity(row) == 0:
		deltas = [
			Vector2i(0, -1),
			Vector2i(0, 1),
			Vector2i(-1, -1),
			Vector2i(-1, 0),
			Vector2i(1, -1),
			Vector2i(1, 0),
		]
	else:
		deltas = [
			Vector2i(0, -1),
			Vector2i(0, 1),
			Vector2i(-1, 0),
			Vector2i(-1, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
		]

	var neighbors: Array[Vector2i] = []
	for delta in deltas:
		var next_row: int = row + delta.x
		var next_col: int = col + delta.y
		if next_col < 0 or next_col >= column_count or next_row < 0:
			continue
		neighbors.append(Vector2i(next_row, next_col))

	return neighbors


func ensure_row(row: int) -> void:
	while grid.size() <= row:
		grid.append(make_empty_row())


func compact_grid() -> void:
	while not grid.is_empty():
		var keep_row: bool = false
		var last_row: Array = grid[grid.size() - 1]
		for col in range(column_count):
			if int(last_row[col]) != EMPTY_CELL:
				keep_row = true
				break
		if keep_row:
			break
		grid.remove_at(grid.size() - 1)


func make_empty_row() -> Array[int]:
	var row: Array[int] = []
	for _col in range(column_count):
		row.append(EMPTY_CELL)
	return row


func cell_occupied(row: int, col: int) -> bool:
	return row >= 0 and row < grid.size() and col >= 0 and col < column_count and grid[row][col] != EMPTY_CELL


func count_bubbles() -> int:
	var count: int = 0
	for row in range(grid.size()):
		for col in range(column_count):
			if grid[row][col] != EMPTY_CELL:
				count += 1
	return count


func count_total_wave_bubbles() -> int:
	var count: int = count_bubbles()
	for row in reserve_rows:
		for col in range(column_count):
			if int(row[col]) != EMPTY_CELL:
				count += 1
	return count


func _spawn_wave(rng: RandomNumberGenerator) -> void:
	grid.clear()
	reserve_rows.clear()
	row_parity_offset = 0
	var palette_size: int = current_palette_size()
	var start_rows: int = current_wave_start_rows()
	var board_density: float = current_wave_board_density()
	if not _spawn_pattern_wave(rng, palette_size, start_rows, board_density):
		_spawn_clustered_random_wave(rng, palette_size, start_rows, board_density)
	_split_visible_chunk()
	if wave == 1:
		status_message = "Aim with mouse or touch. Match 3 or more bubbles."
	else:
		status_message = "Wave %d ready. Match 3 or more bubbles." % wave


func _spawn_pattern_wave(rng: RandomNumberGenerator, palette_size: int, start_rows: int, board_density: float) -> bool:
	match wave:
		1:
			_spawn_tutorial_wave(rng, palette_size, start_rows, board_density)
			return true
		5:
			_spawn_checker_blocks_wave(rng, palette_size, start_rows, board_density)
			return true
		10:
			_spawn_pyramid_wave(rng, palette_size, start_rows, board_density)
			return true
		15, 20:
			_spawn_stripe_wave(rng, palette_size, start_rows, board_density)
			return true

	var board_type: String = current_wave_board_type()
	if board_type == "tutorial":
		_spawn_tutorial_wave(rng, palette_size, start_rows, board_density)
		return true
	return false


func _spawn_clustered_random_wave(rng: RandomNumberGenerator, palette_size: int, start_rows: int, board_density: float) -> void:
	var progress: float = clampf(float(wave - 1) / 24.0, 0.0, 1.0)
	var cluster_bias: float = lerpf(0.82, 0.34, progress)
	for row in range(start_rows):
		var cells: Array[int] = []
		for col in range(column_count):
			if rng.randf() > _row_density(board_density, row, start_rows):
				cells.append(EMPTY_CELL)
				continue
			cells.append(_choose_clustered_color(rng, cells, row, col, palette_size, cluster_bias))
		grid.append(cells)


func _spawn_tutorial_wave(rng: RandomNumberGenerator, palette_size: int, start_rows: int, board_density: float) -> void:
	for row in range(start_rows):
		var cells: Array[int] = []
		var col: int = 0
		while col < column_count:
			var fill_density: float = _row_density(board_density, row, start_rows)
			if rng.randf() > fill_density:
				cells.append(EMPTY_CELL)
				col += 1
				continue
			var segment_color: int = _choose_clustered_color(rng, cells, row, col, palette_size, 0.95)
			var segment_length: int = mini(column_count - col, rng.randi_range(2, 3))
			for _segment_index in range(segment_length):
				cells.append(segment_color)
				col += 1
				if col >= column_count:
					break
				if rng.randf() > fill_density + 0.05:
					break
		grid.append(cells)


func _spawn_checker_blocks_wave(rng: RandomNumberGenerator, palette_size: int, start_rows: int, board_density: float) -> void:
	var pattern_colors: Array[int] = _pick_distinct_palette(rng, palette_size, 2)
	for row in range(start_rows):
		var cells: Array[int] = []
		for col in range(column_count):
			if rng.randf() > _row_density(board_density + 0.04, row, start_rows):
				cells.append(EMPTY_CELL)
				continue
			var color_index: int = (int(row / 2) + int(col / 2)) % pattern_colors.size()
			cells.append(pattern_colors[color_index])
		grid.append(cells)


func _spawn_pyramid_wave(rng: RandomNumberGenerator, palette_size: int, start_rows: int, board_density: float) -> void:
	var band_colors: Array[int] = _pick_distinct_palette(rng, palette_size, mini(3, palette_size))
	var center: float = float(column_count - 1) * 0.5
	for row in range(start_rows):
		var cells: Array[int] = []
		var width_ratio: float = 1.0 - float(row) / maxf(float(start_rows), 1.0)
		var half_span: float = lerpf(1.4, center + 0.4, width_ratio)
		for col in range(column_count):
			var inside: bool = absf(float(col) - center) <= half_span
			if not inside or rng.randf() > _row_density(board_density + 0.06, row, start_rows):
				cells.append(EMPTY_CELL)
				continue
			var band_index: int = mini(int(floor(float(row) / 2.0)), band_colors.size() - 1)
			cells.append(band_colors[band_index])
		grid.append(cells)


func _spawn_stripe_wave(rng: RandomNumberGenerator, palette_size: int, start_rows: int, board_density: float) -> void:
	var stripe_colors: Array[int] = _pick_distinct_palette(rng, palette_size, mini(4, palette_size))
	for row in range(start_rows):
		var cells: Array[int] = []
		var stripe_color: int = stripe_colors[int(row / 2) % stripe_colors.size()]
		for col in range(column_count):
			if rng.randf() > _row_density(board_density + 0.02, row, start_rows):
				cells.append(EMPTY_CELL)
				continue
			cells.append(stripe_color)
		grid.append(cells)


func _choose_clustered_color(rng: RandomNumberGenerator, current_row: Array[int], row: int, col: int, palette_size: int, cluster_bias: float) -> int:
	var preferred: Array[int] = []
	if col > 0 and int(current_row[col - 1]) != EMPTY_CELL:
		preferred.append(int(current_row[col - 1]))
		preferred.append(int(current_row[col - 1]))
	for neighbor in get_neighbors(row, col):
		if neighbor.x > row or (neighbor.x == row and neighbor.y >= col):
			continue
		if not cell_occupied(neighbor.x, neighbor.y):
			continue
		preferred.append(int(grid[neighbor.x][neighbor.y]))
	if not preferred.is_empty() and rng.randf() < cluster_bias:
		return preferred[rng.randi_range(0, preferred.size() - 1)]
	return rng.randi_range(0, palette_size - 1)


func _pick_distinct_palette(rng: RandomNumberGenerator, palette_size: int, count: int) -> Array[int]:
	var options: Array[int] = []
	for color_index in range(palette_size):
		options.append(color_index)
	options.shuffle()
	var picked: Array[int] = []
	for index in range(mini(count, options.size())):
		picked.append(options[index])
	if picked.is_empty():
		picked.append(0)
	return picked


func pop_cluster_from(start: Vector2i) -> Dictionary:
	var bubble_color: int = grid[start.x][start.y]
	var cluster: Array[Vector2i] = collect_cluster(start, bubble_color)
	if cluster.size() < 3:
		return {
			"cluster_bursts": [],
			"floating_bursts": [],
			"total_removed": 0,
		}

	var cluster_bursts: Array[Dictionary] = []
	for cell in cluster:
		cluster_bursts.append({
			"cell": cell,
			"color": bubble_color,
		})
		grid[cell.x][cell.y] = EMPTY_CELL

	var floating_bursts: Array[Dictionary] = remove_floating_bubbles()
	var total_removed: int = cluster.size() + floating_bursts.size()
	score += cluster.size() * 20 + floating_bursts.size() * 25
	status_message = "Popped %d bubbles." % total_removed

	return {
		"cluster_bursts": cluster_bursts,
		"floating_bursts": floating_bursts,
		"total_removed": total_removed,
	}


func _split_visible_chunk() -> void:
	var visible_rows: int = mini(current_wave_visible_rows(), grid.size())
	if visible_rows >= grid.size():
		return
	var all_rows: Array[Array] = grid.duplicate(true)
	grid.clear()
	reserve_rows.clear()
	var visible_start: int = all_rows.size() - visible_rows
	for row_index in range(all_rows.size()):
		if row_index < visible_start:
			reserve_rows.append(all_rows[row_index])
		else:
			grid.append(all_rows[row_index])


func _promote_next_wave_chunk() -> int:
	if not grid.is_empty() or reserve_rows.is_empty():
		return 0
	var rows_to_move: int = mini(current_wave_visible_rows(), reserve_rows.size())
	var start_index: int = reserve_rows.size() - rows_to_move
	for row_index in range(start_index, reserve_rows.size()):
		grid.append(reserve_rows[row_index])
	reserve_rows.resize(start_index)
	status_message = "Layer cleared. More bubbles incoming."
	return rows_to_move


func remove_floating_bubbles() -> Array[Dictionary]:
	var attached: Dictionary = {}
	var frontier: Array[Vector2i] = []

	if grid.is_empty():
		return []

	var occupied_cells: Array[Vector2i] = []
	for row in range(grid.size()):
		for col in range(column_count):
			if cell_occupied(row, col):
				occupied_cells.append(Vector2i(row, col))

	var support_graph: Dictionary = _build_float_support_graph(occupied_cells)

	for col in range(column_count):
		if cell_occupied(0, col):
			var top_cell: Vector2i = Vector2i(0, col)
			attached[top_cell] = true
			frontier.append(top_cell)

	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for neighbor in support_graph.get(cell, []):
			if not cell_occupied(neighbor.x, neighbor.y):
				continue
			if attached.has(neighbor):
				continue
			attached[neighbor] = true
			frontier.append(neighbor)

	var removed: Array[Dictionary] = []
	for row in range(grid.size()):
		for col in range(column_count):
			var cell: Vector2i = Vector2i(row, col)
			if grid[row][col] != EMPTY_CELL and not attached.has(cell):
				var bubble_color: int = grid[row][col]
				grid[row][col] = EMPTY_CELL
				removed.append({
					"cell": cell,
					"color": bubble_color,
				})

	if not removed.is_empty():
		compact_grid()

	return removed


func collect_cluster(start: Vector2i, bubble_color: int) -> Array[Vector2i]:
	var cluster: Array[Vector2i] = []
	var frontier: Array[Vector2i] = [start]
	var seen: Dictionary = {start: true}

	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		cluster.append(cell)
		for neighbor in get_neighbors(cell.x, cell.y):
			if not cell_occupied(neighbor.x, neighbor.y):
				continue
			if grid[neighbor.x][neighbor.y] != bubble_color:
				continue
			if seen.has(neighbor):
				continue
			seen[neighbor] = true
			frontier.append(neighbor)

	return cluster


func push_row_from_ceiling(rng: RandomNumberGenerator) -> void:
	var options: Array[int] = available_grid_colors()
	if options.is_empty():
		for color_index in range(current_palette_size()):
			options.append(color_index)

	var new_row: Array[int] = []
	var push_density: float = current_wave_push_density()
	for col in range(column_count):
		if rng.randf() > _push_row_density(push_density, col):
			new_row.append(EMPTY_CELL)
		else:
			new_row.append(options[rng.randi_range(0, options.size() - 1)])

	grid.insert(0, new_row)
	row_parity_offset = (row_parity_offset + 1) % 2
	status_message = "Ceiling dropped one row."


func _sync_wave_settings() -> void:
	var wave_data: Dictionary = current_wave_data()
	if wave_data.is_empty():
		shots_per_shift = 5
		return
	shots_per_shift = maxi(int(wave_data["shots_per_shift"]), 1)


func _row_density(base_density: float, row_index: int, total_rows: int) -> float:
	if total_rows <= 1:
		return base_density
	var row_ratio: float = float(row_index) / float(total_rows - 1)
	var density_bias: float = lerpf(0.04, -0.04, row_ratio)
	return clampf(base_density + density_bias, 0.45, 1.0)


func _push_row_density(base_density: float, column_index: int) -> float:
	var center_distance: float = absf(float(column_index) - float(column_count - 1) * 0.5)
	var edge_relief: float = center_distance / maxf(float(column_count - 1) * 0.5, 1.0)
	return clampf(base_density - edge_relief * 0.05, 0.45, 1.0)
