class_name BinsSession
extends RefCounted
## Логика одной партии «Выбери бак» (без интерфейса): подбор вопросов, проверка, счёт, ошибки.

var total: int = 0
var index: int = -1          ## номер текущего вопроса (с 0); пока идёт вопрос == числу уже пройденных
var score: int = 0
var questions: Array[WasteItem] = []
var mistakes: Array[Dictionary] = []


func _init(pool: Array[WasteItem], rounds: int) -> void:
	questions = pick(pool, rounds)
	total = questions.size()


## Случайная выборка. Сначала берём отходы с разными названиями, потом добираем повторы.
static func pick(pool: Array[WasteItem], rounds: int) -> Array[WasteItem]:
	var shuffled: Array[WasteItem] = []
	shuffled.append_array(pool)
	shuffled.shuffle()
	var out: Array[WasteItem] = []
	var seen := {}
	for it in shuffled:
		if out.size() >= rounds:
			break
		var key: String = it.name.to_lower()
		if not seen.has(key):
			seen[key] = true
			out.append(it)
	for it in shuffled:
		if out.size() >= rounds:
			break
		if not out.has(it):
			out.append(it)
	return out


func has_next() -> bool:
	return index + 1 < total


func next_question() -> WasteItem:
	index += 1
	return questions[index]


func current() -> WasteItem:
	if index < 0 or index >= total:
		return null
	return questions[index]


## Ответ: бак выбран (bin_id) или время вышло (""). Возвращает true, если верно.
func answer(bin_id: String) -> bool:
	var it: WasteItem = current()
	var ok: bool = not bin_id.is_empty() and it.bins.has(bin_id)
	if ok:
		score += 1
	else:
		mistakes.append({
			"id": it.id,
			"name": it.name,
			"image": it.image,
			"correct_bins": it.bins.duplicate(),
			"chosen": bin_id,
		})
	return ok
