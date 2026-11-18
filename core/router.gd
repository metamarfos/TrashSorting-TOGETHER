extends Node
## Автозагрузка «Router»: переходы между экранами (с плавным затемнением),
## передача параметров и кнопка «Назад» Android.
##
## Чтобы добавить экран: положите .tscn и пропишите его id в SCREENS ниже.
## Из любого места:  Router.go("bins_game", {"что": "угодно"})
## В целевом экране параметры лежат в Router.params.

const SCREENS := {
	"menu": "res://screens/main_menu/main_menu.tscn",
	"bins_intro": "res://screens/bins_intro/bins_intro.tscn",
	"bins_game": "res://screens/bins_game/bins_game.tscn",
	"results": "res://screens/results/results.tscn",
	"waste_editor": "res://screens/editor/waste_editor.tscn",
	"waste_form": "res://screens/editor/waste_form.tscn",
}

var params: Dictionary = {}

var _busy: bool = false
var _layer: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c: Color = Design.tokens.bg
	_fade.color = Color(c.r, c.g, c.b, 0.0)
	_layer.add_child(_fade)


func go(screen_id: String, p: Dictionary = {}) -> void:
	if _busy:
		return
	if not SCREENS.has(screen_id):
		push_error("Router: неизвестный экран «%s»" % screen_id)
		return
	_busy = true
	params = p
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP   # блокируем нажатия на время перехода
	await _fade_to(1.0)
	var err: Error = get_tree().change_scene_to_file(SCREENS[screen_id])
	if err != OK:
		push_error("Router: не удалось открыть «%s»: %s" % [screen_id, error_string(err)])
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, Design.tokens.transition_time)
	await tween.finished


## Кнопка «Назад» (Android) и Esc (ПК) — передаём текущему экрану.
func handle_back() -> void:
	if _busy:
		return
	var screen: Node = get_tree().current_scene
	if screen != null and screen.has_method("on_back_requested"):
		screen.call("on_back_requested")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back()
