extends Control
## Заглушка игры «Выбери бак». Полноценный игровой экран появится на Этапе 2.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(860, 0)
	col.add_theme_constant_override("separation", 40)
	center.add_child(col)

	col.add_child(UIKit.make_label("Выбери бак", 96, Palette.GREEN_DARK))
	col.add_child(UIKit.make_label("Игровой экран появится на следующем этапе разработки.", 42, Palette.TEXT_SOFT))
	var back := UIKit.make_button("В меню", Palette.GREEN, Vector2(0, 130), 46)
	back.pressed.connect(on_back_requested)
	col.add_child(back)


func on_back_requested() -> void:
	SceneRouter.go_back()
