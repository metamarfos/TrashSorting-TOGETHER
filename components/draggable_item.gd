class_name DraggableItem
extends Control
## Универсальный перетаскиваемый объект (не знает ни про картинки, ни про баки).
## Игра добавляет визуал дочерними узлами (с mouse_filter = IGNORE) и подписывается на сигналы.
## Ввод: мышь; на Android касание пальцем автоматически эмулируется как левая кнопка мыши.

signal drag_started
signal drag_moved(finger_pos: Vector2, item_center: Vector2)
signal drag_released(finger_pos: Vector2, item_center: Vector2)
signal drag_cancelled

@export var lift_scale: float = 1.08
@export var drag_z_index: int = 50

## Позиция "дома" в локальных координатах родителя; сюда объект возвращается.
var home_position: Vector2 = Vector2.ZERO
var dragging: bool = false
var enabled: bool = true:
	set(value):
		enabled = value
		if not value and dragging:
			cancel_drag()

var _grab_offset: Vector2 = Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size / 2.0
	resized.connect(_on_resized)


func _on_resized() -> void:
	pivot_offset = size / 2.0


func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed and not dragging:
			_begin_drag()
		elif not mb.pressed and dragging:
			_end_drag()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		_follow()
		accept_event()


func _begin_drag() -> void:
	dragging = true
	_kill_tween()
	z_index = drag_z_index
	_grab_offset = get_global_mouse_position() - global_position
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * lift_scale, 0.12)
	drag_started.emit()


func _follow() -> void:
	var finger := get_global_mouse_position()
	global_position = finger - _grab_offset
	drag_moved.emit(finger, _center())


func _end_drag() -> void:
	dragging = false
	drag_released.emit(get_global_mouse_position(), _center())


## Отмена перетаскивания (потеря фокуса, отключение объекта): объект возвращается домой.
func cancel_drag() -> void:
	if not dragging:
		return
	dragging = false
	drag_cancelled.emit()
	return_home()


## Плавный возврат на исходную позицию.
func return_home(duration: float = 0.28) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", home_position, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, duration)
	_tween.chain().tween_callback(_reset_z)


## Мгновенный сброс состояния (перед показом следующего объекта).
func reset_state() -> void:
	_kill_tween()
	dragging = false
	position = home_position
	scale = Vector2.ONE
	modulate.a = 1.0
	z_index = 0


func _reset_z() -> void:
	z_index = 0


func _center() -> Vector2:
	return global_position + size / 2.0


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if dragging:
			cancel_drag()
