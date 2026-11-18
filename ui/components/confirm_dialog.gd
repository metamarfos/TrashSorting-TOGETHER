class_name ConfirmDialog
extends Control
## Модальное окно подтверждения. Создаётся через BaseScreen.confirm().

signal confirmed
signal closed(was_confirmed: bool)

var _title: String = ""
var _message: String = ""
var _ok_text: String = "Ок"
var _cancel_text: String = "Отмена"
var _danger: bool = false

@onready var _title_label: Label = %Title
@onready var _message_label: Label = %Message
@onready var _ok: Button = %OkButton
@onready var _cancel: Button = %CancelButton
@onready var _dim: Panel = %Dim


func setup(title_text: String, message: String, ok_text: String, cancel_text: String, danger: bool) -> void:
	_title = title_text
	_message = message
	_ok_text = ok_text
	_cancel_text = cancel_text
	_danger = danger


func _ready() -> void:
	_title_label.text = _title
	_message_label.text = _message
	_message_label.visible = not _message.is_empty()
	_ok.text = _ok_text
	_cancel.text = _cancel_text
	if _danger:
		_ok.theme_type_variation = &"DangerButton"
	_ok.pressed.connect(_on_ok)
	_cancel.pressed.connect(dismiss)
	_dim.gui_input.connect(_on_dim_input)


func dismiss() -> void:
	closed.emit(false)
	queue_free()


func _on_ok() -> void:
	confirmed.emit()
	closed.emit(true)
	queue_free()


func _on_dim_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		dismiss()
