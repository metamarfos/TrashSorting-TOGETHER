class_name AutoFitLabel
extends Label
## Подпись, которая сама уменьшает шрифт, чтобы длинный текст уместился в max_height.
## Нужна для названий отходов: «Фильтры волокнистые на основе полимерных волокон, загрязнённые …».

@export var max_font_size: int = 48
@export var min_font_size: int = 22
@export var max_height: float = 200.0

var _last_key: String = ""


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resized.connect(_fit)
	_fit()


func set_fit_text(value: String) -> void:
	text = value
	_last_key = ""
	_fit()


func _fit() -> void:
	if not is_inside_tree() or size.x <= 1.0:
		return
	var key: String = "%s|%d" % [text, int(size.x)]
	if key == _last_key:
		return
	_last_key = key
	var font: Font = get_theme_font("font")
	if font == null:
		return
	var s: int = max_font_size
	while s > min_font_size:
		var h: float = font.get_multiline_string_size(text, horizontal_alignment, size.x, s).y
		if h <= max_height:
			break
		s -= 2
	add_theme_font_size_override("font_size", s)
