class_name GameSession
extends RefCounted
## Логика раунда «Выбери бак» без привязки к интерфейсу:
## очередь отходов, проверка ответа, счёт. (Время и попытки добавятся на Этапе 3.)

var items: Array = []
var index: int = 0
var correct_count: int = 0
var mistakes: int = 0


func _init(round_items: Array) -> void:
	items = round_items


func total() -> int:
	return items.size()


func is_empty() -> bool:
	return items.is_empty()


func current() -> Dictionary:
	return items[index]


## Верно ли выбран бак: допускается любой из accepted_bins (или единственный correct_bin).
func is_correct(item: Dictionary, bin_id: String) -> bool:
	var accepted: Array = item.get("accepted_bins", [])
	if accepted.is_empty():
		accepted = [item.get("correct_bin", "")]
	return accepted.has(bin_id)


func register_correct() -> void:
	correct_count += 1


func register_mistake() -> void:
	mistakes += 1


## Переходит к следующему отходу. false, если раунд закончен.
func advance() -> bool:
	index += 1
	return index < items.size()
