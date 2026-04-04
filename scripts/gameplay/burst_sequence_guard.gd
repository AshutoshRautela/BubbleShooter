class_name BubbleBurstSequenceGuard
extends RefCounted


static func has_cluster_phase_remaining(pending_bursts: Array, active_bursts: Array) -> bool:
	for burst in pending_bursts:
		if String(burst.get("burst_kind", "")) == "cluster":
			return true
	for burst in active_bursts:
		if String(burst.get("burst_kind", "")) == "cluster":
			return true
	return false


static func can_activate_floating_burst(pending_bursts: Array, active_bursts: Array) -> bool:
	return not has_cluster_phase_remaining(pending_bursts, active_bursts)


static func should_start_floating_phase(deferred_floating_bursts: Array, pending_bursts: Array, active_bursts: Array) -> bool:
	return not deferred_floating_bursts.is_empty() and not has_cluster_phase_remaining(pending_bursts, active_bursts)


static func floating_start_delay(cluster_count: int, cluster_step: float, cluster_duration: float, phase_gap: float) -> float:
	if cluster_count <= 0:
		return 0.0
	var last_cluster_delay: float = float(maxi(cluster_count - 1, 0)) * cluster_step
	return last_cluster_delay + cluster_duration + phase_gap


static func visible_preview_bursts(pending_bursts: Array, deferred_floating_bursts: Array) -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	var seen_cells: Dictionary = {}
	for burst in pending_bursts:
		var pending_copy: Dictionary = Dictionary(burst).duplicate(true)
		var pending_cell: Variant = pending_copy.get("cell", null)
		if pending_cell != null:
			seen_cells[pending_cell] = true
		visible.append(pending_copy)
	for burst in deferred_floating_bursts:
		var preview_burst: Dictionary = Dictionary(burst).duplicate(true)
		var preview_cell: Variant = preview_burst.get("cell", null)
		if preview_cell != null and seen_cells.has(preview_cell):
			continue
		preview_burst["preview_only"] = true
		visible.append(preview_burst)
	return visible
