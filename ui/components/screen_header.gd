class_name ScreenHeader
extends HBoxContainer
## Шапка экрана: кнопка «назад», заголовок, слот справа (right_slot) для своих кнопок.

signal back_pressed

@export var title: String = "":
	set(value):
		title = value
		if is_node_ready():
			_title.text = value
@export var show_back: bool = true

@onready var _back: Button = %BackButton
@onready var _title: Label = %Title
@onready var right_slot: HBoxContainer = %RightSlot


func _ready() -> void:
	_title.text = title
	_back.pressed.connect(_on_back_pressed)
	if not show_back:
		_back.modulate = Color(1, 1, 1, 0)
		_back.disabled = true


func _on_back_pressed() -> void:
	back_pressed.emit()
