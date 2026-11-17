class_name DropZone
extends Control
## Универсальная зона приёма. Определяет попадание точки (с запасом hit_margin)
## и умеет подсвечиваться. Конкретный вид задаёт наследник (например, BinView).

@export var zone_id: String = ""
@export var hit_margin: float = 10.0

var hovered: bool = false


func contains_point(global_pos: Vector2) -> bool:
	return get_global_rect().grow(hit_margin).has_point(global_pos)


func set_hover(on: bool) -> void:
	if on == hovered:
		return
	hovered = on
	_on_hover_changed(on)


func _on_hover_changed(_on: bool) -> void:
	pass
