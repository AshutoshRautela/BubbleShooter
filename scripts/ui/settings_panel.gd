class_name BubbleSettingsPanel
extends PanelContainer

signal settings_changed(settings: Dictionary)
signal closed

@onready var sfx_toggle: CheckButton = $VBox/SfxToggle
@onready var volume_slider: HSlider = $VBox/VolumeSlider
@onready var volume_value: Label = $VBox/VolumeValue
@onready var fps_toggle: CheckButton = $VBox/FpsToggle
@onready var close_button: Button = $VBox/CloseButton
@onready var title_label: Label = $VBox/TitleLabel
@onready var volume_label: Label = $VBox/VolumeLabel

var settings: Dictionary = {}


func _ready() -> void:
	settings = BubbleSaveManager.load_settings()
	_apply_style()
	_apply_settings_to_controls()
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	fps_toggle.toggled.connect(_on_fps_toggled)
	close_button.pressed.connect(_on_close_pressed)


func _apply_style() -> void:
	var panel_style: StyleBoxFlat = BubbleUiTheme.make_panel_style(
		Color(0.02, 0.08, 0.12, 0.97),
		Color(0.98, 0.72, 0.33, 0.24),
		24,
		Color(0.0, 0.0, 0.0, 0.32),
		18,
		{"left": 20.0, "top": 18.0, "right": 20.0, "bottom": 18.0}
	)
	add_theme_stylebox_override("panel", panel_style)

	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("f7fbff"))
	volume_label.add_theme_font_size_override("font_size", 15)
	volume_label.add_theme_color_override("font_color", Color("d5f7ff"))
	volume_value.add_theme_font_size_override("font_size", 14)
	volume_value.add_theme_color_override("font_color", Color("ffe9b5"))

	for toggle in [sfx_toggle, fps_toggle]:
		toggle.add_theme_font_size_override("font_size", 16)
		toggle.add_theme_color_override("font_color", Color("f7fbff"))

	var slider_style: StyleBoxFlat = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.12, 0.24, 0.31, 0.95)
	slider_style.corner_radius_top_left = 8
	slider_style.corner_radius_top_right = 8
	slider_style.corner_radius_bottom_left = 8
	slider_style.corner_radius_bottom_right = 8
	volume_slider.add_theme_stylebox_override("slider", slider_style)

	BubbleUiTheme.apply_button(close_button, Color("7a551f"), Color("a06d27"), Color("c98b34"), 46.0)


func _apply_settings_to_controls() -> void:
	sfx_toggle.button_pressed = bool(settings.get("sfx_enabled", true))
	volume_slider.value = float(settings.get("sfx_volume", 1.0))
	volume_value.text = "%d%%" % int(round(volume_slider.value * 100.0))
	fps_toggle.button_pressed = OS.is_debug_build() and bool(settings.get("show_fps_debug", true))
	fps_toggle.visible = OS.is_debug_build()


func _persist() -> void:
	BubbleSaveManager.save_settings(settings)
	settings_changed.emit(settings.duplicate(true))


func _on_sfx_toggled(enabled: bool) -> void:
	settings["sfx_enabled"] = enabled
	_persist()


func _on_volume_changed(value: float) -> void:
	settings["sfx_volume"] = value
	volume_value.text = "%d%%" % int(round(value * 100.0))
	_persist()


func _on_fps_toggled(enabled: bool) -> void:
	settings["show_fps_debug"] = enabled
	_persist()


func _on_close_pressed() -> void:
	closed.emit()
