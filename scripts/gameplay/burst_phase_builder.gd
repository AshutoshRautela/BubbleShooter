class_name BubbleBurstPhaseBuilder
extends RefCounted


static func build_phases(
	resolution: Dictionary,
	start_cell: Vector2i,
	origin: Vector2,
	board: BubbleBoardState,
	grid_layout: BubbleGridLayout,
	colors: Array[Color],
	bubble_radius: float,
	mobile_low_fx: bool
) -> Dictionary:
	var parity_offset: int = resolution["burst_row_parity_offset"]
	var cluster_entries: Array[Dictionary] = _build_cluster_entries(
		resolution["cluster_bursts"], start_cell, origin, parity_offset, board, grid_layout, colors
	)
	var floating_entries: Array[Dictionary] = _build_floating_entries(
		resolution["floating_bursts"], origin, parity_offset, board, grid_layout, colors
	)
	var cluster_cells: Dictionary = {}
	for entry in cluster_entries:
		cluster_cells[entry["cell"]] = true
	if not cluster_cells.is_empty():
		var filtered: Array[Dictionary] = []
		for entry in floating_entries:
			if not cluster_cells.has(entry["cell"]):
				filtered.append(entry)
		floating_entries = filtered

	var cluster_step: float = 0.04 if mobile_low_fx else 0.0336
	var floating_step: float = 0.056 if mobile_low_fx else 0.0464
	var cluster_particle_count: int = 4 if mobile_low_fx else 6
	var floating_particle_count: int = 3 if mobile_low_fx else 5

	for entry in cluster_entries:
		entry["particle_count"] = cluster_particle_count
		entry["particle_scale"] = bubble_radius * 0.24
		entry["duration"] = 0.24 if mobile_low_fx else 0.28
		entry["glow"] = 1.5

	for entry in floating_entries:
		entry["particle_count"] = floating_particle_count
		entry["particle_scale"] = bubble_radius * 0.19
		entry["duration"] = 0.22 if mobile_low_fx else 0.26
		entry["glow"] = 1.22

	for index in range(cluster_entries.size()):
		cluster_entries[index]["delay"] = float(index) * cluster_step
	for index in range(floating_entries.size()):
		floating_entries[index]["delay"] = float(index) * floating_step

	return {"cluster": cluster_entries, "floating": floating_entries}


static func _build_cluster_entries(
	cluster_bursts: Array,
	start_cell: Vector2i,
	origin: Vector2,
	parity_offset: int,
	board: BubbleBoardState,
	gl: BubbleGridLayout,
	colors: Array[Color]
) -> Array[Dictionary]:
	var burst_by_cell: Dictionary = {}
	for burst in cluster_bursts:
		burst_by_cell[burst["cell"]] = burst

	var ordered_cells: Array[Vector2i] = []
	var visited: Dictionary = {}
	var frontier: Array[Vector2i] = []
	if burst_by_cell.has(start_cell):
		frontier.append(start_cell)
		visited[start_cell] = true
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		ordered_cells.append(cell)
		for neighbor in board.get_neighbors(cell.x, cell.y):
			if not burst_by_cell.has(neighbor) or visited.has(neighbor):
				continue
			visited[neighbor] = true
			frontier.append(neighbor)

	if ordered_cells.size() < cluster_bursts.size():
		var remaining: Array[Dictionary] = []
		for burst in cluster_bursts:
			var c: Vector2i = burst["cell"]
			if visited.has(c):
				continue
			remaining.append({
				"cell": c,
				"sort_key": gl.cell_center(c.x, c.y, parity_offset).distance_squared_to(origin),
			})
		remaining.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["sort_key"]) < float(b["sort_key"])
		)
		for entry in remaining:
			ordered_cells.append(entry["cell"])

	var entries: Array[Dictionary] = []
	for c in ordered_cells:
		var burst: Dictionary = burst_by_cell[c]
		entries.append({
			"cell": c,
			"center": gl.cell_center(c.x, c.y, parity_offset),
			"color": colors[int(burst["color"])],
			"burst_kind": "cluster",
		})
	return entries


static func _build_floating_entries(
	floating_bursts: Array,
	origin: Vector2,
	parity_offset: int,
	board: BubbleBoardState,
	gl: BubbleGridLayout,
	colors: Array[Color]
) -> Array[Dictionary]:
	var burst_by_cell: Dictionary = {}
	for burst in floating_bursts:
		burst_by_cell[burst["cell"]] = burst

	var components: Array[Dictionary] = []
	var visited: Dictionary = {}
	for burst in floating_bursts:
		var start_cell: Vector2i = burst["cell"]
		if visited.has(start_cell):
			continue
		var cells: Array[Vector2i] = []
		var frontier: Array[Vector2i] = [start_cell]
		visited[start_cell] = true
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_front()
			cells.append(cell)
			for neighbor in board.get_neighbors(cell.x, cell.y):
				if not burst_by_cell.has(neighbor) or visited.has(neighbor):
					continue
				visited[neighbor] = true
				frontier.append(neighbor)
		var seed_cell: Vector2i = cells[0]
		var seed_dist: float = gl.cell_center(seed_cell.x, seed_cell.y, parity_offset).distance_squared_to(origin)
		for cell in cells:
			var d: float = gl.cell_center(cell.x, cell.y, parity_offset).distance_squared_to(origin)
			if d < seed_dist:
				seed_cell = cell
				seed_dist = d
		components.append({"seed_cell": seed_cell, "seed_distance": seed_dist, "cells": cells})

	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["seed_distance"]) < float(b["seed_distance"])
	)

	var entries: Array[Dictionary] = []
	for component in components:
		var seed_cell: Vector2i = component["seed_cell"]
		var comp_cells: Array[Vector2i] = component["cells"]
		var lookup: Dictionary = {}
		for cell in comp_cells:
			lookup[cell] = true
		var comp_visited: Dictionary = {seed_cell: true}
		var frontier: Array[Vector2i] = [seed_cell]
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_front()
			var burst: Dictionary = burst_by_cell[cell]
			entries.append({
				"cell": cell,
				"center": gl.cell_center(cell.x, cell.y, parity_offset),
				"color": colors[int(burst["color"])].darkened(0.05),
				"burst_kind": "floating",
			})
			for neighbor in board.get_neighbors(cell.x, cell.y):
				if not lookup.has(neighbor) or comp_visited.has(neighbor):
					continue
				comp_visited[neighbor] = true
				frontier.append(neighbor)
	return entries
