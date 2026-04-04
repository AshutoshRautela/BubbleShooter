class_name BubbleUiTheme
extends RefCounted


static func make_panel_style(
	bg_color: Color,
	border_color: Color,
	corner_radius: int,
	shadow_color: Color,
	shadow_size: int,
	margins: Dictionary = {},
	border_width: int = 2
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.content_margin_left = float(margins.get("left", 0.0))
	style.content_margin_top = float(margins.get("top", 0.0))
	style.content_margin_right = float(margins.get("right", 0.0))
	style.content_margin_bottom = float(margins.get("bottom", 0.0))
	return style


static func make_button_style(
	fill_color: Color,
	corner_radius: int = 16,
	border_width: int = 1,
	shadow_size: int = 8
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = fill_color.lightened(0.22)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = shadow_size
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


static func apply_button(
	button: Button,
	base_color: Color,
	hover_color: Color,
	pressed_color: Color,
	min_height: float,
	font_size: int = 17,
	corner_radius: int = 16
) -> void:
	var normal: StyleBoxFlat = make_button_style(base_color, corner_radius)
	var hover: StyleBoxFlat = make_button_style(hover_color, corner_radius)
	var pressed: StyleBoxFlat = make_button_style(pressed_color, corner_radius)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color("f7fbff"))
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size = Vector2(0.0, min_height)
