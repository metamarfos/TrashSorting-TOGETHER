extends Node
## Автозагрузка «Store»: настройки и прогресс игрока (файл user://settings.cfg).

signal sound_changed(enabled: bool)

var _cfg := ConfigFile.new()
var _sound: bool = true

var sound_enabled: bool:
	get:
		return _sound
	set(value):
		_sound = value
		_cfg.set_value("settings", "sound", value)
		_save()
		sound_changed.emit(value)


func _ready() -> void:
	if _cfg.load(AppConfig.SETTINGS_PATH) == OK:
		_sound = bool(_cfg.get_value("settings", "sound", true))


## {"score": int, "total": int, "plays": int} — лучший результат по игре.
func get_best(game_id: String) -> Dictionary:
	var section: String = "game_" + game_id
	return {
		"score": int(_cfg.get_value(section, "best_score", 0)),
		"total": int(_cfg.get_value(section, "best_total", 0)),
		"plays": int(_cfg.get_value(section, "plays", 0)),
	}


## Сохраняет результат партии. Возвращает true, если это новый рекорд.
func record_result(game_id: String, score: int, total: int) -> bool:
	var section: String = "game_" + game_id
	var best := get_best(game_id)
	var old_ratio: float = 0.0
	if int(best["total"]) > 0:
		old_ratio = float(best["score"]) / float(best["total"])
	var new_ratio: float = 0.0
	if total > 0:
		new_ratio = float(score) / float(total)
	var is_best: bool = total > 0 and (int(best["total"]) == 0 or new_ratio > old_ratio)
	if is_best:
		_cfg.set_value(section, "best_score", score)
		_cfg.set_value(section, "best_total", total)
	_cfg.set_value(section, "plays", int(best["plays"]) + 1)
	_save()
	return is_best


## Настройки уровня, которые меняет пользователь (количество отходов, время и т.д.).
func get_level_setting(game_id: String, key: String, default_value: int) -> int:
	return int(_cfg.get_value("level_" + game_id, key, default_value))


func set_level_setting(game_id: String, key: String, value: int) -> void:
	_cfg.set_value("level_" + game_id, key, value)
	_save()


func _save() -> void:
	var err: Error = _cfg.save(AppConfig.SETTINGS_PATH)
	if err != OK:
		push_warning("Не удалось сохранить настройки: %s" % error_string(err))
