class_name GameModes
extends RefCounted
## Реестр игровых режимов. Читает data/modes.json.
## Новый режим добавляется строкой в JSON (+ своя сцена), код меню менять не нужно.

const MODES_PATH := "res://data/modes.json"


static func load_modes() -> Array:
	if not FileAccess.file_exists(MODES_PATH):
		push_error("GameModes: нет файла " + MODES_PATH)
		return []
	var f := FileAccess.open(MODES_PATH, FileAccess.READ)
	if f == null:
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Dictionary and (data as Dictionary).has("modes"):
		return (data as Dictionary)["modes"]
	push_error("GameModes: некорректный формат modes.json")
	return []
