class_name BinView
extends DropZone
## Визуальный бак (рисуется кодом) + зона приёма. Данные берутся из data/containers.json.

var data: Dictionary = {}
var color: Color = Palette.GREEN

var _label: Label
var _flash_color: Color = Palette.GREEN
var _flash_alpha: float = 0.0:
	set(value):
		_flash_alpha = value
		queue_redraw()


func setup(container: Dictionary) -> void:
	data = container
	zone_id = str(container.get("id", ""))
	color = Color(str(container.get("color", "#2BA66B")))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0
	resized.connect(_on_resized)

	_label = UIKit.make_label(str(data.get("label", data.get("name", ""))), 34, Color.WHITE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.anchor_top = 0.5
	_label.offset_top = 0.0
	_label.offset_left = 12.0
	_label.offset_right = -12.0
	_label.offset_bottom = -12.0


func _on_resized() -> void:
	pivot_offset = size / 2.0
	queue_redraw()


## Вспышка обратной связи: зелёная (верно) или красная (неверно).
func flash(good: bool) -> void:
	_flash_color = Palette.GREEN if good else Palette.RED
	var t := create_tween()
	t.tween_property(self, "_flash_alpha", 0.0, 0.55).from(0.75)


func _on_hover_changed(on: bool) -> void:
	queue_redraw()
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE * (1.06 if on else 1.0), 0.12)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var lid_h := 56.0
	var body_rect := Rect2(0, lid_h * 0.7, w, h - lid_h * 0.7)

	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.set_corner_radius_all(30)
	draw_style_box(body, body_rect)

	var lid := StyleBoxFlat.new()
	lid.bg_color = color.darkened(0.22)
	lid.set_corner_radius_all(22)
	draw_style_box(lid, Rect2(-8, 0, w + 16, lid_h))

	if zone_id == "hazard":
		var cx := w / 2.0
		var cy := lid_h + (h - lid_h) * 0.22
		var r := 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - r), Vector2(cx + r, cy + r * 0.8), Vector2(cx - r, cy + r * 0.8)]), Color("#FFD23F"))
		draw_string(ThemeDB.fallback_font, Vector2(cx - 40.0, cy + r * 0.62), "!", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 48, Palette.TEXT)

	if _flash_alpha > 0.0:
		var overlay := StyleBoxFlat.new()
		overlay.bg_color = Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha)
		overlay.set_corner_radius_all(30)
		draw_style_box(overlay, body_rect)

	if hovered:
		var outline := StyleBoxFlat.new()
		outline.draw_center = false
		outline.border_color = Color.WHITE
		outline.set_border_width_all(10)
		outline.set_corner_radius_all(30)
		draw_style_box(outline, body_rect)
