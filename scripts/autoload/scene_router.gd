extends Node
## SceneRouter (автозагрузка): переходы между сценами с затемнением,
## история "назад" и обработка кнопки "Назад" Android (и Esc на ПК).

signal scene_changed(path: String)

const FADE_TIME := 0.18
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

var _layer: CanvasLayer
var _fade: ColorRect
var _busy: bool = false
var _history: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Palette.BG
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade)


func change_scene(path: String, remember: bool = true) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: сцена не найдена: " + path)
		return
	_busy = true
	if remember:
		var cur := get_tree().current_scene
		if cur != null and cur.scene_file_path != "":
			_history.append(cur.scene_file_path)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await t.finished
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: ошибка загрузки сцены " + path)
	await get_tree().process_frame
	await get_tree().process_frame
	t = create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await t.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	scene_changed.emit(path)


func go_back() -> void:
	if _history.is_empty():
		change_scene(MENU_SCENE, false)
		return
	var path: String = _history.pop_back()
	change_scene(path, false)


func go_to_menu() -> void:
	_history.clear()
	change_scene(MENU_SCENE, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back()


func _handle_back() -> void:
	if _busy:
		return
	var cur := get_tree().current_scene
	if cur != null and cur.has_method("on_back_requested"):
		cur.call("on_back_requested")
	else:
		go_back()
