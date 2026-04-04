extends SceneTree
## Headless integration test: simulates a full wave until all 100 reserve rows
## are consumed and the board is cleared (or MAX_STEPS is hit).
## Tracks grid row counts, baseline refills, shift pushes, and chain reactions.
##
## Run: godot --headless -s res://tests/gameplay_harness.gd
## Exit code 0 = all checks passed.

const Helpers := preload("res://tests/helpers/test_helpers.gd")

const MAX_STEPS := 4000
const SEEDS := [90001, 12345, 77777, 42069, 314159]
const COLUMNS := 9


func _initialize() -> void:
	var total_failures: int = 0
	for seed_val in SEEDS:
		total_failures += _run_seed(seed_val)
	print("\nHARNESS TOTAL: %d seeds, %d failures" % [SEEDS.size(), total_failures])
	quit(total_failures)


func _run_seed(seed_val: int) -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val
	var board: BubbleBoardState = Helpers.make_board(COLUMNS, 6)
	board.wave = 1
	board._spawn_wave(rng)

	var initial_reserve: int = board.reserve_rows.size()
	var initial_grid: int = board.grid.size()
	var baseline_target: int = board.initial_visible_rows()

	print("\n=== SEED %d === wave=1  grid=%d  reserve=%d  baseline_target=%d" % [
		seed_val, initial_grid, initial_reserve, baseline_target
	])

	var failures: int = 0
	var step: int = 0
	var waves_cleared: int = 0
	var total_pops: int = 0
	var total_shifted: int = 0
	var total_baseline_refills: int = 0
	var min_grid_rows: int = initial_grid
	var max_grid_rows: int = initial_grid
	var grid_below_baseline_count: int = 0

	while step < MAX_STEPS:
		var err: String = _check_invariants(board, step, "pre-move")
		if not err.is_empty():
			push_error("  FAIL seed=%d step=%d %s" % [seed_val, step, err])
			_dump_grid(board, step)
			failures += 1
			break

		var row0_snapshot: Array[int] = board.grid[0].duplicate() if not board.grid.is_empty() else ([] as Array[int])

		var snap: Vector2i = _pick_shot_cell(board, rng)
		var color: int = board.pick_shoot_color(rng)
		var grid_before: int = board.grid.size()
		var reserve_before: int = board.reserve_rows.size()

		var res: Dictionary = board.resolve_placed_bubble(snap, color, rng)
		board.apply_resolution_followup(res, rng)

		var removed: int = int(res["total_removed"])
		total_pops += removed
		var refilled: int = int(res.get("baseline_refilled", 0))

		var shifted: int = 0
		if not res["board_cleared"]:
			shifted = board.try_push_shift_row()
			total_shifted += shifted

		var grid_after: int = board.grid.size()
		var reserve_after: int = board.reserve_rows.size()
		var baseline_refilled: int = reserve_before - reserve_after - shifted
		if baseline_refilled > 0:
			total_baseline_refills += baseline_refilled

		min_grid_rows = mini(min_grid_rows, grid_after)
		max_grid_rows = maxi(max_grid_rows, grid_after)

		if grid_after < baseline_target and not board.reserve_rows.is_empty():
			grid_below_baseline_count += 1

		if res["board_cleared"]:
			waves_cleared += 1
			print("  step=%d WAVE CLEARED  grid=%d→%d  reserve=%d→%d  popped=%d" % [
				step, grid_before, grid_after, reserve_before, reserve_after, removed
			])

		if removed >= 6 or shifted > 0 or baseline_refilled > 0:
			print("  step=%d grid=%d→%d reserve=%d→%d popped=%d shifted=%d baseline_refill=%d" % [
				step, grid_before, grid_after, reserve_before, reserve_after, removed, shifted, baseline_refilled
			])

		err = _check_invariants(board, step, "post-move")
		if not err.is_empty():
			push_error("  FAIL seed=%d step=%d %s" % [seed_val, step, err])
			_dump_grid(board, step)
			failures += 1
			break

		var row_err: String = _check_row_count(board)
		if not row_err.is_empty():
			push_error("  FAIL seed=%d step=%d %s" % [seed_val, step, row_err])
			_dump_grid(board, step)
			failures += 1
			break

		var ceiling_err: String = _check_ceiling_insert(
			board, row0_snapshot, refilled + shifted, step, res
		)
		if not ceiling_err.is_empty():
			push_error("  FAIL seed=%d step=%d %s" % [seed_val, step, ceiling_err])
			_dump_grid(board, step)
			failures += 1
			break

		if waves_cleared > 0 and board.reserve_rows.is_empty() and board.count_bubbles() == 0:
			print("  step=%d ALL BUBBLES CLEARED" % step)
			break

		step += 1

	if step >= MAX_STEPS:
		print("  WARNING: hit MAX_STEPS=%d without clearing wave (reserve=%d grid_bubbles=%d)" % [
			MAX_STEPS, board.reserve_rows.size(), board.count_bubbles()
		])

	var status: String = "PASS" if failures == 0 else "FAIL"
	print(
		"  %s | steps=%d waves_cleared=%d total_pops=%d shifted=%d baseline_refills=%d" % [
			status, step, waves_cleared, total_pops, total_shifted, total_baseline_refills
		]
	)
	print(
		"  grid: min=%d max=%d final=%d  reserve: start=%d final=%d  below_baseline_violations=%d" % [
			min_grid_rows, max_grid_rows, board.grid.size(),
			initial_reserve, board.reserve_rows.size(), grid_below_baseline_count
		]
	)
	return failures


func _check_invariants(board: BubbleBoardState, _step: int, phase: String) -> String:
	if board.grid.is_empty():
		if board.reserve_rows.is_empty():
			return ""
		return "%s: grid is empty but reserve has %d rows" % [phase, board.reserve_rows.size()]

	if not board.topology_has_no_blank_rows():
		return "%s: grid has fully blank row (grid.size=%d)" % [phase, board.grid.size()]

	if board.row_parity_offset != 0 and board.row_parity_offset != 1:
		return "%s: bad row_parity_offset=%d" % [phase, board.row_parity_offset]

	var row0_has_bubble: bool = false
	for col in range(board.column_count):
		if board.grid[0][col] != BubbleBoardState.EMPTY_CELL:
			row0_has_bubble = true
			break
	if not row0_has_bubble:
		return "%s: row 0 is empty after compact" % phase

	return ""


func _check_ceiling_insert(
	board: BubbleBoardState,
	old_row0: Array[int],
	rows_inserted: int,
	_step: int,
	res: Dictionary
) -> String:
	if rows_inserted <= 0 or bool(res.get("board_cleared", false)):
		return ""
	if rows_inserted >= board.grid.size():
		return ""
	var target_row: int = rows_inserted
	if target_row >= board.grid.size():
		return ""
	var matched: int = 0
	var checked: int = 0
	for col in range(board.column_count):
		var old_val: int = int(old_row0[col])
		if old_val == BubbleBoardState.EMPTY_CELL:
			continue
		checked += 1
		if int(board.grid[target_row][col]) == old_val:
			matched += 1
	if checked == 0:
		return ""
	if matched == 0 and checked >= 3:
		return (
			"ceiling insert: old row-0 (%d occupied cells) not found at row %d after %d rows inserted — rows may have been appended at bottom instead"
			% [checked, target_row, rows_inserted]
		)
	return ""


func _check_row_count(board: BubbleBoardState) -> String:
	if board.count_total_wave_bubbles() == 0:
		return ""
	var min_rows: int = board.initial_visible_rows()
	if board.grid.size() < min_rows and not board.reserve_rows.is_empty():
		return (
			"grid has %d rows, expected >= %d while reserve still has %d rows"
			% [board.grid.size(), min_rows, board.reserve_rows.size()]
		)
	return ""


func _dump_grid(board: BubbleBoardState, step: int) -> void:
	push_error("  --- grid dump at step %d (rows=%d, parity=%d) ---" % [
		step, board.grid.size(), board.row_parity_offset
	])
	for r in range(mini(board.grid.size(), 20)):
		var cells: PackedStringArray = PackedStringArray()
		for c in range(board.column_count):
			var v: int = int(board.grid[r][c])
			cells.append("." if v == BubbleBoardState.EMPTY_CELL else str(v))
		var indent: String = " " if board.row_shift_parity(r) == 1 else ""
		push_error("  row %2d: %s%s" % [r, indent, " ".join(cells)])
	if board.grid.size() > 20:
		push_error("  ... (%d more rows)" % (board.grid.size() - 20))
	push_error("  reserve=%d  shots_until_shift=%d" % [
		board.reserve_rows.size(), board.shots_until_shift
	])


func _pick_shot_cell(board: BubbleBoardState, rng: RandomNumberGenerator) -> Vector2i:
	var adj_candidates: Array[Vector2i] = []
	var any_empty: Array[Vector2i] = []
	for r in range(board.grid.size()):
		for c in range(board.column_count):
			if board.grid[r][c] != BubbleBoardState.EMPTY_CELL:
				continue
			any_empty.append(Vector2i(r, c))
			for n in board.get_neighbors(r, c):
				if board.cell_occupied(n.x, n.y):
					adj_candidates.append(Vector2i(r, c))
					break

	if not adj_candidates.is_empty():
		return adj_candidates[rng.randi() % adj_candidates.size()]
	if not any_empty.is_empty():
		return any_empty[rng.randi() % any_empty.size()]

	var new_r: int = board.grid.size()
	board.ensure_row(new_r)
	return Vector2i(new_r, rng.randi() % board.column_count)
