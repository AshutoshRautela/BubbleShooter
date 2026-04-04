extends BubbleTestCase

const Helpers = preload("res://tests/helpers/test_helpers.gd")


func test_extreme_left_shot_bounces_off_left_wall_and_reflects_inward() -> void:
	var board = Helpers.make_board(9, 6)
	var planner = Helpers.make_shot_planner(board)
	var shot: Dictionary = planner.simulate_shot_path(Vector2(-1.0, -1.45).normalized())
	var points: Array[Vector2] = shot["points"]
	var bounce_indices: Array[int] = shot["bounce_indices"]
	var left_wall_x: float = planner.board_left + planner.bubble_radius

	assert_true(shot["impact_type"] != "none", "Extreme left shot should still resolve to a real impact")
	assert_true(bounce_indices.size() >= 1, "Extreme left shot should record a wall bounce")
	assert_true(points.size() >= 3, "Bounced shot should contain cannon, bounce, and final target points")
	assert_eq(snappedf(points[1].x, 0.001), snappedf(left_wall_x, 0.001), "First bounce point should land on left wall")
	assert_true(points[2].x > points[1].x, "Path should reflect inward after left wall bounce")


func test_extreme_right_shot_bounces_off_right_wall_and_reflects_inward() -> void:
	var board = Helpers.make_board(9, 6)
	var planner = Helpers.make_shot_planner(board)
	var shot: Dictionary = planner.simulate_shot_path(Vector2(1.0, -1.45).normalized())
	var points: Array[Vector2] = shot["points"]
	var bounce_indices: Array[int] = shot["bounce_indices"]
	var right_wall_x: float = planner.board_right - planner.bubble_radius

	assert_true(shot["impact_type"] != "none", "Extreme right shot should still resolve to a real impact")
	assert_true(bounce_indices.size() >= 1, "Extreme right shot should record a wall bounce")
	assert_true(points.size() >= 3, "Bounced shot should contain cannon, bounce, and final target points")
	assert_eq(snappedf(points[1].x, 0.001), snappedf(right_wall_x, 0.001), "First bounce point should land on right wall")
	assert_true(points[2].x < points[1].x, "Path should reflect inward after right wall bounce")


func test_wall_reflection_preserves_vertical_speed_component() -> void:
	var board = Helpers.make_board(9, 6)
	var planner = Helpers.make_shot_planner(board)
	var planner_velocity: Vector2 = Vector2(-120.0, -180.0)
	var reflected: Vector2 = planner.reflect_velocity_off_wall(planner_velocity, "left")
	assert_eq(reflected.x, -planner_velocity.x, "Horizontal velocity should flip off the left wall")
	assert_true(absf(reflected.y - planner_velocity.y) < 0.001, "Vertical velocity should be unchanged by a vertical wall")


func test_near_wall_anchor_snap_stays_in_bounds() -> void:
	var board = Helpers.make_board(9, 6)
	Helpers.set_grid(board, [
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 0],
		[BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, BubbleBoardState.EMPTY_CELL, 1, BubbleBoardState.EMPTY_CELL],
	])
	var planner = Helpers.make_shot_planner(board)
	var anchor_cell: Vector2i = Vector2i(0, 8)
	var sample_position: Vector2 = planner.cell_to_world(anchor_cell.x, anchor_cell.y) + Vector2(-planner.bubble_radius * 0.92, planner.bubble_radius * 0.22)
	var snap_cell: Vector2i = planner.find_best_snap_cell(sample_position, anchor_cell, false)

	assert_true(snap_cell != Vector2i(-1, -1), "Near-wall anchor should still produce a snap target")
	assert_true(snap_cell.y >= 0 and snap_cell.y < board.column_count, "Snap cell must stay inside board bounds")
	assert_false(board.cell_occupied(snap_cell.x, snap_cell.y), "Snap target should be an empty valid cell")
