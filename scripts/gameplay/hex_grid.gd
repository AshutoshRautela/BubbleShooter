extends RefCounted
## Single definition of staggered-hex topology: (row, col) neighbors, row parity bit.
## BubbleBoardState.get_neighbors matches this table exactly (see unit tests).

const STAGGER0_DELTAS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(1, 0),
]
const STAGGER1_DELTAS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, 0), Vector2i(-1, 1),
	Vector2i(1, 0), Vector2i(1, 1),
]


static func row_stagger_bit(row: int, row_parity_offset: int) -> int:
	return (row + row_parity_offset) % 2


static func neighbor_deltas_for_row(row: int, row_parity_offset: int) -> Array[Vector2i]:
	return STAGGER1_DELTAS if row_stagger_bit(row, row_parity_offset) == 1 else STAGGER0_DELTAS


static func neighbors(
	row: int,
	col: int,
	row_parity_offset: int,
	column_count: int,
	allow_row_beyond_grid: bool = true,
	grid_row_count: int = 999999
) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in neighbor_deltas_for_row(row, row_parity_offset):
		var nr: int = row + d.x
		var nc: int = col + d.y
		if nc < 0 or nc >= column_count or nr < 0:
			continue
		if not allow_row_beyond_grid and nr >= grid_row_count:
			continue
		out.append(Vector2i(nr, nc))
	return out
