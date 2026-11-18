class_name BinRow
extends TapRow
## Строка списка баков на вводном экране.

var _bin: Dictionary = {}

@onready var _pic: TextureRect = %Pic
@onready var _title: Label = %Title


func setup(bin: Dictionary) -> void:
	_bin = bin


func get_bin() -> Dictionary:
	return _bin


func _ready() -> void:
	super._ready()
	_pic.texture = ImageStore.get_texture(str(_bin.get("image", "")))
	_title.text = str(_bin.get("title", ""))
