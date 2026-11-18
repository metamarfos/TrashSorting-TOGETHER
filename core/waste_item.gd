class_name WasteItem
extends RefCounted
## Одна запись таблицы отходов: фото + название + класс опасности + куда выбрасывать.

var id: String = ""
var name: String = ""
var hazard_class: int = 5
var bins: Array[String] = []
var image: String = ""   ## res://… (встроенные) или user://… (добавленные в редакторе)
var note: String = ""    ## служебная заметка для редакторов; в игре не показывается


static func from_dict(d: Dictionary) -> WasteItem:
	var it := WasteItem.new()
	it.id = str(d.get("id", ""))
	it.name = str(d.get("name", "")).strip_edges()
	it.hazard_class = clampi(int(d.get("hazard_class", 5)), 1, 5)
	it.image = str(d.get("image", ""))
	it.note = str(d.get("note", ""))
	var raw: Variant = d.get("bins", [])
	if raw is Array:
		for b in raw:
			var s: String = str(b)
			if not s.is_empty() and not it.bins.has(s):
				it.bins.append(s)
	return it


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"hazard_class": hazard_class,
		"bins": bins.duplicate(),
		"image": image,
		"note": note,
	}


func copy() -> WasteItem:
	return WasteItem.from_dict(to_dict())


func has_valid_image() -> bool:
	if image.is_empty():
		return false
	if image.begins_with("res://"):
		return ResourceLoader.exists(image)
	return FileAccess.file_exists(image)


## Список причин, по которым запись не попадёт в игру (пусто — запись годна).
func problems() -> Array[String]:
	var out: Array[String] = []
	if name.strip_edges().is_empty():
		out.append("нет названия")
	if not has_valid_image():
		out.append("нет картинки")
	if bins.is_empty():
		out.append("не выбран бак")
	return out


func is_playable() -> bool:
	return problems().is_empty()
