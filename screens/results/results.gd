extends BaseScreen
## Итоги партии: звёзды, счёт, рекорд, список ошибок. Параметры берёт из Router.params.

const MistakeRowScene := preload("res://screens/results/mistake_row.tscn")

@onready var _message: Label = %Message
@onready var _stars: Label = %Stars
@onready var _score: Label = %Score
@onready var _best: Label = %Best
@onready var _mistakes_title: Label = %MistakesTitle
@onready var _mistakes: VBoxContainer = %Mistakes
@onready var _again: Button = %AgainButton
@onready var _menu: Button = %MenuButton

var _retry_screen: String = "menu"


func _ready() -> void:
	var p: Dictionary = Router.params
	var game_id: String = str(p.get("game_id", ""))
	var score: int = int(p.get("score", 0))
	var total: int = int(p.get("total", 0))
	_retry_screen = str(p.get("retry_screen", "menu"))
	var ratio: float = float(score) / float(maxi(total, 1))
	var stars: int = 0
	var msg: String = "Давай потренируемся!"
	if ratio >= 0.9:
		stars = 3
		msg = "Отлично!"
	elif ratio >= 0.6:
		stars = 2
		msg = "Хорошо!"
	elif ratio >= 0.3:
		stars = 1
		msg = "Неплохо, попробуй ещё!"
	_message.text = msg
	_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_stars.add_theme_color_override("font_color", Design.tokens.accent)
	_score.text = "%d / %d" % [score, total]
	var new_best: bool = Store.record_result(game_id, score, total)
	if new_best:
		_best.text = "Новый рекорд!"
	else:
		var b: Dictionary = Store.get_best(game_id)
		_best.text = "Рекорд: %d / %d" % [int(b["score"]), int(b["total"])]
	Sfx.play("win" if stars >= 2 else "finish")
	var mistakes: Variant = p.get("mistakes", [])
	if mistakes is Array and not mistakes.is_empty():
		for m in mistakes:
			var row: MistakeRow = MistakeRowScene.instantiate()
			row.setup(m)
			_mistakes.add_child(row)
	else:
		_mistakes_title.visible = false
	_again.pressed.connect(_on_again)
	_menu.pressed.connect(_on_back)


func _on_again() -> void:
	Router.go(_retry_screen)
