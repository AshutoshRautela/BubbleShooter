class_name BubbleShotPlanner
extends RefCounted

const FIRE_ASSIST_MAX_ANGLE := 0.028
const FIRE_ASSIST_STEP_ANGLE := 0.007

var board: BubbleBoardState
var grid_layout: BubbleGridLayout
var board_left: float:
	get: return grid_layout.board_left if grid_layout else 0.0
var board_right: float:
	get: return grid_layout.board_right if grid_layout else 0.0
var board_top: float:
	get: return grid_layout.board_top if grid_layout else 0.0
var bubble_radius: float:
	get: return grid_layout.bubble_radius if grid_layout else 32.0
var bubble_diameter: float:
	get: return grid_layout.bubble_diameter if grid_layout else 64.0
var row_height: float:
	get: return grid_layout.row_height if grid_layout else 56.0
var max_rows_visible: int:
	get: return grid_layout.max_rows_visible if grid_layout else 12
var cannon_position: Vector2:
	get: return grid_layout.cannon_position if grid_layout else Vector2.ZERO
var stack_visual_offset: float:
	get: return grid_layout.stack_visual_offset if grid_layout else 0.0
var start_rows: int = 6


func sync_layout(board_state: BubbleBoardState, layout: BubbleGridLayout) -> void:
	board = board_state
	grid_layout = layout
	start_rows = board.current_wave_visible_rows()


func reflect_velocity_off_wall(simulated_velocity: Vector2, wall_side: String) -> Vector2:
	var into_playfield: Vector2 = Vector2.RIGHT if wall_side == "left" else Vector2.LEFT
	return simulated_velocity.bounce(into_playfield)


func apply_fire_assist(direction: Vector2) -> Vector2:
	var best_direction: Vector2 = direction
	var best_score: float = INF
	var angle_offsets: Array[float] = [
		0.0,
		-FIRE_ASSIST_STEP_ANGLE,
		FIRE_ASSIST_STEP_ANGLE,
		-FIRE_ASSIST_STEP_ANGLE * 2.0,
		FIRE_ASSIST_STEP_ANGLE * 2.0,
		-FIRE_ASSIST_STEP_ANGLE * 3.0,
		FIRE_ASSIST_STEP_ANGLE * 3.0,
		-FIRE_ASSIST_STEP_ANGLE * 4.0,
		FIRE_ASSIST_STEP_ANGLE * 4.0,
	]

	for angle_offset in angle_offsets:
		if absf(angle_offset) > FIRE_ASSIST_MAX_ANGLE:
			continue
		var candidate_direction: Vector2 = direction.rotated(angle_offset).normalized()
		var shot_result: Dictionary = simulate_shot_path(candidate_direction)
		var impact_type: String = shot_result["impact_type"]
		if impact_type == "none":
			continue

		var score: float = absf(angle_offset) * bubble_radius * 14.0
		if impact_type == "stack":
			var impact_position: Vector2 = shot_result["impact_position"]
			var snap_cell: Vector2i = shot_result["snap_cell"]
			var snap_center: Vector2 = cell_to_world(snap_cell.x, snap_cell.y)
			score += snap_center.distance_to(impact_position) * 4.5
		else:
			score += 4.0

		if score < best_score:
			best_score = score
			best_direction = candidate_direction

	return best_direction


func simulate_shot_path(direction: Vector2) -> Dictionary:
	var bounce_sides: Array[String] = []
	var point: Vector2 = cannon_position
	var simulated_velocity: Vector2 = direction * bubble_radius * 1.7

	for _index in range(60):
		var next_point: Vector2 = point + simulated_velocity
		var event: Dictionary = find_first_path_event(point, next_point)
		if event.is_empty():
			point = next_point
			continue

		var event_type: String = event["type"]
		if event_type == "wall":
			point = event["position"]
			var wall_side: String = event["side"]
			bounce_sides.append(wall_side)
			simulated_velocity = reflect_velocity_off_wall(simulated_velocity, wall_side)
			point += simulated_velocity.normalized() * 0.2
			continue
		if event_type == "ceiling":
			var ceiling_impact: Vector2 = event["position"]
			var ceiling_snap: Vector2i = find_best_snap_cell(ceiling_impact, Vector2i(-1, -1), true)
			return {
				"impact_type": "ceiling",
				"impact_position": ceiling_impact,
				"snap_cell": ceiling_snap,
				"points": build_exact_path_to_target(cell_to_world(ceiling_snap.x, ceiling_snap.y), bounce_sides),
				"bounce_indices": build_bounce_indices(bounce_sides.size()),
			}
		if event_type == "stack":
			var stack_impact: Vector2 = event["position"]
			var hit_cell: Vector2i = event["cell"]
			var snap_cell: Vector2i = find_best_snap_cell(stack_impact, hit_cell, false)
			return {
				"impact_type": "stack",
				"impact_position": stack_impact,
				"snap_cell": snap_cell,
				"cell": hit_cell,
				"points": build_exact_path_to_target(cell_to_world(snap_cell.x, snap_cell.y), bounce_sides),
				"bounce_indices": build_bounce_indices(bounce_sides.size()),
			}

	var fallback_points: Array[Vector2] = [cannon_position, point]
	return {
		"impact_type": "none",
		"impact_position": point,
		"points": fallback_points,
		"bounce_indices": build_bounce_indices(bounce_sides.size()),
		"snap_cell": Vector2i(-1, -1),
	}


func path_total_length(points: Array[Vector2]) -> float:
	var total: float = 0.0
	for index in range(points.size() - 1):
		total += points[index].distance_to(points[index + 1])
	return total


func trace_aim_path(direction: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = [cannon_position]
	var point: Vector2 = cannon_position
	var simulated_velocity: Vector2 = direction * bubble_radius * 1.7

	for _index in range(60):
		var next_point: Vector2 = point + simulated_velocity
		var event: Dictionary = find_first_path_event(point, next_point)
		if event.is_empty():
			point = next_point
			points.append(point)
			continue

		var event_type: String = event["type"]
		point = event["position"]
		points.append(point)

		if event_type == "wall":
			var wall_side: String = event["side"]
			simulated_velocity = reflect_velocity_off_wall(simulated_velocity, wall_side)
			point += simulated_velocity.normalized() * 0.2
			continue

		break

	return points


func build_exact_path_to_target(target_position: Vector2, bounce_sides: Array[String]) -> Array[Vector2]:
	var left_x: float = board_left + bubble_radius
	var right_x: float = board_right - bubble_radius
	var virtual_target: Vector2 = target_position

	for index in range(bounce_sides.size() - 1, -1, -1):
		if bounce_sides[index] == "left":
			virtual_target.x = left_x - (virtual_target.x - left_x)
		else:
			virtual_target.x = right_x + (right_x - virtual_target.x)

	var points: Array[Vector2] = [cannon_position]
	var line_start: Vector2 = cannon_position
	for side in bounce_sides:
		var wall_x: float = left_x if side == "left" else right_x
		var delta_x: float = virtual_target.x - line_start.x
		if absf(delta_x) <= 0.0001:
			break
		var t: float = (wall_x - line_start.x) / delta_x
		var bounce_point: Vector2 = line_start.lerp(virtual_target, t)
		points.append(bounce_point)
		line_start = bounce_point

	points.append(target_position)
	return points


func find_first_path_event(start_position: Vector2, end_position: Vector2) -> Dictionary:
	var best_event: Dictionary = {}
	var best_t: float = 2.0
	var movement: Vector2 = end_position - start_position

	if absf(movement.x) > 0.0001:
		var left_x: float = board_left + bubble_radius
		var right_x: float = board_right - bubble_radius
		var wall_t: float = -1.0
		var wall_side: String = ""
		if movement.x < 0.0 and end_position.x <= left_x:
			wall_t = (left_x - start_position.x) / movement.x
			wall_side = "left"
		elif movement.x > 0.0 and end_position.x >= right_x:
			wall_t = (right_x - start_position.x) / movement.x
			wall_side = "right"

		if wall_t >= 0.0 and wall_t <= 1.0 and wall_t < best_t:
			best_t = wall_t
			best_event = {
				"type": "wall",
				"side": wall_side,
				"t": wall_t,
				"position": start_position.lerp(end_position, wall_t),
			}

	if movement.y < -0.0001:
		var ceiling_y: float = board_top + bubble_radius + stack_visual_offset
		if end_position.y <= ceiling_y:
			var ceiling_t: float = (ceiling_y - start_position.y) / movement.y
			if ceiling_t >= 0.0 and ceiling_t <= 1.0 and ceiling_t < best_t:
				best_t = ceiling_t
				best_event = {
					"type": "ceiling",
					"t": ceiling_t,
					"position": start_position.lerp(end_position, ceiling_t),
				}

	var collision_radius: float = bubble_diameter
	for row in range(board.grid.size()):
		for col in range(board.column_count):
			if board.grid[row][col] == BubbleBoardState.EMPTY_CELL:
				continue
			var candidate_cell: Vector2i = Vector2i(row, col)
			var target_center: Vector2 = cell_to_world(row, col)
			var hit_t: float = segment_circle_hit_t(start_position, end_position, target_center, collision_radius)
			if hit_t >= 0.0 and hit_t < best_t:
				best_t = hit_t
				best_event = {
					"type": "stack",
					"t": hit_t,
					"position": start_position.lerp(end_position, hit_t),
					"cell": candidate_cell,
				}

	return best_event


func segment_circle_hit_t(start_position: Vector2, end_position: Vector2, center: Vector2, radius: float) -> float:
	var direction: Vector2 = end_position - start_position
	var a: float = direction.dot(direction)
	if a <= 0.000001:
		return -1.0

	var offset: Vector2 = start_position - center
	var b: float = 2.0 * offset.dot(direction)
	var c: float = offset.dot(offset) - radius * radius
	var discriminant: float = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return -1.0

	var sqrt_discriminant: float = sqrt(discriminant)
	var t1: float = (-b - sqrt_discriminant) / (2.0 * a)
	var t2: float = (-b + sqrt_discriminant) / (2.0 * a)
	if t1 >= 0.0 and t1 <= 1.0:
		return t1
	if t2 >= 0.0 and t2 <= 1.0:
		return t2
	return -1.0


func find_best_snap_cell(position: Vector2, anchor_cell: Vector2i, hit_ceiling: bool) -> Vector2i:
	if hit_ceiling:
		return find_top_snap_cell(position)

	if anchor_cell != Vector2i(-1, -1):
		var anchored_snap: Vector2i = find_neighbor_snap_cell(position, anchor_cell)
		if anchored_snap != Vector2i(-1, -1):
			return anchored_snap

	var best: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF
	var scan_rows: int = mini(max_rows_visible + 2, maxi(board.grid.size() + 2, start_rows + 3))

	for row in range(scan_rows):
		for col in range(board.column_count):
			if board.cell_occupied(row, col):
				continue
			if row != 0 and not has_occupied_neighbor(row, col):
				continue
			var distance: float = cell_to_world(row, col).distance_to(position)
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(row, col)

	if best == Vector2i(-1, -1):
		best = find_top_snap_cell(position)

	return best


func find_top_snap_cell(position: Vector2) -> Vector2i:
	var row_start_x: float = board_left + bubble_radius + float(board.row_shift_parity(0)) * bubble_radius
	var guessed_col: int = clampi(int(round((position.x - row_start_x) / bubble_diameter)), 0, board.column_count - 1)
	if not board.cell_occupied(0, guessed_col):
		return Vector2i(0, guessed_col)

	var best: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF
	for col in range(board.column_count):
		if board.cell_occupied(0, col):
			continue
		var cell: Vector2i = Vector2i(0, col)
		var distance: float = cell_to_world(cell.x, cell.y).distance_to(position)
		if distance < best_distance:
			best_distance = distance
			best = cell

	if best != Vector2i(-1, -1):
		return best

	return Vector2i(0, guessed_col)


func find_neighbor_snap_cell(position: Vector2, anchor_cell: Vector2i) -> Vector2i:
	var anchor_center: Vector2 = cell_to_world(anchor_cell.x, anchor_cell.y)
	var outward: Vector2 = position - anchor_center
	if outward.length_squared() < 0.0001:
		outward = Vector2.UP
	else:
		outward = outward.normalized()

	var best: Vector2i = Vector2i(-1, -1)
	var best_score: float = INF
	for neighbor in board.get_neighbors(anchor_cell.x, anchor_cell.y):
		if board.cell_occupied(neighbor.x, neighbor.y):
			continue
		var candidate_center: Vector2 = cell_to_world(neighbor.x, neighbor.y)
		var distance_score: float = candidate_center.distance_to(position)
		var alignment_bias: float = (1.0 - maxf(-1.0, minf(1.0, outward.dot((candidate_center - anchor_center).normalized())))) * bubble_radius * 0.45
		var score: float = distance_score + alignment_bias
		if score < best_score:
			best_score = score
			best = neighbor

	return best


func has_occupied_neighbor(row: int, col: int) -> bool:
	for neighbor in board.get_neighbors(row, col):
		if board.cell_occupied(neighbor.x, neighbor.y):
			return true
	return false


func build_bounce_indices(count: int) -> Array[int]:
	var indices: Array[int] = []
	for index in range(count):
		indices.append(index + 1)
	return indices


func cell_to_world(row: int, col: int) -> Vector2:
	return grid_layout.cell_center(row, col, board.row_parity_offset)
