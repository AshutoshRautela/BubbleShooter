extends Node2D

const BubbleBoardState = preload("res://scripts/board_state.gd")
const BubbleShotPlanner = preload("res://scripts/shot_planner.gd")

const GRID_COLUMNS := 9
const START_ROWS := 6
const SHOTS_PER_SHIFT := 5
const SHOT_SPEED_BURST_MULTIPLIER := 2.7
const SHOT_SPEED_FINISH_MULTIPLIER := 1.15
const MAX_HIT_WAVES := 6
const MAX_PARTICLES_MOBILE := 90
const MAX_PARTICLES_DESKTOP := 180
const STATE_AIMING := "aiming"
const STATE_FLYING := "flying"
const STATE_GAME_OVER := "game_over"

const COLORS := [
	Color("ff6b6b"),
	Color("ffd166"),
	Color("4ecdc4"),
	Color("5dade2"),
	Color("a78bfa"),
	Color("95e06c"),
]

@onready var hud_panel: PanelContainer = $UI/Hud/Panel
@onready var title_label: Label = $UI/Hud/Panel/VBox/TitleLabel
@onready var score_label: Label = $UI/Hud/Panel/VBox/ScoreLabel
@onready var status_label: Label = $UI/Hud/Panel/VBox/StatusLabel
@onready var fps_label: Label = $UI/Hud/Panel/VBox/FpsLabel
@onready var restart_button: Button = $UI/Hud/Panel/VBox/RestartButton
@onready var overlay: CenterContainer = $UI/Overlay
@onready var overlay_panel: PanelContainer = $UI/Overlay/Panel
@onready var overlay_title: Label = $UI/Overlay/Panel/VBox/OverlayTitle
@onready var overlay_message: Label = $UI/Overlay/Panel/VBox/OverlayMessage
@onready var overlay_button: Button = $UI/Overlay/Panel/VBox/OverlayButton

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var board: BubbleBoardState = BubbleBoardState.new(GRID_COLUMNS, START_ROWS, SHOTS_PER_SHIFT, COLORS.size())
var shot_planner: BubbleShotPlanner = BubbleShotPlanner.new()
var grid: Array[Array] = board.grid
var active_bubble: Dictionary = {}
var pop_particles: Array[Dictionary] = []
var hit_waves: Array[Dictionary] = []
var ambient_stars: Array[Dictionary] = []

var aim_target: Vector2 = Vector2.ZERO
var state: String = STATE_AIMING
var current_color: int = 0
var next_color: int = 0

var viewport_size: Vector2 = Vector2.ZERO
var bubble_radius: float = 32.0
var bubble_diameter: float = 64.0
var row_height: float = 56.0
var board_left: float = 0.0
var board_right: float = 0.0
var board_top: float = 0.0
var lose_line_y: float = 0.0
var cannon_position: Vector2 = Vector2.ZERO
var shot_speed: float = 980.0
var max_rows_visible: int = 12
var visual_time: float = 0.0
var stack_visual_offset: float = 0.0
var stack_settle_velocity: float = 0.0
var row_arrival_flash: float = 0.0
var launcher_flash: float = 0.0
var launcher_recoil: float = 0.0
var mobile_low_fx: bool = false
var touch_aim_active: bool = false
var fps_update_timer: float = 0.0
var smoothed_frame_ms: float = 16.0


func _ready() -> void:
	rng.randomize()
	configure_runtime_profile()
	restart_button.pressed.connect(start_new_game)
	overlay_button.pressed.connect(start_new_game)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	style_ui()
	update_layout()
	start_new_game()


func _process(delta: float) -> void:
	var needs_redraw: bool = false
	var animating: bool = false
	if state == STATE_FLYING:
		update_active_bubble(delta)
		animating = true
		needs_redraw = true
	if launcher_flash > 0.0:
		launcher_flash = maxf(0.0, launcher_flash - delta * 7.2)
		animating = true
		needs_redraw = true
	if launcher_recoil > 0.0:
		launcher_recoil = maxf(0.0, launcher_recoil - delta * 8.8)
		animating = true
		needs_redraw = true
	if update_stack_animation(delta):
		animating = true
		needs_redraw = true
	if update_particles(delta):
		animating = true
		needs_redraw = true
	if update_hit_waves(delta):
		animating = true
		needs_redraw = true
	update_fps_display(delta)

	if not mobile_low_fx:
		visual_time += delta
		queue_redraw()
		return

	if animating:
		visual_time += delta
	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("061018"), true)
	draw_background_accents()
	draw_playfield()
	draw_lose_line()
	draw_bubbles()
	draw_particles()
	draw_launcher()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not mobile_low_fx:
		aim_target = event.position
		if state == STATE_AIMING:
			queue_redraw()
	elif event is InputEventScreenDrag:
		aim_target = event.position
		if state == STATE_AIMING:
			queue_redraw()
	elif event is InputEventMouseButton and not mobile_low_fx and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		aim_target = event.position
		if state == STATE_AIMING:
			fire_bubble()
	elif event is InputEventScreenTouch and event.pressed:
		aim_target = event.position
		touch_aim_active = true
		if state == STATE_AIMING:
			queue_redraw()
	elif event is InputEventScreenTouch and not event.pressed:
		aim_target = event.position
		var should_fire: bool = touch_aim_active and state == STATE_AIMING
		touch_aim_active = false
		if should_fire:
			fire_bubble()


func _on_viewport_size_changed() -> void:
	update_layout()


func configure_runtime_profile() -> void:
	var platform_name: String = OS.get_name()
	mobile_low_fx = platform_name == "Android" or platform_name == "iOS"
	if mobile_low_fx:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)


func update_fps_display(delta: float) -> void:
	smoothed_frame_ms = lerpf(smoothed_frame_ms, delta * 1000.0, 0.12)
	fps_update_timer += delta
	if fps_update_timer < 0.2:
		return
	fps_update_timer = 0.0
	var fps: int = Engine.get_frames_per_second()
	fps_label.text = "FPS: %d   Frame: %.1f ms" % [fps, smoothed_frame_ms]


func style_ui() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.11, 0.17, 0.82)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.55, 0.93, 0.99, 0.24)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	panel_style.shadow_size = 16
	panel_style.content_margin_left = 18
	panel_style.content_margin_top = 16
	panel_style.content_margin_right = 18
	panel_style.content_margin_bottom = 16
	hud_panel.add_theme_stylebox_override("panel", panel_style)

	var overlay_style: StyleBoxFlat = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.02, 0.08, 0.12, 0.92)
	overlay_style.border_width_left = 2
	overlay_style.border_width_top = 2
	overlay_style.border_width_right = 2
	overlay_style.border_width_bottom = 2
	overlay_style.border_color = Color(1.0, 0.86, 0.58, 0.28)
	overlay_style.corner_radius_top_left = 28
	overlay_style.corner_radius_top_right = 28
	overlay_style.corner_radius_bottom_right = 28
	overlay_style.corner_radius_bottom_left = 28
	overlay_style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	overlay_style.shadow_size = 22
	overlay_style.content_margin_left = 24
	overlay_style.content_margin_top = 22
	overlay_style.content_margin_right = 24
	overlay_style.content_margin_bottom = 22
	overlay_panel.add_theme_stylebox_override("panel", overlay_style)

	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("f7fbff"))
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color("d5f7ff"))
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("ffe9b5"))
	fps_label.add_theme_font_size_override("font_size", 15)
	fps_label.add_theme_color_override("font_color", Color("9fe8ff"))
	overlay_title.add_theme_font_size_override("font_size", 30)
	overlay_title.add_theme_color_override("font_color", Color("f7fbff"))
	overlay_message.add_theme_font_size_override("font_size", 18)
	overlay_message.add_theme_color_override("font_color", Color("d5f7ff"))

	style_button(restart_button, Color("0f3647"), Color("1d5c74"), Color("1d8192"))
	style_button(overlay_button, Color("5f4520"), Color("845e26"), Color("c98b34"))


func style_button(button: Button, base_color: Color, hover_color: Color, pressed_color: Color) -> void:
	var normal: StyleBoxFlat = make_button_style(base_color)
	var hover: StyleBoxFlat = make_button_style(hover_color)
	var pressed: StyleBoxFlat = make_button_style(pressed_color)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color("f7fbff"))
	button.add_theme_font_size_override("font_size", 17)
	button.custom_minimum_size = Vector2(0.0, 46.0)


func make_button_style(fill_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = fill_color.lightened(0.22)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


func update_layout() -> void:
	viewport_size = get_viewport_rect().size
	var target_width: float = viewport_size.x * 0.82
	bubble_radius = minf(36.0, target_width / float(GRID_COLUMNS * 2 + 1))
	bubble_diameter = bubble_radius * 2.0
	row_height = bubble_radius * 1.72
	var grid_width: float = bubble_diameter * GRID_COLUMNS + bubble_radius
	board_left = (viewport_size.x - grid_width) * 0.5
	board_right = board_left + grid_width
	board_top = viewport_size.y * 0.14
	cannon_position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.86)
	lose_line_y = cannon_position.y - bubble_radius * 2.8
	shot_speed = bubble_radius * 45.0
	max_rows_visible = maxi(10, int(floor((lose_line_y - board_top - bubble_radius) / row_height)))
	if aim_target == Vector2.ZERO:
		aim_target = cannon_position + Vector2.UP * 320.0
	generate_ambient_stars()
	sync_shot_planner()
	queue_redraw()


func sync_shot_planner() -> void:
	shot_planner.sync_layout(board, {
		"board_left": board_left,
		"board_right": board_right,
		"board_top": board_top,
		"bubble_radius": bubble_radius,
		"bubble_diameter": bubble_diameter,
		"row_height": row_height,
		"max_rows_visible": max_rows_visible,
		"start_rows": START_ROWS,
		"cannon_position": cannon_position,
		"stack_visual_offset": stack_visual_offset,
	})


func generate_ambient_stars() -> void:
	ambient_stars.clear()
	var star_density: float = 52000.0 if mobile_low_fx else 28000.0
	var min_stars: int = 12 if mobile_low_fx else 26
	var max_stars: int = 24 if mobile_low_fx else 64
	var star_count: int = clampi(int(viewport_size.x * viewport_size.y / star_density), min_stars, max_stars)
	for index in range(star_count):
		ambient_stars.append({
			"position": Vector2(rng.randf_range(0.0, viewport_size.x), rng.randf_range(0.0, viewport_size.y)),
			"radius": rng.randf_range(0.8, 2.3),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.2, 1.1),
			"alpha": rng.randf_range(0.14, 0.55),
			"lane": float(index % 3),
		})


func start_new_game() -> void:
	board.start_new_game(rng)
	active_bubble.clear()
	pop_particles.clear()
	hit_waves.clear()
	stack_visual_offset = 0.0
	stack_settle_velocity = 0.0
	row_arrival_flash = 0.0
	overlay.visible = false
	state = STATE_AIMING
	kick_stack_drop(row_height * 0.58, true)
	current_color = board.pick_shoot_color(rng)
	next_color = board.pick_shoot_color(rng)
	refresh_hud()
	queue_redraw()


func fire_bubble() -> void:
	if state != STATE_AIMING:
		return
	sync_shot_planner()
	var direction: Vector2 = shot_planner.apply_fire_assist(clamped_aim_direction())
	var shot_plan: Dictionary = shot_planner.simulate_shot_path(direction)
	var impact_type: String = shot_plan["impact_type"]
	var path_points: Array[Vector2] = shot_plan["points"]
	var bounce_indices: Array[int] = shot_plan["bounce_indices"]
	if impact_type == "none" or path_points.size() < 2:
		return
	active_bubble = {
		"position": cannon_position,
		"color": current_color,
		"path_points": path_points,
		"path_index": 1,
		"bounce_indices": bounce_indices,
		"snap_cell": shot_plan["snap_cell"],
		"hit_ceiling": impact_type == "ceiling",
		"impact_type": impact_type,
		"impact_position": shot_plan["impact_position"],
		"travel_distance": 0.0,
		"travel_total_distance": shot_planner.path_total_length(path_points),
		"launch_age": 0.0,
	}
	state = STATE_FLYING
	launcher_flash = 1.0
	launcher_recoil = 1.0
	queue_redraw()


func update_active_bubble(delta: float) -> void:
	var position: Vector2 = active_bubble["position"]
	var path_points: Array[Vector2] = active_bubble["path_points"]
	var bounce_indices: Array[int] = active_bubble["bounce_indices"]
	var path_index: int = active_bubble["path_index"]
	var travel_distance: float = active_bubble["travel_distance"]
	var travel_total_distance: float = maxf(float(active_bubble["travel_total_distance"]), 1.0)
	var launch_age: float = active_bubble["launch_age"] + delta
	var speed_multiplier: float = shot_speed_multiplier(travel_distance / travel_total_distance)
	var remaining_distance: float = shot_speed * speed_multiplier * delta

	while remaining_distance > 0.0 and path_index < path_points.size():
		var target: Vector2 = path_points[path_index]
		var to_target: Vector2 = target - position
		var distance_to_target: float = to_target.length()
		if distance_to_target <= 0.001:
			position = target
			if bounce_indices.has(path_index):
				spawn_bounce_spark(position)
			path_index += 1
			continue

		if remaining_distance < distance_to_target:
			position += to_target / distance_to_target * remaining_distance
			travel_distance += remaining_distance
			remaining_distance = 0.0
			break

		position = target
		travel_distance += distance_to_target
		remaining_distance -= distance_to_target
		if bounce_indices.has(path_index):
			spawn_bounce_spark(position)
		path_index += 1

	active_bubble["position"] = position
	active_bubble["path_index"] = path_index
	active_bubble["travel_distance"] = travel_distance
	active_bubble["launch_age"] = launch_age

	if path_index >= path_points.size():
		var snap_cell: Vector2i = active_bubble["snap_cell"]
		var hit_ceiling: bool = active_bubble["hit_ceiling"]
		place_active_bubble(Vector2i(-1, -1), hit_ceiling, snap_cell)


func spawn_bounce_spark(position: Vector2) -> void:
	var center_offset: Vector2 = position - Vector2((board_left + board_right) * 0.5, position.y)
	if center_offset.x <= 0.0:
		spawn_spark(position + Vector2.RIGHT * bubble_radius * 0.15, COLORS[int(active_bubble["color"])], Vector2.RIGHT * 110.0)
	else:
		spawn_spark(position + Vector2.LEFT * bubble_radius * 0.15, COLORS[int(active_bubble["color"])], Vector2.LEFT * 110.0)


func place_active_bubble(anchor_cell: Vector2i, hit_ceiling: bool, forced_snap: Vector2i = Vector2i(-1, -1)) -> void:
	var snap: Vector2i = forced_snap
	if snap == Vector2i(-1, -1):
		sync_shot_planner()
		snap = shot_planner.find_best_snap_cell(active_bubble["position"], anchor_cell, hit_ceiling)
	var impact_type: String = active_bubble["impact_type"]
	var snap_center: Vector2 = cell_to_world(snap.x, snap.y)
	spawn_pop_burst(cell_to_world(snap.x, snap.y), COLORS[int(active_bubble["color"])].lightened(0.18), 5, bubble_radius * 0.16)
	if impact_type == "stack":
		spawn_hit_wave(snap_center, 1.25)
		spawn_stack_impact_sparks(snap_center, COLORS[int(active_bubble["color"])])
	var resolution: Dictionary = board.resolve_placed_bubble(snap, int(active_bubble["color"]), rng)
	spawn_resolution_effects(resolution)
	active_bubble.clear()
	state = STATE_AIMING

	if resolution["board_cleared"]:
		kick_stack_drop(row_height * 0.58, true)
		current_color = board.pick_shoot_color(rng)
		next_color = board.pick_shoot_color(rng)
		refresh_hud()
		return

	if resolution["row_pushed"]:
		kick_stack_drop(row_height * 0.92, false)

	if check_loss_condition():
		return

	current_color = next_color
	next_color = board.pick_shoot_color(rng)
	refresh_hud()


func spawn_resolution_effects(resolution: Dictionary) -> void:
	var burst_row_parity_offset: int = resolution["burst_row_parity_offset"]
	for burst in resolution["cluster_bursts"]:
		var cluster_cell: Vector2i = burst["cell"]
		var cluster_color: int = burst["color"]
		spawn_pop_burst(cell_to_world_with_parity(cluster_cell.x, cluster_cell.y, burst_row_parity_offset), COLORS[cluster_color], 10, bubble_radius * 0.28)

	for burst in resolution["floating_bursts"]:
		var floating_cell: Vector2i = burst["cell"]
		var floating_color: int = burst["color"]
		spawn_pop_burst(cell_to_world_with_parity(floating_cell.x, floating_cell.y, burst_row_parity_offset), COLORS[floating_color].darkened(0.05), 8, bubble_radius * 0.22)


func check_loss_condition() -> bool:
	var deepest_y: float = board_top
	for row in range(grid.size()):
		for col in range(GRID_COLUMNS):
			if grid[row][col] == BubbleBoardState.EMPTY_CELL:
				continue
			deepest_y = maxf(deepest_y, cell_to_logic_world(row, col).y)

	if deepest_y + bubble_radius >= lose_line_y:
		end_game("The stack crossed the warning line.")
		return true

	return false


func end_game(message: String) -> void:
	state = STATE_GAME_OVER
	active_bubble.clear()
	overlay.visible = true
	overlay_title.text = "Game Over"
	overlay_message.text = "%s\nFinal score: %d" % [message, board.score]
	board.status_message = message
	refresh_hud()
	queue_redraw()


func refresh_hud() -> void:
	score_label.text = "Score: %d    Wave: %d" % [board.score, board.wave]
	status_label.text = "%s  Row in %d shots." % [board.status_message, board.shots_until_shift]


func row_shift_parity(row: int) -> int:
	return board.row_shift_parity(row)


func cell_occupied(row: int, col: int) -> bool:
	return board.cell_occupied(row, col)


func cell_to_world(row: int, col: int) -> Vector2:
	return cell_to_world_with_parity(row, col, board.row_parity_offset)


func cell_to_world_with_parity(row: int, col: int, parity_offset: int) -> Vector2:
	return Vector2(
		board_left + bubble_radius + float(col) * bubble_diameter + float((row + parity_offset) % 2) * bubble_radius,
		board_top + bubble_radius + float(row) * row_height + stack_visual_offset
	)


func cell_to_logic_world(row: int, col: int) -> Vector2:
	return Vector2(
		board_left + bubble_radius + float(col) * bubble_diameter + float(row_shift_parity(row)) * bubble_radius,
		board_top + bubble_radius + float(row) * row_height
	)


func shot_speed_multiplier(progress: float) -> float:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	return lerpf(SHOT_SPEED_BURST_MULTIPLIER, SHOT_SPEED_FINISH_MULTIPLIER, pow(clamped_progress, 0.82))


func current_shot_direction() -> Vector2:
	if active_bubble.is_empty():
		return Vector2.UP
	var path_points: Array[Vector2] = active_bubble["path_points"]
	var path_index: int = active_bubble["path_index"]
	var position: Vector2 = active_bubble["position"]
	if path_index < path_points.size():
		var next_point: Vector2 = path_points[path_index]
		var to_next: Vector2 = next_point - position
		if to_next.length_squared() > 0.0001:
			return to_next.normalized()
	if path_index > 0 and path_index - 1 < path_points.size():
		var prev_point: Vector2 = path_points[path_index - 1]
		var from_prev: Vector2 = position - prev_point
		if from_prev.length_squared() > 0.0001:
			return from_prev.normalized()
	return Vector2.UP


func aim_pullback_distance() -> float:
	if state != STATE_AIMING:
		return 0.0
	var pull_ratio: float = clampf(cannon_position.distance_to(aim_target) / (viewport_size.y * 0.42), 0.0, 1.0)
	return bubble_radius * (0.18 + pull_ratio * 0.62)


func clamped_aim_direction() -> Vector2:
	var direction: Vector2 = aim_target - cannon_position
	if direction.length_squared() < 0.0001:
		direction = Vector2.UP
	var angle: float = atan2(direction.y, direction.x)
	angle = clamp(angle, deg_to_rad(-162.0), deg_to_rad(-18.0))
	var center_angle: float = -PI * 0.5
	var angle_step: float = deg_to_rad(1.6)
	sync_shot_planner()
	for _index in range(24):
		var candidate_direction: Vector2 = Vector2(cos(angle), sin(angle)).normalized()
		if not shot_planner.first_wall_bounce_too_low(candidate_direction):
			return candidate_direction
		if angle < center_angle:
			angle += angle_step
		else:
			angle -= angle_step
	return Vector2(cos(angle), sin(angle)).normalized()


func update_stack_animation(delta: float) -> bool:
	var animated: bool = false
	if state != STATE_FLYING and (absf(stack_visual_offset) > 0.02 or absf(stack_settle_velocity) > 0.02):
		var spring_strength: float = 54.0 if mobile_low_fx else 38.0
		var damping_strength: float = 13.5 if mobile_low_fx else 10.5
		var spring_force: float = -stack_visual_offset * spring_strength
		var damping_force: float = -stack_settle_velocity * damping_strength
		stack_settle_velocity += (spring_force + damping_force) * delta
		stack_visual_offset += stack_settle_velocity * delta
		animated = true
		var settle_offset_cutoff: float = 0.2 if mobile_low_fx else 0.12
		var settle_velocity_cutoff: float = 3.0 if mobile_low_fx else 2.0
		if absf(stack_visual_offset) < settle_offset_cutoff and absf(stack_settle_velocity) < settle_velocity_cutoff:
			stack_visual_offset = 0.0
			stack_settle_velocity = 0.0

	if row_arrival_flash > 0.0:
		row_arrival_flash = maxf(0.0, row_arrival_flash - delta * 2.2)
		animated = true

	if animated:
		sync_shot_planner()

	return animated


func kick_stack_drop(strength: float, gentle: bool) -> void:
	if mobile_low_fx:
		var mobile_strength: float = minf(strength, row_height * 0.62)
		stack_visual_offset = maxf(stack_visual_offset - mobile_strength, -row_height * 0.78)
		if gentle:
			stack_settle_velocity = minf(stack_settle_velocity, -row_height * 0.55)
			row_arrival_flash = maxf(row_arrival_flash, 0.22)
		else:
			stack_settle_velocity = minf(stack_settle_velocity, -row_height * 0.78)
			row_arrival_flash = 0.34
		sync_shot_planner()
		return

	var capped_strength: float = minf(strength, row_height * 1.2)
	stack_visual_offset = maxf(stack_visual_offset - capped_strength, -row_height * 1.35)
	if gentle:
		stack_settle_velocity = minf(stack_settle_velocity, -row_height * 0.8)
		row_arrival_flash = maxf(row_arrival_flash, 0.5)
	else:
		stack_settle_velocity = minf(stack_settle_velocity, -row_height * 1.2)
		row_arrival_flash = 1.0
		spawn_ceiling_entry_fx()
	sync_shot_planner()


func spawn_ceiling_entry_fx() -> void:
	if mobile_low_fx:
		return
	for col in range(GRID_COLUMNS):
		if not cell_occupied(0, col):
			continue
		if rng.randf() > 0.7 and col != 0 and col != GRID_COLUMNS - 1:
			continue
		var center: Vector2 = cell_to_logic_world(0, col)
		spawn_pop_burst(center, COLORS[int(grid[0][col])].lightened(0.2), 4, bubble_radius * 0.14)


func update_particles(delta: float) -> bool:
	if pop_particles.is_empty():
		return false

	var survivors: Array[Dictionary] = []
	for particle in pop_particles:
		var remaining: float = particle["life"] - delta
		if remaining <= 0.0:
			continue
		var position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		position += velocity * delta
		velocity *= 0.96
		velocity.y += 320.0 * delta
		particle["life"] = remaining
		particle["position"] = position
		particle["velocity"] = velocity
		survivors.append(particle)

	pop_particles = survivors
	return true


func update_hit_waves(delta: float) -> bool:
	if hit_waves.is_empty():
		return false

	var survivors: Array[Dictionary] = []
	for wave in hit_waves:
		var age: float = wave["age"] + delta
		var duration: float = wave["duration"]
		if age >= duration:
			continue
		wave["age"] = age
		survivors.append(wave)

	hit_waves = survivors
	return true


func spawn_hit_wave(origin: Vector2, strength: float) -> void:
	var durations: Array[float] = []
	var delays: Array[float] = []
	var strengths: Array[float] = []
	if mobile_low_fx:
		durations.append(0.48)
		durations.append(0.66)
		delays.append(0.0)
		delays.append(0.05)
		strengths.append(strength)
		strengths.append(strength * 0.82)
	else:
		durations.append(0.62)
		durations.append(0.82)
		durations.append(1.0)
		delays.append(0.0)
		delays.append(0.04)
		delays.append(0.09)
		strengths.append(strength)
		strengths.append(strength * 0.92)
		strengths.append(strength * 0.68)
	for index in range(durations.size()):
		var wave_speed: float = bubble_radius * (15.0 + float(index) * 2.8)
		var wave_width: float = bubble_radius * (2.2 + float(index) * 0.45)
		if not mobile_low_fx:
			wave_speed = bubble_radius * (11.5 + float(index) * 2.0)
			wave_width = bubble_radius * (3.8 + float(index) * 0.8)
		hit_waves.append({
			"origin": origin,
			"age": -delays[index],
			"duration": durations[index],
			"speed": wave_speed,
			"width": wave_width,
			"strength": strengths[index],
		})
	while hit_waves.size() > MAX_HIT_WAVES:
		hit_waves.remove_at(0)


func get_hit_wave_transform(center: Vector2) -> Dictionary:
	var total_offset: Vector2 = Vector2.ZERO
	var total_scale: float = 1.0
	var total_glow: float = 0.0

	for wave in hit_waves:
		var origin: Vector2 = wave["origin"]
		var age: float = wave["age"]
		if age <= 0.0:
			continue
		var duration: float = wave["duration"]
		var strength: float = wave["strength"]
		var to_center: Vector2 = center - origin
		var distance: float = to_center.length()
		var travel_speed: float = wave["speed"]
		var max_radius: float = bubble_diameter * 2.7
		if distance > max_radius:
			continue

		var arrival_time: float = distance / maxf(travel_speed, 1.0)
		var local_time: float = age - arrival_time
		var blast_time: float = age - arrival_time * 0.35
		if local_time <= -0.02 and blast_time <= 0.0:
			continue

		var distance_fade: float = maxf(0.0, 1.0 - distance / max_radius)
		distance_fade = distance_fade * distance_fade
		var oscillation: float = 0.0
		if local_time > 0.0:
			var oscillation_window: float = 0.26 if mobile_low_fx else 0.34
			if local_time < oscillation_window:
				var oscillation_phase: float = local_time / oscillation_window
				var pulse_count: float = 2.6 if mobile_low_fx else 3.2
				oscillation = maxf(0.0, sin(oscillation_phase * PI * pulse_count)) * pow(1.0 - oscillation_phase, 1.7)
		var blast: float = 0.0
		if blast_time > 0.0:
			blast = exp(-blast_time * 11.0)
		var amplitude: float = (absf(oscillation) * 0.62 + blast * 0.48) * distance_fade * strength
		if amplitude <= 0.001:
			continue

		var direction: Vector2 = Vector2.ZERO if distance <= 0.001 else to_center / distance
		total_offset += direction * bubble_radius * (0.18 * amplitude)
		total_scale += 0.16 * amplitude
		total_glow += 0.62 * amplitude

	return {
		"offset": total_offset,
		"scale": total_scale,
		"glow": total_glow,
	}


func spawn_stack_impact_sparks(center: Vector2, bubble_color: Color) -> void:
	var spark_count: int = 10 if mobile_low_fx else 16
	for index in range(spark_count):
		var angle: float = TAU * float(index) / float(spark_count) + rng.randf_range(-0.22, 0.22)
		var push: Vector2 = Vector2.RIGHT.rotated(angle) * rng.randf_range(120.0, 220.0)
		spawn_spark(center + push.normalized() * bubble_radius * 0.14, bubble_color.lightened(0.18), push)


func spawn_pop_burst(center: Vector2, bubble_color: Color, count: int, size_scale: float) -> void:
	for _index in range(count):
		var angle: float = rng.randf_range(0.0, TAU)
		var speed: float = rng.randf_range(bubble_radius * 3.6, bubble_radius * 7.4)
		var life: float = rng.randf_range(0.22, 0.5)
		var particle_color: Color = bubble_color.lerp(Color(1.0, 1.0, 1.0, 1.0), rng.randf_range(0.1, 0.35))
		pop_particles.append({
			"position": center,
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"life": life,
			"max_life": life,
			"size": size_scale * rng.randf_range(0.8, 1.5),
			"color": particle_color,
		})
	trim_particles()


func spawn_spark(center: Vector2, spark_color: Color, push: Vector2) -> void:
	var particle_color: Color = spark_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.4)
	pop_particles.append({
		"position": center,
		"velocity": push + Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(-80.0, 40.0)),
		"life": 0.16,
		"max_life": 0.16,
		"size": bubble_radius * 0.16,
		"color": particle_color,
	})
	trim_particles()


func trim_particles() -> void:
	var limit: int = MAX_PARTICLES_MOBILE if mobile_low_fx else MAX_PARTICLES_DESKTOP
	while pop_particles.size() > limit:
		pop_particles.remove_at(0)


func draw_background_accents() -> void:
	var glow_a: Vector2 = Vector2(
		viewport_size.x * (0.16 + sin(visual_time * 0.32) * 0.04),
		viewport_size.y * (0.18 + cos(visual_time * 0.27) * 0.03)
	)
	var glow_b: Vector2 = Vector2(
		viewport_size.x * (0.83 + cos(visual_time * 0.21) * 0.03),
		viewport_size.y * (0.78 + sin(visual_time * 0.24) * 0.02)
	)
	var glow_c: Vector2 = Vector2(
		viewport_size.x * 0.52,
		viewport_size.y * (0.48 + sin(visual_time * 0.18) * 0.03)
	)
	if mobile_low_fx:
		draw_circle(glow_a, viewport_size.x * 0.24, Color(0.08, 0.68, 0.75, 0.08))
		draw_circle(glow_b, viewport_size.x * 0.2, Color(0.99, 0.72, 0.34, 0.07))
	else:
		draw_circle(glow_a, viewport_size.x * 0.34, Color(0.08, 0.68, 0.75, 0.12))
		draw_circle(glow_b, viewport_size.x * 0.28, Color(0.99, 0.72, 0.34, 0.1))
		draw_circle(glow_c, viewport_size.x * 0.38, Color(0.12, 0.28, 0.5, 0.12))

	for star in ambient_stars:
		var base_position: Vector2 = star["position"]
		var phase: float = star["phase"]
		var radius: float = star["radius"]
		var alpha: float = star["alpha"]
		var draw_position: Vector2 = base_position
		var twinkle: float = 1.0
		if not mobile_low_fx:
			var speed: float = star["speed"]
			var lane: float = star["lane"]
			twinkle = 0.45 + 0.55 * abs(sin(visual_time * speed + phase))
			var drift: Vector2 = Vector2(sin(visual_time * 0.2 + phase) * (5.0 + lane * 2.0), cos(visual_time * 0.18 + phase) * (3.0 + lane))
			draw_position = base_position + drift
		var star_color: Color = Color(1.0, 1.0, 1.0, alpha * twinkle)
		draw_circle(draw_position, radius, star_color)
		if not mobile_low_fx:
			draw_circle(draw_position, radius * 2.4, Color(0.68, 0.93, 0.99, alpha * 0.12 * twinkle))

	if not mobile_low_fx:
		for index in range(4):
			var ring_radius: float = viewport_size.x * (0.18 + float(index) * 0.075)
			draw_arc(
				Vector2(viewport_size.x * 0.18, viewport_size.y * 0.11),
				ring_radius,
				PI * 0.12,
				PI * 0.96,
				72,
				Color(0.39, 0.83, 0.9, 0.08),
				3.0,
				true
			)


func draw_playfield() -> void:
	var frame_rect: Rect2 = get_playfield_rect()
	draw_rect(Rect2(frame_rect.position + Vector2(0.0, bubble_radius * 0.22), frame_rect.size), Color(0.0, 0.0, 0.0, 0.18), true)
	draw_rect(frame_rect, Color(0.03, 0.12, 0.18, 0.78), true)

	if row_arrival_flash > 0.0:
		var entry_rect: Rect2 = Rect2(
			Vector2(frame_rect.position.x + bubble_radius * 0.08, board_top - bubble_radius * 0.55 + stack_visual_offset),
			Vector2(frame_rect.size.x - bubble_radius * 0.16, row_height * 1.1)
		)
		draw_rect(entry_rect, Color(0.72, 0.97, 1.0, 0.12 * row_arrival_flash), true)
		draw_line(
			Vector2(entry_rect.position.x, entry_rect.position.y + bubble_radius * 0.22),
			Vector2(entry_rect.end.x, entry_rect.position.y + bubble_radius * 0.22),
			Color(1.0, 1.0, 1.0, 0.28 * row_arrival_flash),
			3.0
		)

	var band_count: int = 5 if mobile_low_fx else 9
	for band in range(band_count):
		var top: float = frame_rect.position.y + frame_rect.size.y * float(band) / float(band_count)
		var alpha: float = 0.055 - float(band) * 0.004
		draw_rect(
			Rect2(Vector2(frame_rect.position.x, top), Vector2(frame_rect.size.x, frame_rect.size.y / float(band_count) + 2.0)),
			Color(0.12, 0.35, 0.46, maxf(alpha, 0.01)),
			true
		)

	if not mobile_low_fx:
		for streak in range(8):
			var offset: float = fmod(visual_time * 70.0 + float(streak) * bubble_radius * 2.7, frame_rect.size.x + frame_rect.size.y)
			var from_point: Vector2 = Vector2(frame_rect.position.x + offset - frame_rect.size.y, frame_rect.position.y)
			var to_point: Vector2 = from_point + Vector2(frame_rect.size.y * 0.8, frame_rect.size.y * 0.8)
			draw_line(from_point, to_point, Color(0.8, 0.97, 1.0, 0.035), 2.0)

	draw_rect(frame_rect, Color(0.56, 0.95, 0.99, 0.22), false, 3.0)
	draw_line(
		Vector2(frame_rect.position.x + bubble_radius * 0.2, frame_rect.position.y + bubble_radius * 0.25),
		Vector2(frame_rect.end.x - bubble_radius * 0.2, frame_rect.position.y + bubble_radius * 0.25),
		Color(1.0, 1.0, 1.0, 0.18),
		3.0
	)

	var rows_to_draw: int = mini(grid.size() + 2, max_rows_visible)
	for row in range(rows_to_draw):
		for col in range(GRID_COLUMNS):
			if cell_occupied(row, col):
				continue
			var cell_center: Vector2 = cell_to_world(row, col)
			if cell_center.y >= lose_line_y - bubble_radius * 0.4:
				continue
			draw_circle(cell_center, bubble_radius * 0.12, Color(0.77, 0.96, 0.99, 0.08))
			if not mobile_low_fx:
				draw_arc(cell_center, bubble_radius * 0.34, 0.0, TAU, 18, Color(0.77, 0.96, 0.99, 0.045), 1.2, true)


func draw_lose_line() -> void:
	var step: float = bubble_radius * 1.12
	var start_x: float = board_left
	while start_x < board_right:
		var end_x: float = minf(start_x + bubble_radius * 0.74, board_right)
		draw_line(Vector2(start_x, lose_line_y), Vector2(end_x, lose_line_y), Color(1.0, 0.42, 0.48, 0.9), 4.0)
		start_x += step
	draw_line(Vector2(board_left, lose_line_y), Vector2(board_right, lose_line_y), Color(1.0, 0.74, 0.78, 0.12), 9.0)


func draw_bubbles() -> void:
	var rows_to_draw: int = mini(grid.size(), max_rows_visible + 1)
	for row in range(rows_to_draw):
		for col in range(GRID_COLUMNS):
			if grid[row][col] == BubbleBoardState.EMPTY_CELL:
				continue
			var bubble_center: Vector2 = cell_to_world(row, col)
			if bubble_center.y > lose_line_y + bubble_radius:
				continue
			var wave_transform: Dictionary = get_hit_wave_transform(bubble_center)
			var transformed_center: Vector2 = bubble_center + wave_transform["offset"]
			var row_glow: float = 1.0
			var row_radius: float = bubble_radius
			if row == 0 and row_arrival_flash > 0.0:
				row_glow += row_arrival_flash * 0.7
				row_radius *= 1.0 + row_arrival_flash * 0.06
			row_glow += wave_transform["glow"]
			row_radius *= wave_transform["scale"]
			draw_bubble(transformed_center, COLORS[int(grid[row][col])], row_radius, row_glow)

	if not active_bubble.is_empty():
		draw_flying_bubble(
			active_bubble["position"],
			COLORS[int(active_bubble["color"])],
			current_shot_direction(),
			float(active_bubble["launch_age"])
		)


func draw_particles() -> void:
	for particle in pop_particles:
		var color: Color = particle["color"]
		var remaining: float = particle["life"]
		var max_life: float = particle["max_life"]
		var life_ratio: float = remaining / max_life
		var position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		var size: float = particle["size"] * life_ratio
		var faded: Color = color
		faded.a *= life_ratio
		draw_circle(position, maxf(size, 1.2), faded)
		if velocity.length_squared() > 2.0:
			var trail_end: Vector2 = position - velocity.normalized() * size * 2.2
			draw_line(position, trail_end, Color(faded.r, faded.g, faded.b, faded.a * 0.6), maxf(size * 0.9, 1.0))


func draw_flying_bubble(center: Vector2, bubble_color: Color, direction: Vector2, launch_age: float) -> void:
	var normalized_direction: Vector2 = direction.normalized()
	var launch_burst: float = exp(-launch_age * 8.5)
	var trail_length: float = bubble_radius * (1.6 + launch_burst * 4.2)
	var trail_end: Vector2 = center - normalized_direction * trail_length
	var trail_alpha: float = 0.16 + launch_burst * 0.32
	draw_line(trail_end, center, Color(bubble_color.r, bubble_color.g, bubble_color.b, trail_alpha), bubble_radius * (0.28 + launch_burst * 0.18))
	draw_circle(trail_end, bubble_radius * (0.34 + launch_burst * 0.1), Color(bubble_color.r, bubble_color.g, bubble_color.b, 0.08 + launch_burst * 0.08))
	var smear_count: int = 3 if mobile_low_fx else 4
	for index in range(smear_count):
		var t: float = float(index + 1) / float(smear_count + 1)
		var sample_center: Vector2 = center - normalized_direction * trail_length * t * 0.72
		var sample_alpha: float = (1.0 - t) * (0.09 + launch_burst * 0.16)
		draw_circle(sample_center, bubble_radius * (0.62 - t * 0.12), Color(bubble_color.r, bubble_color.g, bubble_color.b, sample_alpha))
	var head_offset: Vector2 = normalized_direction * bubble_radius * launch_burst * 0.22
	draw_bubble(center + head_offset, bubble_color, bubble_radius * (1.0 + launch_burst * 0.08), 1.5 + launch_burst * 0.85)


func draw_launcher() -> void:
	var aim_direction: Vector2 = clamped_aim_direction()
	draw_aim_guide(aim_direction)
	var recoil_offset: Vector2 = -aim_direction * bubble_radius * 0.22 * launcher_recoil
	var launcher_center: Vector2 = cannon_position + recoil_offset
	var pullback: float = aim_pullback_distance()
	var loaded_center: Vector2 = launcher_center - aim_direction * pullback

	var socket_shadow: Color = Color(0.0, 0.0, 0.0, 0.25)
	draw_circle(launcher_center + Vector2(0.0, bubble_radius * 0.26), bubble_radius * 1.18, socket_shadow)
	if launcher_flash > 0.0:
		var flash_alpha: float = launcher_flash * (0.32 if mobile_low_fx else 0.45)
		draw_circle(launcher_center, bubble_radius * (1.42 + launcher_flash * 0.22), Color(1.0, 0.95, 0.82, flash_alpha))
		draw_line(
			launcher_center,
			launcher_center + aim_direction * bubble_radius * (1.2 + launcher_flash * 1.4),
			Color(1.0, 0.9, 0.72, flash_alpha * 0.9),
			bubble_radius * (0.42 + launcher_flash * 0.18)
		)
		if not mobile_low_fx:
			draw_line(
				launcher_center,
				launcher_center + aim_direction * bubble_radius * (2.0 + launcher_flash * 2.0),
				Color(1.0, 0.98, 0.9, flash_alpha * 0.28),
				bubble_radius * (0.7 + launcher_flash * 0.2)
			)
	draw_line(
		launcher_center,
		launcher_center + aim_direction * bubble_radius * 2.6,
		Color(0.96, 0.99, 1.0, 0.95),
		bubble_radius * 0.45
	)
	draw_circle(launcher_center, bubble_radius * 1.06, Color(0.14, 0.29, 0.39, 0.95))
	draw_circle(launcher_center, bubble_radius * 0.74, Color(0.78, 0.9, 0.96, 0.22))
	if state == STATE_AIMING and pullback > 0.0:
		draw_line(loaded_center, launcher_center, Color(1.0, 0.94, 0.82, 0.2), bubble_radius * 0.26)
		draw_line(loaded_center, launcher_center, Color(0.78, 0.95, 1.0, 0.16), bubble_radius * 0.12)

	if state == STATE_AIMING:
		draw_bubble(loaded_center, COLORS[current_color], bubble_radius * 1.02, 1.32)

	var next_center: Vector2 = cannon_position + Vector2(bubble_radius * 2.7, bubble_radius * 1.15)
	draw_bubble(next_center, COLORS[next_color], bubble_radius * 0.68, 0.85)
	draw_circle(next_center, bubble_radius * 0.8, Color(0.78, 0.9, 0.96, 0.16))


func trace_aim_path(direction: Vector2) -> Array[Vector2]:
	sync_shot_planner()
	return shot_planner.trace_aim_path(direction)


func draw_aim_guide(direction: Vector2) -> void:
	if state != STATE_AIMING:
		return

	var points: Array[Vector2] = trace_aim_path(direction)
	if points.size() < 2:
		return

	for index in range(points.size() - 1):
		var from_point: Vector2 = points[index]
		var to_point: Vector2 = points[index + 1]
		var ratio: float = 1.0 - float(index) / float(maxi(points.size() - 1, 1))
		draw_line(from_point, to_point, Color(0.58, 0.93, 1.0, 0.08 * ratio), maxf(bubble_radius * 0.28 * ratio, 2.2))
		draw_line(from_point, to_point, Color(1.0, 1.0, 1.0, 0.16 * ratio), maxf(bubble_radius * 0.1 * ratio, 1.1))

	for index in range(1, points.size()):
		var point: Vector2 = points[index]
		var ratio: float = 1.0 - float(index - 1) / float(maxi(points.size() - 1, 1))
		draw_circle(point, maxf(3.2, bubble_radius * 0.17 * ratio), Color(0.79, 0.96, 1.0, 0.16 * ratio))
		draw_circle(point, maxf(2.1, bubble_radius * 0.1 * ratio), Color(1.0, 1.0, 1.0, 0.58 * ratio))

	var impact_point: Vector2 = points[points.size() - 1]
	draw_circle(impact_point, bubble_radius * 0.34, Color(0.79, 0.96, 1.0, 0.08))
	if not mobile_low_fx:
		draw_arc(impact_point, bubble_radius * 0.46, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.22), 2.0, true)


func draw_bubble(center: Vector2, bubble_color: Color, radius: float, glow_strength: float) -> void:
	var pulse: float = 1.0
	if not mobile_low_fx:
		pulse = 1.0 + sin(visual_time * 2.4 + center.x * 0.018 + center.y * 0.011) * 0.028
	var animated_radius: float = radius * pulse
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.26)
	var glow_color: Color = bubble_color
	glow_color.a = 0.11 * glow_strength
	if mobile_low_fx:
		draw_circle(center, animated_radius * 1.12, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.72))
		draw_circle(center + Vector2(0.0, animated_radius * 0.12), animated_radius * 1.01, shadow_color)
		draw_circle(center, animated_radius, bubble_color.darkened(0.06))
		draw_circle(center + Vector2(-animated_radius * 0.12, -animated_radius * 0.14), animated_radius * 0.62, bubble_color.lightened(0.18))
		draw_circle(center + Vector2(-animated_radius * 0.24, -animated_radius * 0.26), animated_radius * 0.2, Color(1.0, 1.0, 1.0, 0.3))
		return

	draw_circle(center, animated_radius * (1.28 + glow_strength * 0.05), glow_color)
	draw_circle(center + Vector2(0.0, animated_radius * 0.16), animated_radius * 1.04, shadow_color)

	draw_circle(center, animated_radius, bubble_color.darkened(0.08))
	draw_circle(center + Vector2(-animated_radius * 0.1, -animated_radius * 0.12), animated_radius * 0.82, bubble_color.lightened(0.14))
	draw_circle(center + Vector2(-animated_radius * 0.18, -animated_radius * 0.2), animated_radius * 0.56, bubble_color.lightened(0.25))
	draw_circle(center + Vector2(-animated_radius * 0.26, -animated_radius * 0.28), animated_radius * 0.24, Color(1.0, 1.0, 1.0, 0.34))
	draw_circle(center + Vector2(animated_radius * 0.22, animated_radius * 0.24), animated_radius * 0.38, Color(0.0, 0.0, 0.0, 0.08))

	draw_arc(center, animated_radius * 0.95, deg_to_rad(215.0), deg_to_rad(340.0), 32, bubble_color.darkened(0.45), maxf(2.0, animated_radius * 0.11), true)
	draw_arc(center, animated_radius * 0.82, deg_to_rad(22.0), deg_to_rad(150.0), 24, Color(1.0, 1.0, 1.0, 0.18), maxf(1.6, animated_radius * 0.08), true)
	draw_circle(center + Vector2(-animated_radius * 0.06, -animated_radius * 0.08), animated_radius * 0.08, Color(1.0, 1.0, 1.0, 0.18))


func get_playfield_rect() -> Rect2:
	return Rect2(
		Vector2(board_left - bubble_radius * 0.65, board_top - bubble_radius * 0.65),
		Vector2(board_right - board_left + bubble_radius * 1.3, lose_line_y - board_top + bubble_radius * 0.6)
	)
