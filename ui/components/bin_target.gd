class_name BinTarget
extends PanelContainer
## Бак на экране игры — «мишень», в которую отпускают картинку отхода.

var bin_id: String = ""
var _data: Dictionary = {}
var _base_color: Color = Color.GRAY

@onready var _pic: TextureRect = %Pic
@onready var _name: Label = %Name


func setup(bin: Dictionary) -> void:
	_data = bin
	bin_id = str(bin.get("id", ""))
	_base_color = Color(str(bin.get("color", "#888888")))


func _ready() -> void:
	_pic.texture = ImageStore.get_texture(str(_data.get("image", "")))
	_name.text = str(_data.get("short", _data.get("title", "")))
	set_state("idle")


func contains_point(global_point: Vector2) -> bool:
	return get_global_rect().has_point(global_point)


## idle | hover | correct | wrong | dim
func set_state(state: String) -> void:
	var t: DesignTokens = Design.tokens
	var fill: Color = t.surface
	var border: Color = _base_color
	var width: int = t.border_width + 2
	modulate = Color.WHITE
	scale = Vector2.ONE
	match state:
		"hover":
			fill = _base_color.lerp(Color.WHITE, 0.7)
			width = t.border_width + 6
			scale = Vector2(1.06, 1.06)
		"correct":
			fill = t.success.lightened(0.55)
			border = t.success
			width = t.border_width + 6
		"wrong":
			fill = t.danger.lightened(0.55)
			border = t.danger
			width = t.border_width + 6
		"dim":
			modulate = Color(1, 1, 1, 0.45)
	pivot_offset = size / 2.0
	add_theme_stylebox_override("panel", ThemeBuilder.flat_box(fill, t.radius, border, width, 12, 12, t.shadow, t.shadow_size))
