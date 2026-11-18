class_name RoundTimer
extends VBoxContainer
## Счётчик секунд + полоса времени (зелёная — осталось, красная — прошло).

signal timeout

var duration: float = 10.0
var _left: float = 0.0
var _running: bool = false
var _paused: bool = false

@onready var _label: Label = %SecondsLabel
@onready var _bar: ProgressBar = %Bar


func start(seconds: float) -> void:
	duration = maxf(0.5, seconds)
	_left = duration
	_running = true
	_paused = false
	_refresh()


func stop() -> void:
	_running = false


func pause(value: bool) -> void:
	_paused = value


func _process(delta: float) -> void:
	if not _running or _paused:
		return
	_left -= delta
	if _left <= 0.0:
		_left = 0.0
		_running = false
		_refresh()
		timeout.emit()
		return
	_refresh()


func _refresh() -> void:
	_bar.value = _left / duration
	_label.text = str(ceili(_left))
	if _left <= 3.0:
		_label.add_theme_color_override("font_color", Design.tokens.danger)
	else:
		_label.remove_theme_color_override("font_color")
