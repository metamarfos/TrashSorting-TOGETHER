class_name UIKit
extends RefCounted
## Помощники для построения единообразного интерфейса из кода.


static func box(color: Color, radius: int = 36, border_color: Color = Color(0, 0, 0, 0), border_width: int = 0, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border_width > 0:
		s.border_color = border_color
		s.set_border_width_all(border_width)
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.12)
		s.shadow_size = 10
		s.shadow_offset = Vector2(0, 6)
	return s


static func style_button(b: Button, color: Color, text_color: Color = Color.WHITE, font_size: int = 44, radius: int = 36) -> void:
	var normal := box(color, radius)
	var hover := box(color.lightened(0.08), radius)
	var pressed := box(color.darkened(0.15), radius, Color(0, 0, 0, 0), 0, false)
	var disabled := box(Palette.DISABLED, radius, Color(0, 0, 0, 0), 0, false)
	for s: StyleBoxFlat in [normal, hover, pressed, disabled]:
		s.content_margin_left = 28
		s.content_margin_right = 28
		s.content_margin_top = 14
		s.content_margin_bottom = 14
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", text_color)
	b.add_theme_color_override("font_hover_color", text_color)
	b.add_theme_color_override("font_pressed_color", text_color)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", font_size)
	b.focus_mode = Control.FOCUS_NONE


static func make_button(text: String, color: Color, min_size: Vector2 = Vector2(0, 120), font_size: int = 44) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	style_button(b, color, Color.WHITE, font_size)
	return b


static func make_label(text: String, size: int = 40, color: Color = Palette.TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func make_circle(diameter: float, color: Color) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(diameter, diameter)
	p.size = Vector2(diameter, diameter)
	p.add_theme_stylebox_override("panel", box(color, int(diameter / 2.0), Color(0, 0, 0, 0), 0, false))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		ignore_mouse(child)
