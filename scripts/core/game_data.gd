class_name GameData
extends RefCounted
## Загрузка данных для игры. На Этапе 4 источник отходов заменится на WasteDB
## (база + пользовательские правки); интерфейс pick_round останется прежним.

const CONTAINERS_PATH := "res://data/containers.json"
const TEST_WASTE_PATH := "res://data/test_waste.json"


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("GameData: нет файла " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


static func load_containers() -> Array:
	var d: Variant = load_json(CONTAINERS_PATH)
	if d is Dictionary and (d as Dictionary).has("containers"):
		return (d as Dictionary)["containers"]
	return []


static func load_waste(path: String = TEST_WASTE_PATH) -> Array:
	var d: Variant = load_json(path)
	if d is Dictionary and (d as Dictionary).has("items"):
		return (d as Dictionary)["items"]
	return []


## Выбирает отходы на раунд. count <= 0 или больше доступного = все.
static func pick_round(items: Array, count: int, order: String) -> Array:
	var pool: Array = items.duplicate()
	if order == "random":
		pool.shuffle()
	var n := count
	if n <= 0 or n > pool.size():
		n = pool.size()
	return pool.slice(0, n)
