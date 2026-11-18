class_name JsonUtil
extends RefCounted
## Чтение и запись JSON-файлов.


## Возвращает разобранные данные (Dictionary/Array) или null, если файла нет / он повреждён.
static func read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text: String = FileAccess.get_file_as_string(path)
	if text.strip_edges().is_empty():
		return null
	return JSON.parse_string(text)


## Записывает JSON через временный файл, чтобы не потерять данные при сбое.
static func write_file(path: String, data: Variant) -> bool:
	var text: String = JSON.stringify(data, "\t")
	var tmp: String = path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Не удалось открыть файл для записи: %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(text)
	f.close()
	if DirAccess.rename_absolute(tmp, path) == OK:
		return true
	# Некоторые платформы не перезаписывают существующий файл при переименовании.
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(tmp, path) == OK:
		return true
	var direct := FileAccess.open(path, FileAccess.WRITE)
	if direct == null:
		push_error("Не удалось записать файл: %s" % path)
		return false
	direct.store_string(text)
	direct.close()
	DirAccess.remove_absolute(tmp)
	return true
