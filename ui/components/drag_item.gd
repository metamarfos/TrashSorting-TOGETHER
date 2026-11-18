class_name DragItem
extends Control
## Картинка отхода, которую можно перетащить пальцем и отпустить в бак.
##
## Пока палец на экране, «призрак» картинки следует за ним (чуть выше пальца, чтобы было видно).
## Сигналы:  drag_moved(центр_призрака)  — в процессе;  dropped(центр_призрака) — палец отпущен.
## После dropped игра вызывает consume(цель) (принято) или return_home() (вернуть на место).

signal drag_started
signal drag_moved(point: Vector2)
signal dropped(point: Vector2)

@export var ghost_size: float = 340.0
@export var finger_offset: float = 150.0   ## насколько призрак приподнят над пальцем

var enabled: bool = false
var _texture: Texture2D
var _dragging: bool = false
var _tween: Tween

@onready var _holder: TextureRect = %Holder
@onready var _ghost: TextureRect = %Ghost


func _ready() -> void:
	_ghost.top_level = true
	_ghost.visible = false
	set_process_input(false)


func set_texture(tex: Texture2D) -> void:
	_texture = tex
	_holder.texture = tex
	_ghost.texture = tex
	_reset_visuals()


func _reset_visuals() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_dragging = false
	set_process_input(false)
	_ghost.visible = false
	_ghost.modulate = Color.WHITE
	_holder.modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	if not enabled or _texture == null:
		return
	_dragging = true
	set_process_input(true)
	_holder.modulate = Color(1, 1, 1, 0.25)
	_ghost.size = Vector2(ghost_size, ghost_size)
	_ghost.scale = Vector2.ONE
	_ghost.pivot_offset = _ghost.size / 2.0
	_ghost.modulate = Color.WHITE
	_ghost.visible = true
	_move_ghost(mb.global_position)
	drag_started.emit()
	accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		_move_ghost(mm.global_position)
		drag_moved.emit(ghost_center())
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_dragging = false
		set_process_input(false)
		_move_ghost(mb.global_position)
		dropped.emit(ghost_center())


func ghost_center() -> Vector2:
	return _ghost.global_position + _ghost.size / 2.0


func _move_ghost(pointer: Vector2) -> void:
	_ghost.global_position = pointer - _ghost.size / 2.0 - Vector2(0, finger_offset)


## Отмена перетаскивания (например, вышло время).
func cancel_drag() -> void:
	_reset_visuals()


## Отпустили мимо бака — картинка плавно возвращается на место.
func return_home() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var home: Vector2 = _holder.global_position + _holder.size / 2.0 - _ghost.size / 2.0
	_tween = create_tween()
	_tween.tween_property(_ghost, "global_position", home, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_reset_visuals)


## Отпустили в бак — картинка «падает» в него и исчезает.
func consume(target_center: Vector2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var dest: Vector2 = target_center - _ghost.size / 2.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_ghost, "global_position", dest, 0.2)
	_tween.tween_property(_ghost, "scale", Vector2(0.2, 0.2), 0.2)
	_tween.tween_property(_ghost, "modulate:a", 0.0, 0.2)
	_tween.chain().tween_callback(_ghost.hide)
