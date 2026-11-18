class_name TapRow
extends PanelContainer
## Нажимаемая строка списка, дружелюбная к прокрутке пальцем.
##
## Обычные Button в ScrollContainer «съедают» касание и мешают прокручивать список,
## а после прокрутки срабатывают ложным нажатием. TapRow пропускает касания к
## ScrollContainer и считает «тапом» только короткое касание без сдвига.

signal tapped

@export var tap_slop: float = 28.0   ## на сколько пикселей можно сдвинуть палец, чтобы это всё ещё был тап

var _pressing: bool = false
var _press_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_pressing = true
			_press_pos = mb.global_position
			modulate = Color(0.93, 0.93, 0.93, 1.0)
		else:
			modulate = Color.WHITE
			if _pressing and mb.global_position.distance_to(_press_pos) <= tap_slop:
				Sfx.play("click")
				tapped.emit()
			_pressing = false
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _pressing:
		if mm.global_position.distance_to(_press_pos) > tap_slop:
			_pressing = false
			modulate = Color.WHITE
