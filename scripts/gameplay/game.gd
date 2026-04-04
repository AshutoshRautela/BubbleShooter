extends Node2D

const GRID_COLUMNS := 9
const SHOT_SPEED_BURST_MULTIPLIER := 2.7
const SHOT_SPEED_FINISH_MULTIPLIER := 1.15
const STATE_AIMING := "aiming"
const STATE_FLYING := "flying"
const STATE_RESOLVING := "resolving"
const STATE_GAME_OVER := "game_over"
const OVERLAY_NONE := "none"
const OVERLAY_PAUSE := "pause"
const OVERLAY_GAME_OVER := "game_over"

const COLORS: Array[Color] = [
	Color("ff6b6b"),
	Color("ffd166"),
	Color("4ecdc4"),
	Color("5dade2"),
	Color("a78bfa"),
	Color("95e06c"),
]
const BUBBLE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/bubbles/png/bubble_red_256px.png"),
	preload("res://assets/bubbles/png/bubble_yellow_256px.png"),
	preload("res://assets/bubbles/png/bubble_teal_256px.png"),
	preload("res://assets/bubbles/png/bubble_blue_256px.png"),
	preload("res://assets/bubbles/png/bubble_purple_256px.png"),
	preload("res://assets/bubbles/png/bubble_green_256px.png"),
]

@onready var hud_panel: PanelContainer = $UI/Hud/Panel
@onready var title_label: Label = $UI/Hud/Panel/VBox/TitleLabel
@onready var score_label: Label = $UI/Hud/Panel/VBox/ScoreLabel
@onready var status_label: Label = $UI/Hud/Panel/VBox/StatusLabel
@onready var fps_label: Label = $UI/Hud/Panel/VBox/FpsLabel
@onready var pause_button: Button = $UI/Hud/Panel/VBox/ActionRow/PauseButton
@onready var restart_button: Button = $UI/Hud/Panel/VBox/ActionRow/RestartButton
@onready var overlay: CenterContainer = $UI/Overlay
@onready var overlay_panel: PanelContainer = $UI/Overlay/Panel
@onready var overlay_title: Label = $UI/Overlay/Panel/VBox/OverlayTitle
@onready var overlay_message: Label = $UI/Overlay/Panel/VBox/OverlayMessage
@onready var overlay_primary_button: Button = $UI/Overlay/Panel/VBox/OverlayPrimaryButton
@onready var overlay_secondary_button: Button = $UI/Overlay/Panel/VBox/OverlaySecondaryButton
@onready var overlay_tertiary_button: Button = $UI/Overlay/Panel/VBox/OverlayTertiaryButton
@onready var sfx: BubbleSfxController = $Sfx

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wave_config: BubbleWaveConfig = BubbleWaveConfig.new(COLORS.size())
var board: BubbleBoardState = BubbleBoardState.new(GRID_COLUMNS, COLORS.size(), wave_config)
var shot_planner: BubbleShotPlanner = BubbleShotPlanner.new()
var layout: BubbleGridLayout = BubbleGridLayout.new()
var grid: Array[Array] = board.grid
var active_bubble: Dictionary = {}
var particle_pool: BubbleParticlePool
var pending_bursts: Array[Dictionary] = []
var deferred_floating_bursts: Array[Dictionary] = []
var burst_bubbles: Array[Dictionary] = []
var pending_resolution: Dictionary = {}
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
## World Y of row-0 bubble tops (= centers at board_top + bubble_radius). Fixed to playfield_top after layout.
var board_top: float = 0.0
var playfield_top: float = 0.0
var lose_line_y: float = 0.0
var cannon_position: Vector2 = Vector2.ZERO
var shot_speed: float = 980.0
var max_rows_visible: int = 12
var visual_time: float = 0.0
var stack_visual_offset: float = 0.0
var row_arrival_flash: float = 0.0
var launcher_flash: float = 0.0
var launcher_recoil: float = 0.0
var mobile_low_fx: bool = false
var touch_aim_active: bool = false
var fps_update_timer: float = 0.0
var smoothed_frame_ms: float = 16.0
var last_pop_haptic_ms: int = -1000
var session_paused: bool = false
var overlay_mode: String = OVERLAY_NONE
var onboarding_active: bool = false
var onboarding_acknowledged_pop: bool = false
var game_over_recorded: bool = false
var last_run_rank: int = -1
var last_run_personal_best: bool = false
var settings: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	configure_runtime_profile()
	particle_pool = BubbleParticlePool.new(rng, mobile_low_fx)
	settings = BubbleSaveManager.load_settings()
	pause_button.pressed.connect(toggle_pause)
	restart_button.pressed.connect(restart_run)
	overlay_primary_button.pressed.connect(_on_overlay_primary_pressed)
	overlay_secondary_button.pressed.connect(_on_overlay_secondary_pressed)
	overlay_tertiary_button.pressed.connect(_on_overlay_tertiary_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	style_ui()
	apply_runtime_settings()
	update_layout()
	start_from_launch_request()
	refresh_processing_state()


func _process(delta: float) -> void:
	if session_paused:
		update_fps_display(delta)
		refresh_processing_state()
		return
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
	if particle_pool.update(delta):
		animating = true
		needs_redraw = true
	if update_pending_bursts(delta):
		animating = true
		needs_redraw = true
	if update_burst_bubbles(delta):
		animating = true
		needs_redraw = true
	if try_start_deferred_floating_phase():
		animating = true
		needs_redraw = true
	if state == STATE_RESOLVING and pending_bursts.is_empty() and burst_bubbles.is_empty():
		finish_resolution_sequence()
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
	refresh_processing_state()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("061018"), true)
	draw_background_accents()
	draw_playfield()
	draw_lose_line()
	draw_bubbles()
	draw_burst_bubbles()
	draw_particles()
	draw_launcher()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back_request()
		get_viewport().set_input_as_handled()
		return
	if session_paused or overlay_mode == OVERLAY_GAME_OVER:
		return
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
	if not fps_label.visible:
		return
	smoothed_frame_ms = lerpf(smoothed_frame_ms, delta * 1000.0, 0.12)
	fps_update_timer += delta
	if fps_update_timer < 0.2:
		return
	fps_update_timer = 0.0
	var fps: int = Engine.get_frames_per_second()
	fps_label.text = "FPS: %d   Frame: %.1f ms" % [fps, smoothed_frame_ms]


func style_ui() -> void:
	var panel_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.03, 0.11, 0.17, 0.82),
		Color(0.55, 0.93, 0.99, 0.24),
		24,
		Color(0.0, 0.0, 0.0, 0.28),
		16,
		{"left": 18.0, "top": 16.0, "right": 18.0, "bottom": 16.0}
	)
	hud_panel.add_theme_stylebox_override("panel", panel_style)

	var overlay_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.02, 0.08, 0.12, 0.92),
		Color(1.0, 0.86, 0.58, 0.28),
		28,
		Color(0.0, 0.0, 0.0, 0.34),
		22,
		{"left": 24.0, "top": 22.0, "right": 24.0, "bottom": 22.0}
	)
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

	style_button(pause_button, Color("204458"), Color("2c6077"), Color("3e7f93"))
	style_button(restart_button, Color("0f3647"), Color("1d5c74"), Color("1d8192"))
	style_button(overlay_primary_button, Color("5f4520"), Color("845e26"), Color("c98b34"))
	style_button(overlay_secondary_button, Color("153a4d"), Color("21526a"), Color("2b6782"))
	style_button(overlay_tertiary_button, Color("2d3138"), Color("404754"), Color("535d70"))


func style_button(button: Button, base_color: Color, hover_color: Color, pressed_color: Color) -> void:
	BubbleUiTheme.apply_button(button, base_color, hover_color, pressed_color, 46.0)


func update_layout() -> void:
	viewport_size = get_viewport_rect().size
	bubble_radius = minf(42.0, viewport_size.x / float(GRID_COLUMNS * 2 + 1))
	bubble_diameter = bubble_radius * 2.0
	row_height = bubble_radius * 1.72
	board_left = 0.0
	board_right = viewport_size.x
	playfield_top = viewport_size.y * 0.065
	cannon_position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.86)
	lose_line_y = cannon_position.y - bubble_radius * 2.8
	shot_speed = bubble_radius * 63.0
	board_top = playfield_top
	max_rows_visible = maxi(10, int(floor((lose_line_y - playfield_top - bubble_radius) / row_height)))
	board.set_playfield_visible_row_target(max_rows_visible)
	if aim_target == Vector2.ZERO:
		aim_target = cannon_position + Vector2.UP * 320.0
	sync_grid_layout()
	generate_ambient_stars()
	board.sync_float_adjacency(layout)
	sync_shot_planner()
	queue_redraw()


func apply_runtime_settings() -> void:
	settings = BubbleSaveManager.load_settings()
	sfx.apply_settings(settings)
	fps_label.visible = OS.is_debug_build() and bool(settings.get("show_fps_debug", true))
	refresh_processing_state()


func should_keep_processing_active() -> bool:
	if not mobile_low_fx:
		return true
	if fps_label.visible:
		return true
	if session_paused:
		return false
	return (
		state == STATE_FLYING
		or launcher_flash > 0.0
		or launcher_recoil > 0.0
			or absf(stack_visual_offset) > 0.4
			or row_arrival_flash > 0.0
			or not particle_pool.is_empty()
			or not pending_bursts.is_empty()
		or not deferred_floating_bursts.is_empty()
		or not burst_bubbles.is_empty()
	)


func refresh_processing_state(force_active: bool = false) -> void:
	if not mobile_low_fx:
		set_process(true)
		return
	set_process(force_active or should_keep_processing_active())


func start_from_launch_request() -> void:
	var request: Dictionary = BubbleSaveManager.consume_launch_request()
	apply_runtime_settings()
	if String(request.get("mode", "")) == "continue" and BubbleSaveManager.has_checkpoint():
		load_checkpoint_run(BubbleSaveManager.load_checkpoint())
		return
	start_new_game()


func sync_grid_layout() -> void:
	layout.board_left = board_left
	layout.board_right = board_right
	layout.board_top = board_top
	layout.bubble_radius = bubble_radius
	layout.bubble_diameter = bubble_diameter
	layout.row_height = row_height
	layout.max_rows_visible = max_rows_visible
	layout.cannon_position = cannon_position
	layout.lose_line_y = lose_line_y
	layout.stack_visual_offset = stack_visual_offset


func sync_shot_planner() -> void:
	layout.stack_visual_offset = stack_visual_offset
	shot_planner.sync_layout(board, layout)


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
	update_layout()
	active_bubble.clear()
	particle_pool.clear()
	pending_bursts.clear()
	deferred_floating_bursts.clear()
	burst_bubbles.clear()
	pending_resolution.clear()
	stack_visual_offset = 0.0
	row_arrival_flash = 0.0
	session_paused = false
	overlay_mode = OVERLAY_NONE
	overlay.visible = false
	state = STATE_AIMING
	game_over_recorded = false
	last_run_rank = -1
	last_run_personal_best = false
	onboarding_active = not BubbleSaveManager.is_onboarding_complete()
	onboarding_acknowledged_pop = false
	current_color = board.pick_shoot_color(rng)
	next_color = board.pick_shoot_color(rng)
	if onboarding_active:
		board.status_message = "Match 3 bubbles of the same color."
	BubbleSaveManager.clear_checkpoint()
	save_checkpoint_if_safe(true)
	refresh_hud()
	refresh_processing_state(true)
	queue_redraw()


func restart_run() -> void:
	start_new_game()


func load_checkpoint_run(checkpoint: Dictionary) -> void:
	board.import_state(Dictionary(checkpoint.get("board_state", {})))
	grid = board.grid
	update_layout()
	active_bubble.clear()
	particle_pool.clear()
	pending_bursts.clear()
	deferred_floating_bursts.clear()
	burst_bubbles.clear()
	pending_resolution.clear()
	stack_visual_offset = 0.0
	row_arrival_flash = 0.0
	session_paused = false
	overlay_mode = OVERLAY_NONE
	overlay.visible = false
	state = STATE_AIMING
	game_over_recorded = false
	last_run_rank = -1
	last_run_personal_best = false
	onboarding_active = false
	onboarding_acknowledged_pop = true
	current_color = int(checkpoint.get("current_color", board.pick_shoot_color(rng)))
	next_color = int(checkpoint.get("next_color", board.pick_shoot_color(rng)))
	refresh_hud()
	refresh_processing_state()
	queue_redraw()


func build_checkpoint() -> Dictionary:
	return {
		"board_state": board.export_state(),
		"current_color": current_color,
		"next_color": next_color,
		"wave": board.wave,
		"score": board.score,
	}


func save_checkpoint_if_safe(force: bool = false) -> void:
	if not force:
		if state != STATE_AIMING or session_paused:
			return
		if not active_bubble.is_empty() or not pending_bursts.is_empty() or not burst_bubbles.is_empty():
			return
		if overlay_mode == OVERLAY_GAME_OVER:
			return
	BubbleSaveManager.save_checkpoint(build_checkpoint())


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
	sfx.play_shoot()
	refresh_processing_state(true)
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
	sfx.play_wall_bounce()
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
		spawn_stack_impact_sparks(snap_center, COLORS[int(active_bubble["color"])])
	var resolution: Dictionary = board.resolve_placed_bubble(snap, int(active_bubble["color"]), rng)
	active_bubble.clear()
	if has_resolution_bursts(resolution):
		begin_resolution_sequence(resolution, snap, snap_center)
		return

	complete_resolution_followup(resolution)


func has_resolution_bursts(resolution: Dictionary) -> bool:
	return not resolution["cluster_bursts"].is_empty() or not resolution["floating_bursts"].is_empty()


func begin_resolution_sequence(resolution: Dictionary, start_cell: Vector2i, origin: Vector2) -> void:
	pending_resolution = resolution
	var burst_phases: Dictionary = build_resolution_burst_phases(resolution, start_cell, origin)
	pending_bursts = Array(burst_phases.get("cluster", []), TYPE_DICTIONARY, &"", null)
	deferred_floating_bursts = Array(burst_phases.get("floating", []), TYPE_DICTIONARY, &"", null)
	burst_bubbles.clear()
	state = STATE_RESOLVING
	refresh_hud()
	refresh_processing_state(true)
	queue_redraw()


func finish_resolution_sequence() -> void:
	if pending_resolution.is_empty():
		return

	var resolution: Dictionary = pending_resolution.duplicate(true)
	pending_resolution.clear()
	complete_resolution_followup(resolution)


func complete_resolution_followup(resolution: Dictionary) -> void:
	board.apply_resolution_followup(resolution, rng)
	state = STATE_AIMING
	board_top = playfield_top
	var baseline_refilled: int = int(resolution.get("baseline_refilled", 0))
	if bool(resolution["board_cleared"]):
		stack_visual_offset = 0.0
	else:
		stack_visual_offset = -float(baseline_refilled) * row_height

	if resolution["board_cleared"]:
		update_layout()
		sfx.play_board_clear()
		current_color = board.pick_shoot_color(rng)
		next_color = board.pick_shoot_color(rng)
		if onboarding_active and not onboarding_acknowledged_pop:
			onboarding_acknowledged_pop = true
			onboarding_active = false
			board.status_message = "Nice shot. Keep the stack away from the warning line."
			BubbleSaveManager.set_onboarding_complete(true)
		save_checkpoint_if_safe(true)
		refresh_hud()
		queue_redraw()
		return

	board.sync_float_adjacency(layout)
	sync_shot_planner()

	refresh_processing_state(true)

	if check_loss_condition():
		return

	current_color = next_color
	next_color = board.pick_shoot_color(rng)
	if onboarding_active and resolution["total_removed"] >= 3 and not onboarding_acknowledged_pop:
		onboarding_acknowledged_pop = true
		onboarding_active = false
		board.status_message = "Nice shot. Detached bubbles also fall."
		BubbleSaveManager.set_onboarding_complete(true)
	save_checkpoint_if_safe()
	refresh_hud()
	queue_redraw()


func build_resolution_burst_phases(resolution: Dictionary, start_cell: Vector2i, origin: Vector2) -> Dictionary:
	return BubbleBurstPhaseBuilder.build_phases(
		resolution, start_cell, origin, board, layout, COLORS, bubble_radius, mobile_low_fx
	)


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
	session_paused = false
	active_bubble.clear()
	pending_bursts.clear()
	deferred_floating_bursts.clear()
	burst_bubbles.clear()
	pending_resolution.clear()
	sfx.play_game_over()
	record_high_score_if_needed()
	show_game_over_overlay(message)
	board.status_message = message
	BubbleSaveManager.clear_checkpoint()
	refresh_hud()
	refresh_processing_state()
	queue_redraw()


func try_start_deferred_floating_phase() -> bool:
	if not BubbleBurstSequenceGuard.should_start_floating_phase(deferred_floating_bursts, pending_bursts, burst_bubbles):
		return false
	pending_bursts = deferred_floating_bursts
	deferred_floating_bursts = []
	return true


func record_high_score_if_needed() -> void:
	if game_over_recorded:
		return
	game_over_recorded = true
	var result: Dictionary = BubbleSaveManager.record_score({
		"score": board.score,
		"wave": board.wave,
	})
	last_run_rank = int(result.get("rank", -1))
	last_run_personal_best = bool(result.get("is_personal_best", false))


func show_pause_overlay() -> void:
	if state == STATE_GAME_OVER:
		return
	session_paused = true
	overlay_mode = OVERLAY_PAUSE
	overlay.visible = true
	overlay_title.text = "Paused"
	overlay_message.text = "Take a breath. Resume when you're ready."
	overlay_primary_button.text = "Resume"
	overlay_secondary_button.text = "Restart"
	overlay_secondary_button.visible = true
	overlay_tertiary_button.text = "Main Menu"
	overlay_tertiary_button.visible = true
	refresh_hud()


func show_game_over_overlay(message: String) -> void:
	overlay_mode = OVERLAY_GAME_OVER
	overlay.visible = true
	overlay_title.text = "Game Over"
	var summary_lines: Array[String] = [
		message,
		"Final score: %d" % board.score,
		"Wave reached: %d" % board.wave,
	]
	if last_run_personal_best:
		summary_lines.append("New personal best.")
	elif last_run_rank > 0:
		summary_lines.append("High score rank: #%d" % last_run_rank)
	overlay_message.text = "\n".join(summary_lines)
	overlay_primary_button.text = "Retry"
	overlay_secondary_button.text = "Main Menu"
	overlay_secondary_button.visible = true
	overlay_tertiary_button.visible = false


func hide_overlay() -> void:
	overlay.visible = false
	overlay_mode = OVERLAY_NONE


func toggle_pause() -> void:
	if state == STATE_GAME_OVER:
		return
	if session_paused:
		resume_game()
	else:
		show_pause_overlay()


func resume_game() -> void:
	session_paused = false
	hide_overlay()
	refresh_hud()
	refresh_processing_state()
	queue_redraw()


func return_to_menu() -> void:
	BubbleSaveManager.set_launch_request({})
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func handle_back_request() -> void:
	if overlay_mode == OVERLAY_GAME_OVER:
		return_to_menu()
		return
	if overlay_mode == OVERLAY_PAUSE:
		return_to_menu()
		return
	show_pause_overlay()


func _on_overlay_primary_pressed() -> void:
	if overlay_mode == OVERLAY_PAUSE:
		resume_game()
		return
	start_new_game()


func _on_overlay_secondary_pressed() -> void:
	if overlay_mode == OVERLAY_PAUSE:
		start_new_game()
		return
	return_to_menu()


func _on_overlay_tertiary_pressed() -> void:
	if overlay_mode == OVERLAY_PAUSE:
		return_to_menu()


func refresh_hud() -> void:
	score_label.text = "Score: %d    Wave: %d" % [board.score, board.wave]
	status_label.text = board.status_message
	pause_button.text = "Resume" if session_paused else "Pause"
	restart_button.disabled = state == STATE_GAME_OVER


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_checkpoint_if_safe()


func row_shift_parity(row: int) -> int:
	return board.row_shift_parity(row)


func cell_occupied(row: int, col: int) -> bool:
	return board.cell_occupied(row, col)


func cell_to_world(row: int, col: int) -> Vector2:
	return layout.cell_center(row, col, board.row_parity_offset)


func cell_to_world_with_parity(row: int, col: int, parity_offset: int) -> Vector2:
	return layout.cell_center(row, col, parity_offset)


func cell_to_logic_world(row: int, col: int) -> Vector2:
	return layout.cell_center_static(row, col, board.row_parity_offset)


func get_playfield_rect() -> Rect2:
	return layout.playfield_rect()


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
	return Vector2(cos(angle), sin(angle)).normalized()


func update_stack_animation(delta: float) -> bool:
	var animated: bool = false
	if state != STATE_FLYING and absf(stack_visual_offset) > 0.4:
		stack_visual_offset *= exp(-8.0 * delta)
		if absf(stack_visual_offset) <= 0.4:
			stack_visual_offset = 0.0
		animated = true

	if row_arrival_flash > 0.0:
		row_arrival_flash = maxf(0.0, row_arrival_flash - delta * 2.2)
		animated = true

	if animated:
		sync_shot_planner()

	return animated




func update_pending_bursts(delta: float) -> bool:
	if pending_bursts.is_empty():
		return false

	var write_index: int = 0
	for read_index in range(pending_bursts.size()):
		var burst: Dictionary = pending_bursts[read_index]
		var delay: float = burst["delay"] - delta
		if delay <= 0.0:
			if String(burst["burst_kind"]) == "floating" and not BubbleBurstSequenceGuard.can_activate_floating_burst(pending_bursts, burst_bubbles):
				burst["delay"] = 0.0
				pending_bursts[write_index] = burst
				write_index += 1
				continue
			activate_burst_bubble(burst)
			continue
		burst["delay"] = delay
		pending_bursts[write_index] = burst
		write_index += 1

	if write_index != pending_bursts.size():
		pending_bursts.resize(write_index)

	return true


func update_burst_bubbles(delta: float) -> bool:
	if burst_bubbles.is_empty():
		return false

	var write_index: int = 0
	for read_index in range(burst_bubbles.size()):
		var burst: Dictionary = burst_bubbles[read_index]
		var age: float = burst["age"] + delta
		var duration: float = burst["duration"]
		if age >= duration:
			continue
		burst["age"] = age
		burst_bubbles[write_index] = burst
		write_index += 1

	if write_index != burst_bubbles.size():
		burst_bubbles.resize(write_index)

	return true


func activate_burst_bubble(burst: Dictionary) -> void:
	var center: Vector2 = burst["center"]
	var bubble_color: Color = burst["color"]
	var pop_power: float = 1.0 if burst["burst_kind"] == "cluster" else 0.82
	trigger_pop_haptic()
	if burst["burst_kind"] == "cluster":
		sfx.play_match_pop()
	else:
		sfx.play_floating_drop()
	spawn_pop_burst(center, bubble_color, burst["particle_count"], burst["particle_scale"])
	burst_bubbles.append({
		"center": center,
		"color": bubble_color,
		"burst_kind": burst["burst_kind"],
		"age": 0.0,
		"duration": burst["duration"],
		"glow": burst["glow"],
		"pop_power": pop_power,
	})


func trigger_pop_haptic() -> void:
	if not mobile_low_fx:
		return
	var now: int = Time.get_ticks_msec()
	if now - last_pop_haptic_ms < 16:
		return
	last_pop_haptic_ms = now
	Input.vibrate_handheld(16, 0.45)


func spawn_stack_impact_sparks(center: Vector2, bubble_color: Color) -> void:
	particle_pool.spawn_impact_sparks(center, bubble_color, bubble_radius)


func spawn_pop_burst(center: Vector2, bubble_color: Color, count: int, size_scale: float) -> void:
	particle_pool.spawn_burst(center, bubble_color, count, size_scale, bubble_radius)


func spawn_spark(center: Vector2, spark_color: Color, push: Vector2) -> void:
	particle_pool.spawn_spark(center, spark_color, push, bubble_radius)


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
			Vector2(frame_rect.position.x + bubble_radius * 0.08, frame_rect.position.y - row_height * 0.38),
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
	var ceiling_y: float = board_top + stack_visual_offset
	draw_line(
		Vector2(frame_rect.position.x + bubble_radius * 0.2, ceiling_y),
		Vector2(frame_rect.end.x - bubble_radius * 0.2, ceiling_y),
		Color(1.0, 1.0, 1.0, 0.18),
		3.0
	)

	var show_empty_slots: bool = not mobile_low_fx or (state == STATE_AIMING and absf(stack_visual_offset) < 0.02 and row_arrival_flash <= 0.0)
	if show_empty_slots:
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
	var source_rows: Array[Array] = grid
	var rows_to_draw: int = mini(source_rows.size(), max_rows_visible + 1)
	for row in range(rows_to_draw):
		for col in range(GRID_COLUMNS):
			if int(source_rows[row][col]) == BubbleBoardState.EMPTY_CELL:
				continue
			var bubble_center: Vector2 = cell_to_world(row, col)
			if bubble_center.y > lose_line_y + bubble_radius:
				continue
			draw_bubble(bubble_center, COLORS[int(source_rows[row][col])], bubble_radius, 1.0)

	if not active_bubble.is_empty():
		draw_flying_bubble(
			active_bubble["position"],
			COLORS[int(active_bubble["color"])],
			current_shot_direction(),
			float(active_bubble["launch_age"])
		)

	draw_pending_burst_bubbles()


func draw_particles() -> void:
	for particle in particle_pool.particles:
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


func draw_burst_bubbles() -> void:
	for burst in burst_bubbles:
		var age: float = burst["age"]
		var duration: float = burst["duration"]
		var progress: float = clampf(age / duration, 0.0, 1.0)
		var center: Vector2 = burst["center"]
		var bubble_color: Color = burst["color"]
		var glow_strength: float = burst["glow"]
		var pop_power: float = burst["pop_power"]
		var flash_ratio: float = 1.0 - progress
		var swell_phase: float = clampf(progress / 0.22, 0.0, 1.0)
		var collapse_phase: float = clampf((progress - 0.14) / 0.86, 0.0, 1.0)
		var swell: float = sin(swell_phase * PI * 0.5) * (0.22 * pop_power)
		var collapse: float = pow(1.0 - collapse_phase, 0.52)
		var radius: float = bubble_radius * (1.0 + swell) * collapse
		var highlight_mix: float = 0.2 + flash_ratio * 0.28 + swell * 0.45
		var highlight_color: Color = bubble_color.lerp(Color(1.0, 1.0, 1.0, 1.0), minf(highlight_mix, 0.72))
		var shell_alpha: float = (0.16 + flash_ratio * 0.12 + swell * 0.22) * pop_power
		draw_circle(center, bubble_radius * (1.1 + swell * 0.8), Color(highlight_color.r, highlight_color.g, highlight_color.b, shell_alpha * 0.48))
		draw_bubble(center, highlight_color, maxf(radius, bubble_radius * 0.12), glow_strength + flash_ratio * (0.92 + pop_power * 0.2))
		var flash_size: float = bubble_radius * (0.24 + swell * 0.7 + flash_ratio * 0.16)
		draw_circle(center, flash_size, Color(1.0, 1.0, 1.0, (0.2 + swell * 0.24) * flash_ratio))
		var ring_radius: float = bubble_radius * (0.28 + progress * (1.0 + pop_power * 0.35))
		var ring_alpha: float = (0.22 + swell * 0.18) * flash_ratio
		draw_arc(center, ring_radius, 0.0, TAU, 22, Color(1.0, 1.0, 1.0, ring_alpha), maxf(1.4, bubble_radius * (0.06 + flash_ratio * 0.03)), true)


func draw_pending_burst_bubbles() -> void:
	var preview_bursts: Array[Dictionary] = BubbleBurstSequenceGuard.visible_preview_bursts(pending_bursts, deferred_floating_bursts)
	for burst in preview_bursts:
		var is_preview_only: bool = bool(burst.get("preview_only", false))
		var glow: float = 1.0 if is_preview_only else (1.08 if burst["burst_kind"] == "cluster" else 0.92)
		draw_bubble(burst["center"], burst["color"], bubble_radius, glow)


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
	# Plain PNG-check mode: pulse, glow, and shadow are temporarily disabled.
	#var pulse: float = 1.0
	#if not mobile_low_fx:
	#	pulse = 1.0 + sin(visual_time * 2.4 + center.x * 0.018 + center.y * 0.011) * 0.028
	#var animated_radius: float = radius * pulse
	#var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.26)
	#var glow_color: Color = bubble_color
	#glow_color.a = 0.11 * glow_strength
	var bubble_texture: Texture2D = get_bubble_texture_for_color(bubble_color)
	#var glow_radius: float = animated_radius * (1.14 if mobile_low_fx else 1.24 + glow_strength * 0.04)
	#draw_circle(center, glow_radius, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * (0.74 if mobile_low_fx else 1.0)))
	#draw_circle(center + Vector2(0.0, animated_radius * 0.14), animated_radius * 1.02, shadow_color)
	#var texture_rect: Rect2 = Rect2(center - Vector2.ONE * animated_radius, Vector2.ONE * animated_radius * 2.0)
	var draw_radius: float = radius / 0.84
	var texture_rect: Rect2 = Rect2(center - Vector2.ONE * draw_radius, Vector2.ONE * draw_radius * 2.0)
	draw_texture_rect(bubble_texture, texture_rect, false, bubble_color)
	#if mobile_low_fx:
	#	return
	#draw_circle(center + Vector2(-animated_radius * 0.2, -animated_radius * 0.22), animated_radius * 0.14, Color(1.0, 1.0, 1.0, 0.18))
	#draw_circle(center + Vector2(animated_radius * 0.22, animated_radius * 0.24), animated_radius * 0.34, Color(0.0, 0.0, 0.0, 0.06))


func get_bubble_texture_for_color(bubble_color: Color) -> Texture2D:
	var best_index: int = 0
	var best_distance: float = INF
	for index in range(mini(COLORS.size(), BUBBLE_TEXTURES.size())):
		var base_color: Color = COLORS[index]
		var distance: float = (
			pow(base_color.r - bubble_color.r, 2.0)
			+ pow(base_color.g - bubble_color.g, 2.0)
			+ pow(base_color.b - bubble_color.b, 2.0)
		)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return BUBBLE_TEXTURES[best_index]
