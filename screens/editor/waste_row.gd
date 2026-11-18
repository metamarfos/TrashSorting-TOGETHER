class_name WasteRow
extends TapRow
## Строка таблицы отходов в редакторе: миниатюра, название, класс, баки, предупреждения.

var _item: WasteItem

@onready var _thumb: TextureRect = %Thumb
@onready var _name: Label = %Name
@onready var _tags: HFlowContainer = %Tags
@onready var _warn: Label = %Warn


func setup(item: WasteItem) -> void:
	_item = item


func get_item() -> WasteItem:
	return _item


func _ready() -> void:
	super._ready()
	_thumb.texture = ImageStore.get_texture(_item.image)
	_name.text = _item.name if not _item.name.is_empty() else "(без названия)"
	_tags.add_child(_make_tag(Hazard.label(_item.hazard_class), Design.hazard_color(_item.hazard_class)))
	for id in _item.bins:
		_tags.add_child(_make_tag(BinDB.short_name(id), BinDB.color(id).lerp(Color.WHITE, 0.55)))
	var problems: Array[String] = _item.problems()
	_warn.visible = not problems.is_empty()
	if not problems.is_empty():
		_warn.text = "Не участвует в игре: " + ", ".join(PackedStringArray(problems))


func _make_tag(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", ThemeBuilder.flat_box(color, 999, Color(0, 0, 0, 0), 0, 18, 6))
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"TagLabel"
	l.add_theme_color_override("font_color", Design.on_color(color))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p
