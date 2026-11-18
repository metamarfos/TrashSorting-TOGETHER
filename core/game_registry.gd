extends Node
## Автозагрузка «GameRegistry»: список игр главного меню из data/games.json.

var badge_text: String = "Скоро"
var games: Array[Dictionary] = []


func _ready() -> void:
	var data: Variant = JsonUtil.read_file(AppConfig.GAMES_PATH)
	if not (data is Dictionary):
		push_error("Не удалось загрузить список игр: %s" % AppConfig.GAMES_PATH)
		return
	badge_text = str(data.get("badge", badge_text))
	var arr: Variant = data.get("games", [])
	if arr is Array:
		for g in arr:
			if g is Dictionary:
				games.append(g)


func get_game(id: String) -> Dictionary:
	for g in games:
		if str(g.get("id", "")) == id:
			return g
	return {}
