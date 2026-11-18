extends Node
## Автозагрузка «WasteDB»: таблица отходов с созданием / изменением / удалением записей.
##
## Первый запуск: копируем встроенную таблицу res://data/waste_default.json в user://waste.json.
## Дальше приложение работает с копией — именно её правит редактор.
## Любое изменение сразу сохраняется на диск и рассылает сигнал `changed`.

signal changed

var items: Array[WasteItem] = []


func _ready() -> void:
	load_db()


func load_db() -> void:
	items.clear()
	var data: Variant = JsonUtil.read_file(AppConfig.WASTE_USER_PATH)
	if data is Dictionary and data.get("items") is Array:
		_fill(data)
	else:
		if FileAccess.file_exists(AppConfig.WASTE_USER_PATH):
			# Файл есть, но повреждён: сохраняем его рядом и начинаем с исходной таблицы.
			push_warning("Таблица отходов повреждена — восстанавливаю исходную.")
			DirAccess.rename_absolute(AppConfig.WASTE_USER_PATH, AppConfig.WASTE_USER_PATH + ".broken")
		_load_defaults()
		save()
	changed.emit()


func _load_defaults() -> void:
	items.clear()
	var data: Variant = JsonUtil.read_file(AppConfig.WASTE_DEFAULT_PATH)
	if data is Dictionary and data.get("items") is Array:
		_fill(data)
	else:
		push_error("Не найдена исходная таблица отходов: %s" % AppConfig.WASTE_DEFAULT_PATH)


func _fill(data: Dictionary) -> void:
	var arr: Array = data["items"]
	for d in arr:
		if d is Dictionary:
			var it := WasteItem.from_dict(d)
			if it.id.is_empty():
				it.id = _new_id()
			items.append(it)


func save() -> bool:
	var arr: Array = []
	for it in items:
		arr.append(it.to_dict())
	return JsonUtil.write_file(AppConfig.WASTE_USER_PATH, {"version": AppConfig.DB_VERSION, "items": arr})


# ------------------------------------------------------------------ чтение

func get_item(id: String) -> WasteItem:
	for it in items:
		if it.id == id:
			return it
	return null


## Записи, пригодные для игры: есть название, картинка и хотя бы один бак.
func get_playable() -> Array[WasteItem]:
	var out: Array[WasteItem] = []
	for it in items:
		if it.is_playable():
			out.append(it)
	return out


## Поиск для редактора. class_filter: 0 — любой; bin_filter: "" — любой.
func filter(query: String, class_filter: int, bin_filter: String) -> Array[WasteItem]:
	var q: String = query.strip_edges().to_lower()
	var out: Array[WasteItem] = []
	for it in items:
		if class_filter != 0 and it.hazard_class != class_filter:
			continue
		if not bin_filter.is_empty() and not it.bins.has(bin_filter):
			continue
		if not q.is_empty() and not it.name.to_lower().contains(q):
			continue
		out.append(it)
	return out


# ------------------------------------------------------------------ запись

## Создаёт запись (если id пустой) или обновляет существующую. Новые записи — в начало списка.
func upsert(item: WasteItem) -> void:
	var old_image: String = ""
	var idx: int = -1
	if item.id.is_empty():
		item.id = _new_id()
	else:
		idx = _index_of(item.id)
	if idx >= 0:
		old_image = items[idx].image
		items[idx] = item
	else:
		items.push_front(item)
	save()
	if old_image != item.image:
		gc_image(old_image)
	changed.emit()


func delete_item(id: String) -> void:
	var idx: int = _index_of(id)
	if idx < 0:
		return
	var old_image: String = items[idx].image
	items.remove_at(idx)
	save()
	gc_image(old_image)
	changed.emit()


## Возвращает исходную таблицу и удаляет все добавленные пользователем картинки.
func reset_to_defaults() -> void:
	var old_images: Array[String] = []
	for it in items:
		old_images.append(it.image)
	_load_defaults()
	save()
	for p in old_images:
		gc_image(p)
	changed.emit()


## Удаляет файл картинки из user://, если на него больше никто не ссылается.
func gc_image(path: String) -> void:
	if path.is_empty() or not path.begins_with(AppConfig.USER_IMAGES_DIR):
		return
	for it in items:
		if it.image == path:
			return
	ImageStore.delete_user_image(path)


# ------------------------------------------------------------------ служебное

func _index_of(id: String) -> int:
	for i in items.size():
		if items[i].id == id:
			return i
	return -1


func _new_id() -> String:
	var id: String = ""
	while id.is_empty() or _index_of(id) >= 0:
		id = "u%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]
	return id
