extends Node
## Автозагрузка «ImageStore»: загрузка картинок отходов и импорт пользовательских картинок.
##
## * res://… — встроенные картинки (импортируются движком);
## * user://… — картинки, добавленные в редакторе (копии лежат в user://waste_images).
## * content://… (Android) — выбор через системное окно; читаем байты и копируем к себе.

const CACHE_MAX := 24

var _cache: Dictionary = {}          # путь -> Texture2D
var _order: Array[String] = []       # порядок использования (для вытеснения)


func get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if path.begins_with("res://"):
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
	else:
		var img := load_image_file(path)
		if img != null:
			tex = ImageTexture.create_from_image(img)
	if tex != null:
		_remember(path, tex)
	return tex


func forget(path: String) -> void:
	_cache.erase(path)
	_order.erase(path)


## Читает картинку из любого пути (в том числе content:// на Android). null — если не получилось.
func load_image_file(path: String) -> Image:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 12:
		return null
	var img := Image.new()
	var err: Error = ERR_FILE_UNRECOGNIZED
	if bytes[0] == 0x89 and bytes[1] == 0x50:                       # PNG
		err = img.load_png_from_buffer(bytes)
	elif bytes[0] == 0xFF and bytes[1] == 0xD8:                     # JPEG
		err = img.load_jpg_from_buffer(bytes)
	elif bytes[0] == 0x52 and bytes[1] == 0x49 and bytes[8] == 0x57:  # RIFF....WEBP
		err = img.load_webp_from_buffer(bytes)
	else:
		err = img.load_png_from_buffer(bytes)
		if err != OK:
			err = img.load_jpg_from_buffer(bytes)
		if err != OK:
			err = img.load_webp_from_buffer(bytes)
	if err != OK or img.is_empty():
		return null
	return img


## Копирует выбранную пользователем картинку в user://waste_images (с уменьшением).
## Возвращает путь к копии или "" при ошибке.
func import_user_image(source_path: String) -> String:
	var img := load_image_file(source_path)
	if img == null:
		return ""
	var longest: int = maxi(img.get_width(), img.get_height())
	if longest > AppConfig.MAX_USER_IMAGE_SIDE:
		var k: float = float(AppConfig.MAX_USER_IMAGE_SIDE) / float(longest)
		img.resize(maxi(1, roundi(img.get_width() * k)), maxi(1, roundi(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(AppConfig.USER_IMAGES_DIR)
	var base: String = "%s/img_%d_%d" % [AppConfig.USER_IMAGES_DIR, int(Time.get_unix_time_from_system()), randi() % 100000]
	var out_path: String
	var err: Error
	if img.detect_alpha() != Image.ALPHA_NONE:
		out_path = base + ".png"
		err = img.save_png(out_path)
	else:
		img.convert(Image.FORMAT_RGB8)
		out_path = base + ".jpg"
		err = img.save_jpg(out_path, 0.9)
	if err != OK:
		push_error("Не удалось сохранить картинку: %s" % error_string(err))
		return ""
	return out_path


## Удаляет файл картинки, если он лежит в нашей пользовательской папке.
func delete_user_image(path: String) -> void:
	forget(path)
	if path.begins_with(AppConfig.USER_IMAGES_DIR) and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _remember(path: String, tex: Texture2D) -> void:
	_cache[path] = tex
	_order.erase(path)
	_order.append(path)
	while _order.size() > CACHE_MAX:
		var oldest: String = _order.pop_front()
		_cache.erase(oldest)
