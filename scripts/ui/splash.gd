extends Control

const SPLASH_DURATION := 1.5
const SPLASH_COLORS := [
	Color("ff6b6b"),
	Color("ffd166"),
	Color("4ecdc4"),
	Color("5dade2"),
]

@onready var timer: Timer = $Timer
@onready var hero_panel: PanelContainer = $Center/HeroPanel
@onready var eyebrow_label: Label = $Center/HeroPanel/VBox/EyebrowLabel
@onready var logo_label: Label = $Center/HeroPanel/VBox/LogoLabel
@onready var tagline_label: Label = $Center/HeroPanel/VBox/TaglineLabel
@onready var hint_label: Label = $Center/HeroPanel/VBox/HintLabel

var advanced: bool = false
var visual_time: float = 0.0


func _ready() -> void:
	_apply_theme()
	timer.wait_time = SPLASH_DURATION
	timer.timeout.connect(_advance)
	timer.start()


func _process(delta: float) -> void:
	visual_time += delta
	queue_redraw()


func _draw() -> void:
	var viewport: Vector2 = get_viewport_rect().size
	draw_circle(Vector2(viewport.x * 0.2, viewport.y * 0.24), viewport.x * 0.3, Color(0.09, 0.67, 0.73, 0.13))
	draw_circle(Vector2(viewport.x * 0.82, viewport.y * 0.76), viewport.x * 0.24, Color(0.99, 0.70, 0.33, 0.1))
	for index in range(8):
		var color: Color = SPLASH_COLORS[index % SPLASH_COLORS.size()]
		var phase: float = visual_time * (0.6 + float(index) * 0.03) + float(index)
		var center: Vector2 = Vector2(
			viewport.x * (0.22 + float(index % 4) * 0.17) + sin(phase) * 8.0,
			viewport.y * (0.28 + float(index / 4) * 0.11) + cos(phase * 0.9) * 10.0
		)
		var radius: float = 17.0 + sin(phase * 1.2) * 1.2
		draw_circle(center, radius * 1.24, Color(color.r, color.g, color.b, 0.08))
		draw_circle(center, radius, color.darkened(0.08))
		draw_circle(center + Vector2(-radius * 0.14, -radius * 0.16), radius * 0.54, color.lightened(0.16))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		_advance()


func _advance() -> void:
	if advanced:
		return
	advanced = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _apply_theme() -> void:
	var panel_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.02, 0.08, 0.12, 0.84),
		Color(0.98, 0.72, 0.33, 0.22),
		30,
		Color(0.0, 0.0, 0.0, 0.3),
		16,
		{"left": 24.0, "top": 24.0, "right": 24.0, "bottom": 24.0}
	)
	hero_panel.add_theme_stylebox_override("panel", panel_style)
	eyebrow_label.add_theme_font_size_override("font_size", 12)
	eyebrow_label.add_theme_color_override("font_color", Color("ffe9b5"))
	logo_label.add_theme_font_size_override("font_size", 38)
	logo_label.add_theme_color_override("font_color", Color("f7fbff"))
	tagline_label.add_theme_font_size_override("font_size", 17)
	tagline_label.add_theme_color_override("font_color", Color("d5f7ff"))
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color("9fe8ff"))
