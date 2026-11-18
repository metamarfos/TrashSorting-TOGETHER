class_name Hazard
extends RefCounted
## Классы опасности отходов: римские цифры и подписи (по ТЗ: «I класс», а не «1»).

const ROMAN := ["", "I", "II", "III", "IV", "V"]
const TITLES := [
	"",
	"чрезвычайно опасные отходы",
	"высокоопасные отходы",
	"умеренно опасные отходы",
	"малоопасные отходы",
	"практически неопасные отходы",
]


static func is_valid(c: int) -> bool:
	return c >= 1 and c <= 5


static func roman(c: int) -> String:
	return str(ROMAN[c]) if is_valid(c) else "—"


## «III класс»
static func label(c: int) -> String:
	return "%s класс" % roman(c) if is_valid(c) else "класс не указан"


## «III класс — умеренно опасные отходы»
static func full(c: int) -> String:
	if not is_valid(c):
		return "класс не указан"
	return "%s класс — %s" % [roman(c), str(TITLES[c])]
