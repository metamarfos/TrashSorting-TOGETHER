extends Node
## Автозагрузка «BinDB»: справочник баков из data/bins.json.

var bins: Array[Dictionary] = []
var _by_id: Dictionary = {}


func _ready() -> void:
	var data: Variant = JsonUtil.read_file(AppConfig.BINS_PATH)
	if data is Dictionary:
		var arr: Variant = data.get("bins", [])
		if arr is Array:
			for b in arr:
				if b is Dictionary:
					bins.append(b)
					_by_id[str(b.get("id", ""))] = b
	if bins.is_empty():
		push_error("Не удалось загрузить справочник баков: %s" % AppConfig.BINS_PATH)


func get_bin(id: String) -> Dictionary:
	return _by_id.get(id, {})


func title(id: String) -> String:
	return str(get_bin(id).get("title", id))


func short_name(id: String) -> String:
	var b: Dictionary = get_bin(id)
	return str(b.get("short", b.get("title", id)))


func color(id: String) -> Color:
	return Color(str(get_bin(id).get("color", "#888888")))
