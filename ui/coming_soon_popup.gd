class_name ComingSoonPopup
extends Control
## Всплывающее окно «Скоро». Использование: ComingSoonPopup.open(self, "Название")

var _title: String = ""
var _message: String = "Этот раздел скоро появится!"


static func open(parent: Node, title: String, message: String = "Этот раздел скоро появится!") -> ComingSoonPopup:
	var p := ComingSoonPopup.new()
	p._title = title
	p._message = message
	parent.add_child(p)
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Palette.DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(840, 0)
	var sb := UIKit.box(Palette.CARD, 56)
	sb.set_content_margin_all(56)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 32)
	panel.add_child(col)

	col.add_child(UIKit.make_label(_title, 54, Palette.TEXT))
	col.add_child(UIKit.make_label(_message, 40, Palette.TEXT_SOFT))
	var ok := UIKit.make_button("Понятно", Palette.GREEN, Vector2(0, 120), 46)
	ok.pressed.connect(close)
	col.add_child(ok)

	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.15)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func close() -> void:
	queue_free()
