class_name BinInfoPopup
extends Control
## Окно с подробностями о баке: что в него можно выбросить.

var _bin: Dictionary = {}

@onready var _dim: Panel = %Dim
@onready var _pic: TextureRect = %Pic
@onready var _title: Label = %Title
@onready var _scroll: ScrollContainer = %Scroll
@onready var _body: VBoxContainer = %Body
@onready var _ok: Button = %OkButton


func setup(bin: Dictionary) -> void:
	_bin = bin


func _ready() -> void:
	_pic.texture = ImageStore.get_texture(str(_bin.get("image", "")))
	_title.text = str(_bin.get("title", ""))
	_add_text(str(_bin.get("description", "")), false)
	var bullets: Variant = _bin.get("bullets", [])
	if bullets is Array:
		for b in bullets:
			_add_text("•  " + str(b), false)
	var footer: String = str(_bin.get("footer", ""))
	if not footer.is_empty():
		_add_text(footer, true)
	_ok.pressed.connect(dismiss)
	_dim.gui_input.connect(_on_dim_input)
	call_deferred("_fit_scroll")


func _add_text(value: String, muted: bool) -> void:
	if value.is_empty():
		return
	var l := Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if muted:
		l.theme_type_variation = &"MutedLabel"
	_body.add_child(l)


## Высота области текста = высота содержимого, но не больше 760 (дальше — прокрутка).
func _fit_scroll() -> void:
	var h: int = mini(int(_body.get_combined_minimum_size().y) + 8, 760)
	_scroll.custom_minimum_size.y = h


func dismiss() -> void:
	queue_free()


func _on_dim_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		dismiss()
