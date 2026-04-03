class_name BubbleBoardState
extends RefCounted

const EMPTY_CELL := -1
const BASE_PALETTE_SIZE := 4

var column_count: int
var start_rows: int
var shots_per_shift: int
var max_palette_size: int

var grid: Array[Array] = []
var row_parity_offset: int = 0
var score: int = 0
var wave: int = 1
var shots_until_shift: int
var status_message: String = ""


func _init(columns: int, initial_rows: int, shift_shots: int, palette_size: int) -> void:
	column_count = columns
	start_rows = initial_rows
	shots_per_shift = shift_shots
	max_palette_size = palette_size
	shots_until_shift = shots_per_shift


func start_new_game(rng: RandomNumberGenerator) -> void:
	score = 0
	wave = 1
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
	var burst_row_parity_offset: int = row_parity_offset

	compact_grid()

	if total_removed == 0:
		score += 5

	if count_bubbles() == 0:
		score += 150
		wave += 1
		shots_until_shift = shots_per_shift
		status_message = "Board cleared. Wave %d begins." % wave
		board_cleared = true
	else:
		shots_until_shift -= 1
		if total_removed == 0:
			status_message = "No match. New row in %d shots." % [maxi(shots_until_shift, 0)]
		if shots_until_shift <= 0:
			shots_until_shift = shots_per_shift
			row_pushed = true

	return {
		"cluster_bursts": pop_result["cluster_bursts"],
		"floating_bursts": pop_result["floating_bursts"],
		"total_removed": total_removed,
		"board_cleared": board_cleared,
		"row_pushed": row_pushed,
		"burst_row_parity_offset": burst_row_parity_offset,
	}


func apply_resolution_followup(result: Dictionary, rng: RandomNumberGenerator) -> void:
	if result["board_cleared"]:
		_spawn_wave(rng)
		return

	if result["row_pushed"]:
		push_row_from_ceiling(rng)


func current_palette_size() -> int:
	return clampi(BASE_PALETTE_SIZE + int((wave - 1) / 2), BASE_PALETTE_SIZE, max_palette_size)


func pick_shoot_color(rng: RandomNumberGenerator) -> int:
	var options: Array[int] = available_grid_colors()
	if options.is_empty():
		for color_index in range(mini(BASE_PALETTE_SIZE, max_palette_size)):
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


func row_shift_parity(row: int) -> int:
	return (row + row_parity_offset) % 2


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


func _spawn_wave(rng: RandomNumberGenerator) -> void:
	grid.clear()
	row_parity_offset = 0
	var palette_size: int = current_palette_size()
	for row in range(start_rows):
		var cells: Array[int] = []
		for _col in range(column_count):
			if row > 1 and rng.randf() < 0.1:
				cells.append(EMPTY_CELL)
			else:
				cells.append(rng.randi_range(0, palette_size - 1))
		grid.append(cells)
	status_message = "Aim with mouse or touch. Match 3 or more bubbles."


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


func remove_floating_bubbles() -> Array[Dictionary]:
	var attached: Dictionary = {}
	var frontier: Array[Vector2i] = []

	if grid.is_empty():
		return []

	for col in range(column_count):
		if cell_occupied(0, col):
			var top_cell: Vector2i = Vector2i(0, col)
			attached[top_cell] = true
			frontier.append(top_cell)

	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for neighbor in get_neighbors(cell.x, cell.y):
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
		options = [0]

	var new_row: Array[int] = []
	for col in range(column_count):
		if col > 0 and col < column_count - 1 and rng.randf() < 0.08:
			new_row.append(EMPTY_CELL)
		else:
			new_row.append(options[rng.randi_range(0, options.size() - 1)])

	grid.insert(0, new_row)
	row_parity_offset = (row_parity_offset + 1) % 2
	status_message = "Ceiling dropped one row."
