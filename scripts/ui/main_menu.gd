extends Control

const MENU_BUBBLE_COLORS := [
	Color("ff6b6b"),
	Color("ffd166"),
	Color("4ecdc4"),
	Color("5dade2"),
	Color("a78bfa"),
	Color("95e06c"),
]

@onready var version_chip: Label = $TopBar/Row/VersionChip
@onready var eyebrow_label: Label = $Hero/HeroPanel/VBox/EyebrowLabel
@onready var title_label: Label = $Hero/HeroPanel/VBox/TitleLabel
@onready var subtitle_label: Label = $Hero/HeroPanel/VBox/SubtitleLabel
@onready var continue_button: Button = $Hero/HeroPanel/VBox/ContinueButton
@onready var new_game_button: Button = $Hero/HeroPanel/VBox/NewGameButton
@onready var high_scores_button: Button = $Hero/HeroPanel/VBox/HighScoresButton
@onready var hint_card: PanelContainer = $Hero/HeroPanel/VBox/HintCard
@onready var hint_label: Label = $Hero/HeroPanel/VBox/HintCard/HintLabel
@onready var footer_label: Label = $Hero/HeroPanel/VBox/FooterLabel
@onready var settings_button: Button = $TopBar/Row/SettingsButton
@onready var high_scores_overlay: Control = $HighScoresOverlay
@onready var high_scores_panel: PanelContainer = $HighScoresOverlay/Center/Panel
@onready var high_scores_text: Label = $HighScoresOverlay/Center/Panel/VBox/ScoresLabel
@onready var high_scores_close_button: Button = $HighScoresOverlay/Center/Panel/VBox/CloseButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var settings_panel: BubbleSettingsPanel = $SettingsOverlay/Center/SettingsPanel
@onready var overwrite_dialog: ConfirmationDialog = $OverwriteDialog

var visual_time: float = 0.0
var decor_bubbles: Array[Dictionary] = []


func _ready() -> void:
	_apply_theme()
	_seed_decor()
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	high_scores_button.pressed.connect(_open_high_scores)
	settings_button.pressed.connect(_open_settings)
	high_scores_close_button.pressed.connect(_close_high_scores)
	settings_panel.closed.connect(_close_settings)
	settings_panel.settings_changed.connect(_on_settings_changed)
	overwrite_dialog.confirmed.connect(_start_new_game)
	refresh_menu()


func _process(delta: float) -> void:
	visual_time += delta
	queue_redraw()


func _draw() -> void:
	var viewport: Vector2 = get_viewport_rect().size
	draw_circle(Vector2(viewport.x * 0.18, viewport.y * 0.18), viewport.x * 0.28, Color(0.10, 0.68, 0.74, 0.12))
	draw_circle(Vector2(viewport.x * 0.86, viewport.y * 0.78), viewport.x * 0.24, Color(0.99, 0.71, 0.29, 0.1))
	draw_circle(Vector2(viewport.x * 0.55, viewport.y * 0.42), viewport.x * 0.34, Color(0.14, 0.26, 0.49, 0.12))
	for bubble in decor_bubbles:
		var base_position: Vector2 = bubble["position"]
		var drift: Vector2 = Vector2(
			sin(visual_time * bubble["speed"] + bubble["phase"]) * bubble["drift"],
			cos(visual_time * bubble["speed"] * 0.82 + bubble["phase"]) * bubble["drift"] * 0.72
		)
		var center: Vector2 = base_position + drift
		var radius: float = bubble["radius"] * (1.0 + sin(visual_time * 1.3 + bubble["phase"]) * 0.03)
		var color: Color = bubble["color"]
		draw_circle(center, radius * 1.28, Color(color.r, color.g, color.b, 0.08))
		draw_circle(center + Vector2(0.0, radius * 0.12), radius * 1.02, Color(0.0, 0.0, 0.0, 0.14))
		draw_circle(center, radius, color.darkened(0.08))
		draw_circle(center + Vector2(-radius * 0.12, -radius * 0.16), radius * 0.58, color.lightened(0.18))


func _apply_theme() -> void:
	var hero_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.02, 0.08, 0.12, 0.92),
		Color(0.54, 0.93, 0.99, 0.24),
		30,
		Color(0.0, 0.0, 0.0, 0.32),
		18,
		{"left": 22.0, "top": 24.0, "right": 22.0, "bottom": 22.0}
	)
	$Hero/HeroPanel.add_theme_stylebox_override("panel", hero_style)

	var info_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.05, 0.17, 0.22, 0.84),
		Color(0.98, 0.72, 0.33, 0.24),
		22,
		Color(0.0, 0.0, 0.0, 0.0),
		0,
		{"left": 16.0, "top": 14.0, "right": 16.0, "bottom": 14.0},
		1
	)
	hint_card.add_theme_stylebox_override("panel", info_style)

	var overlay_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.03, 0.09, 0.13, 0.97),
		Color(0.54, 0.93, 0.99, 0.24),
		30,
		Color(0.0, 0.0, 0.0, 0.32),
		18,
		{"left": 20.0, "top": 20.0, "right": 20.0, "bottom": 20.0}
	)
	high_scores_panel.add_theme_stylebox_override("panel", overlay_style)

	_style_button(continue_button, Color("7a551f"), Color("a06d27"), Color("c98b34"), 58.0)
	_style_button(new_game_button, Color("0f4051"), Color("17576d"), Color("23768f"), 54.0)
	_style_button(high_scores_button, Color("16222d"), Color("20313d"), Color("2a4050"), 52.0)
	_style_button(settings_button, Color("122735"), Color("1a3a4c"), Color("235370"), 44.0)
	_style_button(high_scores_close_button, Color("173847"), Color("205269"), Color("2a6f8f"), 46.0)

	version_chip.add_theme_font_size_override("font_size", 13)
	version_chip.add_theme_color_override("font_color", Color("9fe8ff"))
	eyebrow_label.add_theme_font_size_override("font_size", 12)
	eyebrow_label.add_theme_color_override("font_color", Color("ffe9b5"))
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color("f7fbff"))
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", Color("d5f7ff"))
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color("e9fbff"))
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", Color("7ab8c8"))
	$HighScoresOverlay/Center/Panel/VBox/TitleLabel.add_theme_font_size_override("font_size", 28)
	$HighScoresOverlay/Center/Panel/VBox/TitleLabel.add_theme_color_override("font_color", Color("f7fbff"))
	high_scores_text.add_theme_font_size_override("font_size", 17)
	high_scores_text.add_theme_color_override("font_color", Color("d5f7ff"))


func _style_button(button: Button, base_color: Color, hover_color: Color, pressed_color: Color, min_height: float) -> void:
	BubbleUiTheme.apply_button(button, base_color, hover_color, pressed_color, min_height, 18, 18)


func _seed_decor() -> void:
	decor_bubbles.clear()
	var viewport: Vector2 = get_viewport_rect().size
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4127
	for index in range(11):
		decor_bubbles.append({
			"position": Vector2(
				rng.randf_range(viewport.x * 0.08, viewport.x * 0.92),
				rng.randf_range(viewport.y * 0.12, viewport.y * 0.92)
			),
			"radius": rng.randf_range(12.0, 26.0),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.22, 0.6),
			"drift": rng.randf_range(8.0, 18.0),
			"color": MENU_BUBBLE_COLORS[index % MENU_BUBBLE_COLORS.size()],
		})


func refresh_menu() -> void:
	var checkpoint: Dictionary = BubbleSaveManager.load_checkpoint()
	if checkpoint.is_empty():
		continue_button.visible = false
		subtitle_label.text = "First 25 waves are ready. Start a fresh run."
	else:
		continue_button.visible = true
		subtitle_label.text = "Continue from Wave %d  |  Score %d" % [int(checkpoint.get("wave", 1)), int(checkpoint.get("score", 0))]
	_render_high_scores()


func _render_high_scores() -> void:
	var lines: Array[String] = []
	var scores: Array[Dictionary] = BubbleSaveManager.load_high_scores()
	if scores.is_empty():
		lines.append("No runs recorded yet.")
	else:
		for index in range(scores.size()):
			var entry: Dictionary = scores[index]
			lines.append("%d. %d pts  |  Wave %d" % [index + 1, int(entry["score"]), int(entry["wave"])])
	high_scores_text.text = "\n".join(lines)


func _on_continue_pressed() -> void:
	BubbleSaveManager.set_launch_request({"mode": "continue"})
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_new_game_pressed() -> void:
	if BubbleSaveManager.has_checkpoint():
		overwrite_dialog.popup_centered()
		return
	_start_new_game()


func _start_new_game() -> void:
	BubbleSaveManager.clear_checkpoint()
	BubbleSaveManager.set_launch_request({"mode": "new"})
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _open_high_scores() -> void:
	_render_high_scores()
	high_scores_overlay.visible = true


func _close_high_scores() -> void:
	high_scores_overlay.visible = false


func _open_settings() -> void:
	settings_overlay.visible = true


func _close_settings() -> void:
	settings_overlay.visible = false


func _on_settings_changed(_new_settings: Dictionary) -> void:
	refresh_menu()
