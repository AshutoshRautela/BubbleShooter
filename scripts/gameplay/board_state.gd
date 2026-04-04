class_name BubbleBoardState
extends RefCounted

const _Hex := preload("res://scripts/gameplay/hex_grid.gd")
const EMPTY_CELL := -1
## Full wave stack height (hidden rows above + visible window). Not every row must be dense.
const TOTAL_WAVE_DEPTH_ROWS := 100

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
## How many rows we keep in `grid` (visible window). Set from `game.update_layout` via `max_rows_visible`.
var playfield_visible_row_target: int = 12

var _float_adj_board_left: float = 0.0
var _float_adj_board_top: float = 0.0
var _float_adj_bubble_radius: float = 32.0
var _float_adj_bubble_diameter: float = 64.0
var _float_adj_row_height: float = 56.0
var _float_adjacency_ready: bool = false

## Filled only during `resolve_placed_bubble`: grid row indices that were 100% empty right before a
## `compact_grid` pass (chain reaction can trigger multiple passes). Higher index = closer to bottom.
## Cleared when the next shot resolves.
var debug_last_resolve_fully_vacated_rows: Array[int] = []
var _debug_capture_vacated_rows: bool = false


func _init(columns: int, palette_size: int, config: BubbleWaveConfig) -> void:
	column_count = columns
	max_palette_size = palette_size
	wave_config = config
	_sync_wave_settings()
	shots_until_shift = shots_per_shift


# ---------------------------------------------------------------------------
#  New game / wave
# ---------------------------------------------------------------------------

func start_new_game(rng: RandomNumberGenerator) -> void:
	score = 0
	wave = 1
	_sync_wave_settings()
	shots_until_shift = shots_per_shift
	status_message = ""
	_spawn_wave(rng)


func set_playfield_visible_row_target(n: int) -> void:
	playfield_visible_row_target = maxi(n, 4)


# ---------------------------------------------------------------------------
#  Place bubble → pop (structural compaction waits until followup / after burst)
# ---------------------------------------------------------------------------

func resolve_placed_bubble(snap: Vector2i, bubble_color: int, _rng: RandomNumberGenerator) -> Dictionary:
	ensure_row(snap.x)
	grid[snap.x][snap.y] = bubble_color

	var pop_result: Dictionary = pop_cluster_from(snap)
	var total_removed: int = pop_result["total_removed"]
	var board_cleared: bool = false
	var burst_row_parity_offset: int = row_parity_offset

	if total_removed == 0:
		score += 5
		status_message = "No match."

	if count_total_wave_bubbles() == 0:
		score += int(round(150.0 * current_wave_score_multiplier()))
		wave += 1
		_sync_wave_settings()
		shots_until_shift = shots_per_shift
		status_message = "Board cleared. Wave %d begins." % wave
		board_cleared = true

	return {
		"cluster_bursts": pop_result["cluster_bursts"],
		"floating_bursts": pop_result["floating_bursts"],
		"total_removed": total_removed,
		"board_cleared": board_cleared,
		"burst_row_parity_offset": burst_row_parity_offset,
		"vacated_full_row_count": 0,
	}


func debug_format_vacated_rows_line() -> String:
	if debug_last_resolve_fully_vacated_rows.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for r in debug_last_resolve_fully_vacated_rows:
		parts.append(str(r))
	return "Vacated full rows (grid idx; larger = closer to bottom): " + ", ".join(parts)


func apply_resolution_followup(result: Dictionary, rng: RandomNumberGenerator) -> void:
	if result["board_cleared"]:
		_spawn_wave(rng)
		result["vacated_full_row_count"] = 0
		result["baseline_refilled"] = 0
		return

	debug_last_resolve_fully_vacated_rows.clear()
	_debug_capture_vacated_rows = true
	compact_grid()
	_debug_capture_vacated_rows = false
	var refilled: int = _refill_to_baseline()
	result["baseline_refilled"] = refilled
	result["vacated_full_row_count"] = debug_last_resolve_fully_vacated_rows.size()
	if not debug_last_resolve_fully_vacated_rows.is_empty():
		print("[row_vacancy] removed_total=%d %s" % [int(result.get("total_removed", 0)), debug_format_vacated_rows_line()])


func _refill_to_baseline() -> int:
	if reserve_rows.is_empty():
		return 0
	var target: int = initial_visible_rows()
	var added: int = 0
	while grid.size() < target and not reserve_rows.is_empty():
		grid.insert(0, reserve_rows.pop_front())
		row_parity_offset = (row_parity_offset + 1) % 2
		added += 1
	if added > 0:
		compact_grid()
	return added


func try_push_shift_row() -> int:
	shots_until_shift -= 1
	if shots_until_shift > 0:
		return 0
	shots_until_shift = shots_per_shift
	if reserve_rows.is_empty():
		return 0
	grid.insert(0, reserve_rows.pop_front())
	row_parity_offset = (row_parity_offset + 1) % 2
	compact_grid()
	return 1


# ---------------------------------------------------------------------------
#  Save / load
# ---------------------------------------------------------------------------

func export_state() -> Dictionary:
	return {
		"grid": grid.duplicate(true),
		"reserve_rows": reserve_rows.duplicate(true),
		"row_parity_offset": row_parity_offset,
		"score": score,
		"wave": wave,
		"shots_until_shift": shots_until_shift,
		"status_message": status_message,
		"playfield_visible_row_target": playfield_visible_row_target,
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
	playfield_visible_row_target = maxi(int(data.get("playfield_visible_row_target", playfield_visible_row_target)), 4)


# ---------------------------------------------------------------------------
#  Wave config queries
# ---------------------------------------------------------------------------

func current_palette_size() -> int:
	var d: Dictionary = current_wave_data()
	if d.is_empty():
		return mini(max_palette_size, 4)
	return clampi(int(d["colors"]), 1, max_palette_size)

func current_wave_data() -> Dictionary:
	if wave_config == null:
		return {}
	return wave_config.get_wave_data(wave)

func current_wave_start_rows() -> int:
	var d: Dictionary = current_wave_data()
	if d.is_empty():
		return 6
	return maxi(int(d["start_rows"]), 1)

func current_wave_visible_rows() -> int:
	return maxi(playfield_visible_row_target, 1)

func current_wave_board_density() -> float:
	var d: Dictionary = current_wave_data()
	if d.is_empty():
		return 0.82
	return clampf(float(d["board_density"]), 0.0, 1.0)

func current_wave_score_multiplier() -> float:
	var d: Dictionary = current_wave_data()
	if d.is_empty():
		return 1.0
	return maxf(float(d["score_multiplier"]), 1.0)

func current_wave_board_type() -> String:
	var d: Dictionary = current_wave_data()
	if d.is_empty():
		return "random"
	return String(d.get("board_type", "random"))


# ---------------------------------------------------------------------------
#  Color helpers
# ---------------------------------------------------------------------------

func pick_shoot_color(rng: RandomNumberGenerator) -> int:
	var options: Array[int] = available_grid_colors()
	if options.is_empty():
		for i in range(current_palette_size()):
			options.append(i)
	return options[rng.randi_range(0, options.size() - 1)]

func available_grid_colors() -> Array[int]:
	var found: Dictionary = {}
	for row in range(grid.size()):
		for col in range(column_count):
			if grid[row][col] != EMPTY_CELL:
				found[grid[row][col]] = true
	var out: Array[int] = []
	for key in found.keys():
		out.append(int(key))
	out.sort()
	if out.is_empty():
		for i in range(current_palette_size()):
			out.append(i)
	return out

func wave_preview_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for r in grid:
		rows.append(r.duplicate())
	for r in reserve_rows:
		rows.append(r.duplicate())
	return rows


# ---------------------------------------------------------------------------
#  Hex grid helpers
# ---------------------------------------------------------------------------

func row_shift_parity(row: int) -> int:
	return (row + row_parity_offset) % 2

func get_neighbors(row: int, col: int) -> Array[Vector2i]:
	return _Hex.neighbors(row, col, row_parity_offset, column_count, true, grid.size())

func sync_float_adjacency(board_left: float, board_top: float, bubble_radius: float, bubble_diameter: float, row_height: float) -> void:
	_float_adj_board_left = board_left
	_float_adj_board_top = board_top
	_float_adj_bubble_radius = maxf(bubble_radius, 0.001)
	_float_adj_bubble_diameter = maxf(bubble_diameter, 0.001)
	_float_adj_row_height = maxf(row_height, 0.001)
	_float_adjacency_ready = true


# ---------------------------------------------------------------------------
#  Grid structure
# ---------------------------------------------------------------------------

func ensure_row(row: int) -> void:
	while grid.size() <= row:
		grid.append(make_empty_row())

func make_empty_row() -> Array[int]:
	var row: Array[int] = []
	for _c in range(column_count):
		row.append(EMPTY_CELL)
	return row

func cell_occupied(row: int, col: int) -> bool:
	return row >= 0 and row < grid.size() and col >= 0 and col < column_count and grid[row][col] != EMPTY_CELL

func count_bubbles() -> int:
	var n: int = 0
	for row in range(grid.size()):
		for col in range(column_count):
			if grid[row][col] != EMPTY_CELL:
				n += 1
	return n

func count_total_wave_bubbles() -> int:
	var n: int = count_bubbles()
	for row in reserve_rows:
		for col in range(column_count):
			if int(row[col]) != EMPTY_CELL:
				n += 1
	return n

func _row_is_completely_empty(row_arr: Array) -> bool:
	for col in range(column_count):
		if int(row_arr[col]) != EMPTY_CELL:
			return false
	return true

func topology_has_no_blank_rows() -> bool:
	for row_arr in grid:
		if _row_is_completely_empty(row_arr):
			return false
	return true


func _fully_empty_row_indices_bottom_first() -> Array[int]:
	var rows: Array[int] = []
	for r in range(grid.size()):
		if _row_is_completely_empty(grid[r]):
			rows.append(r)
	rows.sort()
	rows.reverse()
	return rows


## Remove every fully-empty row.  Flip parity only when an occupied row still sits below.
func compact_grid() -> void:
	if _debug_capture_vacated_rows:
		for r in _fully_empty_row_indices_bottom_first():
			debug_last_resolve_fully_vacated_rows.append(r)
	var i: int = 0
	while i < grid.size():
		if not _row_is_completely_empty(grid[i]):
			i += 1
			continue
		var has_below: bool = false
		for j in range(i + 1, grid.size()):
			if not _row_is_completely_empty(grid[j]):
				has_below = true
				break
		grid.remove_at(i)
		if has_below:
			row_parity_offset = (row_parity_offset + 1) % 2


# ---------------------------------------------------------------------------
#  Burst: pop cluster + remove floating
# ---------------------------------------------------------------------------

func pop_cluster_from(start: Vector2i) -> Dictionary:
	var bubble_color: int = grid[start.x][start.y]
	var cluster: Array[Vector2i] = collect_cluster(start, bubble_color)
	if cluster.size() < 3:
		return {"cluster_bursts": [], "floating_bursts": [], "total_removed": 0}

	var cluster_bursts: Array[Dictionary] = []
	for cell in cluster:
		cluster_bursts.append({"cell": cell, "color": bubble_color})
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

func remove_floating_bubbles() -> Array[Dictionary]:
	if grid.is_empty():
		return []

	var occupied: Array[Vector2i] = []
	for row in range(grid.size()):
		for col in range(column_count):
			if cell_occupied(row, col):
				occupied.append(Vector2i(row, col))

	var support: Dictionary = _build_float_support_graph(occupied)
	var attached: Dictionary = {}
	var frontier: Array[Vector2i] = []
	for col in range(column_count):
		if cell_occupied(0, col):
			var c: Vector2i = Vector2i(0, col)
			attached[c] = true
			frontier.append(c)
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for neighbor in support.get(cell, []):
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
				removed.append({"cell": cell, "color": grid[row][col]})
				grid[row][col] = EMPTY_CELL
	if not removed.is_empty():
		compact_grid()
	return removed


# ---------------------------------------------------------------------------
#  Float adjacency graph (distance-based when viewport info available)
# ---------------------------------------------------------------------------

func _float_world_center(row: int, col: int) -> Vector2:
	var shift: float = float(row_shift_parity(row)) * _float_adj_bubble_radius
	return Vector2(
		_float_adj_board_left + _float_adj_bubble_radius + float(col) * _float_adj_bubble_diameter + shift,
		_float_adj_board_top + _float_adj_bubble_radius + float(row) * _float_adj_row_height
	)

func _build_float_support_graph(occupied_cells: Array[Vector2i]) -> Dictionary:
	var adj: Dictionary = {}
	for cell in occupied_cells:
		adj[cell] = []
	if _float_adjacency_ready:
		var limit: float = _float_adj_bubble_diameter * 1.02
		for ia in range(occupied_cells.size()):
			var a: Vector2i = occupied_cells[ia]
			var pa: Vector2 = _float_world_center(a.x, a.y)
			for ib in range(ia + 1, occupied_cells.size()):
				var b: Vector2i = occupied_cells[ib]
				if pa.distance_to(_float_world_center(b.x, b.y)) <= limit:
					adj[a].append(b)
					adj[b].append(a)
	else:
		for cell in occupied_cells:
			for neighbor in get_neighbors(cell.x, cell.y):
				if not cell_occupied(neighbor.x, neighbor.y):
					continue
				adj[cell].append(neighbor)
	return adj


# ---------------------------------------------------------------------------
#  Wave spawn
# ---------------------------------------------------------------------------

func _spawn_wave(rng: RandomNumberGenerator) -> void:
	grid.clear()
	reserve_rows.clear()
	row_parity_offset = 0
	var depth: int = TOTAL_WAVE_DEPTH_ROWS
	var ps: int = current_palette_size()
	var bd: float = current_wave_board_density()
	if not _spawn_pattern_wave(rng, ps, depth, bd):
		_spawn_clustered_random(rng, ps, depth, bd)
	_split_visible_chunk()
	compact_grid()
	if wave == 1:
		status_message = "Aim with mouse or touch. Match 3 or more bubbles."
	else:
		status_message = "Wave %d ready. Match 3 or more bubbles." % wave

func _spawn_pattern_wave(rng: RandomNumberGenerator, ps: int, sr: int, bd: float) -> bool:
	match wave:
		1:
			_spawn_tutorial(rng, ps, sr, bd)
			return true
		5:
			_spawn_checker(rng, ps, sr, bd)
			return true
		10:
			_spawn_pyramid(rng, ps, sr, bd)
			return true
		15, 20:
			_spawn_stripe(rng, ps, sr, bd)
			return true
	if current_wave_board_type() == "tutorial":
		_spawn_tutorial(rng, ps, sr, bd)
		return true
	return false

func _spawn_clustered_random(rng: RandomNumberGenerator, ps: int, sr: int, bd: float) -> void:
	var bias: float = lerpf(0.82, 0.34, clampf(float(wave - 1) / 24.0, 0.0, 1.0))
	for row in range(sr):
		var cells: Array[int] = []
		for col in range(column_count):
			if rng.randf() > _row_density(bd, row, sr):
				cells.append(EMPTY_CELL)
			else:
				cells.append(_clustered_color(rng, cells, row, col, ps, bias))
		grid.append(cells)

func _spawn_tutorial(rng: RandomNumberGenerator, ps: int, sr: int, bd: float) -> void:
	for row in range(sr):
		var cells: Array[int] = []
		var col: int = 0
		while col < column_count:
			var fd: float = _row_density(bd, row, sr)
			if rng.randf() > fd:
				cells.append(EMPTY_CELL)
				col += 1
				continue
			var sc: int = _clustered_color(rng, cells, row, col, ps, 0.95)
			var seg: int = mini(column_count - col, rng.randi_range(2, 3))
			for _s in range(seg):
				cells.append(sc)
				col += 1
				if col >= column_count:
					break
				if rng.randf() > fd + 0.05:
					break
		grid.append(cells)

func _spawn_checker(rng: RandomNumberGenerator, ps: int, sr: int, bd: float) -> void:
	var pc: Array[int] = _distinct_palette(rng, ps, 2)
	for row in range(sr):
		var cells: Array[int] = []
		for col in range(column_count):
			if rng.randf() > _row_density(bd + 0.04, row, sr):
				cells.append(EMPTY_CELL)
			else:
				cells.append(pc[(int(row / 2) + int(col / 2)) % pc.size()])
		grid.append(cells)

func _spawn_pyramid(rng: RandomNumberGenerator, ps: int, sr: int, bd: float) -> void:
	var bc: Array[int] = _distinct_palette(rng, ps, mini(3, ps))
	var center: float = float(column_count - 1) * 0.5
	for row in range(sr):
		var cells: Array[int] = []
		var wr: float = 1.0 - float(row) / maxf(float(sr), 1.0)
		var hs: float = lerpf(1.4, center + 0.4, wr)
		for col in range(column_count):
			if absf(float(col) - center) > hs or rng.randf() > _row_density(bd + 0.06, row, sr):
				cells.append(EMPTY_CELL)
			else:
				cells.append(bc[mini(int(floor(float(row) / 2.0)), bc.size() - 1)])
		grid.append(cells)

func _spawn_stripe(rng: RandomNumberGenerator, ps: int, sr: int, bd: float) -> void:
	var sc: Array[int] = _distinct_palette(rng, ps, mini(4, ps))
	for row in range(sr):
		var cells: Array[int] = []
		@warning_ignore("INTEGER_DIVISION")
		var c: int = sc[(row / 2) % sc.size()]
		for col in range(column_count):
			if rng.randf() > _row_density(bd + 0.02, row, sr):
				cells.append(EMPTY_CELL)
			else:
				cells.append(c)
		grid.append(cells)

func initial_visible_rows() -> int:
	@warning_ignore("INTEGER_DIVISION")
	return mini(clampi(playfield_visible_row_target / 2, 4, 8), playfield_visible_row_target)


func _split_visible_chunk() -> void:
	var vis: int = mini(initial_visible_rows(), grid.size())
	if vis >= grid.size():
		return
	var all: Array[Array] = grid.duplicate(true)
	grid.clear()
	reserve_rows.clear()
	for i in range(vis):
		grid.append(all[i])
	for i in range(vis, all.size()):
		reserve_rows.append(all[i])


# ---------------------------------------------------------------------------
#  Internal helpers
# ---------------------------------------------------------------------------

func _clustered_color(rng: RandomNumberGenerator, current_row: Array[int], row: int, col: int, ps: int, bias: float) -> int:
	var pref: Array[int] = []
	if col > 0 and int(current_row[col - 1]) != EMPTY_CELL:
		pref.append(int(current_row[col - 1]))
		pref.append(int(current_row[col - 1]))
	for n in get_neighbors(row, col):
		if n.x > row or (n.x == row and n.y >= col):
			continue
		if not cell_occupied(n.x, n.y):
			continue
		pref.append(int(grid[n.x][n.y]))
	if not pref.is_empty() and rng.randf() < bias:
		return pref[rng.randi_range(0, pref.size() - 1)]
	return rng.randi_range(0, ps - 1)

func _distinct_palette(rng: RandomNumberGenerator, ps: int, count: int) -> Array[int]:
	var opts: Array[int] = []
	for i in range(ps):
		opts.append(i)
	opts.shuffle()
	var out: Array[int] = []
	for i in range(mini(count, opts.size())):
		out.append(opts[i])
	if out.is_empty():
		out.append(0)
	return out

func _sync_wave_settings() -> void:
	var d: Dictionary = current_wave_data()
	if d.is_empty():
		shots_per_shift = 5
		return
	shots_per_shift = maxi(int(d["shots_per_shift"]), 1)

func _row_density(base: float, row_idx: int, total: int) -> float:
	if total <= 1:
		return base
	var ratio: float = float(row_idx) / float(total - 1)
	return clampf(base + lerpf(0.04, -0.04, ratio), 0.45, 1.0)
