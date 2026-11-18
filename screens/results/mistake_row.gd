class_name MistakeRow
extends PanelContainer
## Строка «ошибки партии»: картинка, название и правильный бак.

var _data: Dictionary = {}

@onready var _pic: TextureRect = %Pic
@onready var _name: Label = %Name
@onready var _answer: Label = %Answer


func setup(data: Dictionary) -> void:
	_data = data


func _ready() -> void:
	_pic.texture = ImageStore.get_texture(str(_data.get("image", "")))
	_name.text = str(_data.get("name", ""))
	var names := PackedStringArray()
	var bins: Variant = _data.get("correct_bins", [])
	if bins is Array:
		for id in bins:
			names.append(BinDB.title(str(id)))
	_answer.text = "Правильно: " + " или ".join(names)
