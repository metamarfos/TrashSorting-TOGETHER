extends Node
## Settings (автозагрузка): настройки уровня и приложения.
## Значения по умолчанию и пресеты берутся из data/config.json,
## изменения пользователя сохраняются в user://settings.json.

signal changed(key: String)

const CONFIG_PATH := "res://data/config.json"
const USER_PATH := "user://settings.json"

var defaults: Dictionary = {}
var presets: Dictionary = {}
var values: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	var cfg := _read_json(CONFIG_PATH)
	defaults = _normalize_dict(cfg.get("game_defaults", {}))
	presets = cfg.get("presets", {})
	values = defaults.duplicate()
	var user := _read_json(USER_PATH)
	for k in user.keys():
		if defaults.has(k):
			values[k] = _normalize(user[k])


func get_value(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)


func set_value(key: String, value: Variant) -> void:
	values[key] = value
	save()
	changed.emit(key)


func apply_preset(preset_id: String) -> void:
	if not presets.has(preset_id):
		return
	var p: Dictionary = presets[preset_id]
	for k in p.keys():
		if k != "label" and defaults.has(k):
			values[k] = _normalize(p[k])
	save()
	changed.emit("*")


func reset_to_defaults() -> void:
	values = defaults.duplicate()
	save()
	changed.emit("*")


func save() -> void:
	var f := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Settings: не удалось сохранить " + USER_PATH)
		return
	f.store_string(JSON.stringify(values, "\t"))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		return data
	return {}


# JSON в Godot читает все числа как float; приводим целые к int.
func _normalize(v: Variant) -> Variant:
	if v is float and is_equal_approx(v, roundf(v)):
		return int(v)
	return v


func _normalize_dict(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d.keys():
		out[k] = _normalize(d[k])
	return out
