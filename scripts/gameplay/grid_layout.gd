class_name BubbleGridLayout
extends RefCounted

var board_left: float = 0.0
var board_right: float = 0.0
var board_top: float = 0.0
var bubble_radius: float = 32.0
var bubble_diameter: float = 64.0
var row_height: float = 56.0
var max_rows_visible: int = 12
var cannon_position: Vector2 = Vector2.ZERO
var lose_line_y: float = 0.0
var stack_visual_offset: float = 0.0


func cell_center(row: int, col: int, parity_offset: int) -> Vector2:
	return Vector2(
		board_left + bubble_radius + float(col) * bubble_diameter + float((row + parity_offset) % 2) * bubble_radius,
		board_top + bubble_radius + float(row) * row_height + stack_visual_offset
	)


func cell_center_static(row: int, col: int, parity_offset: int) -> Vector2:
	return Vector2(
		board_left + bubble_radius + float(col) * bubble_diameter + float((row + parity_offset) % 2) * bubble_radius,
		board_top + bubble_radius + float(row) * row_height
	)


func playfield_rect() -> Rect2:
	var top: float = board_top - bubble_radius * 0.18 + stack_visual_offset
	var height: float = lose_line_y - top
	height = maxf(height, row_height * 0.5)
	return Rect2(Vector2(board_left, top), Vector2(board_right - board_left, height))
