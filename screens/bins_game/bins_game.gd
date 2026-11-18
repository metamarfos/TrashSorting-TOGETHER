extends BaseScreen
## Игра «Выбери бак»: картинку отхода перетаскивают пальцем и отпускают в нужный бак.
## Количество отходов за раунд и время на ответ задаются на вводном экране (Store).

const BinTargetScene := preload("res://ui/components/bin_target.tscn")
const GAME_ID := "bins"
const DELAY_OK := 0.9
const DELAY_WRONG := 2.4

@onready var _exit: Button = %ExitButton
@onready var _progress: Label = %Progress
@onready var _drag: DragItem = %Drag
@onready var _caption: AutoFitLabel = %Caption
@onready var _feedback: Label = %Feedback
@onready var _timer: RoundTimer = %Timer
@onready var _bins_box: HFlowContainer = %Bins

var _session: BinsSession
var _targets: Array[BinTarget] = []
var _hover: BinTarget = null
var _locked: bool = true
var _seconds: float = 10.0
var _advance: Timer


func _ready() -> void:
	var game: Dictionary = GameRegistry.get_game(GAME_ID)
	var rounds: int = Store.get_level_setting(GAME_ID, "rounds", int(game.get("rounds", 10)))
	_seconds = float(Store.get_level_setting(GAME_ID, "time_per_item", int(game.get("time_per_item", 10))))
	_advance = Timer.new()
	_advance.one_shot = true
	add_child(_advance)
	_advance.timeout.connect(_next_question)
	for b in BinDB.bins:
		var t: BinTarget = BinTargetScene.instantiate()
		t.setup(b)
		_bins_box.add_child(t)
		_targets.append(t)
	_exit.pressed.connect(_on_back)
	_timer.timeout.connect(_on_timeout)
	_drag.drag_moved.connect(_on_drag_moved)
	_drag.dropped.connect(_on_dropped)
	_session = BinsSession.new(WasteDB.get_playable(), rounds)
	if _session.total == 0:
		_caption.set_fit_text("В таблице нет отходов, подходящих для игры (нужны картинка и бак). Добавьте их в редакторе.")
		_feedback.text = ""
		_timer.visible = false
		return
	_next_question()


func _next_question() -> void:
	if not _session.has_next():
		_finish()
		return
	var item: WasteItem = _session.next_question()
	_progress.text = "%d / %d" % [_session.index, _session.total]
	_drag.set_texture(ImageStore.get_texture(item.image))
	_caption.set_fit_text(item.name)
	_feedback.text = ""
	_feedback.remove_theme_color_override("font_color")
	for t in _targets:
		t.set_state("idle")
	_hover = null
	_locked = false
	_drag.enabled = true
	_timer.start(_seconds)


func _target_at(point: Vector2) -> BinTarget:
	for t in _targets:
		if t.contains_point(point):
			return t
	return null


func _on_drag_moved(point: Vector2) -> void:
	if _locked:
		return
	var t: BinTarget = _target_at(point)
	if t == _hover:
		return
	if _hover != null:
		_hover.set_state("idle")
	_hover = t
	if _hover != null:
		_hover.set_state("hover")


func _on_dropped(point: Vector2) -> void:
	if _locked:
		return
	var t: BinTarget = _target_at(point)
	if _hover != null:
		_hover.set_state("idle")
	_hover = null
	if t == null:
		_drag.return_home()     # отпустили мимо бака — картинка возвращается
		return
	_drag.consume(t.global_position + t.size / 2.0)
	_resolve(t.bin_id)


func _on_timeout() -> void:
	if _locked:
		return
	_drag.cancel_drag()
	if _hover != null:
		_hover.set_state("idle")
		_hover = null
	_resolve("")


## Фиксирует ответ (bin_id = "" — время вышло), подсвечивает баки, планирует следующий вопрос.
func _resolve(bin_id: String) -> void:
	_locked = true
	_drag.enabled = false
	_timer.stop()
	var item: WasteItem = _session.current()
	var ok: bool = _session.answer(bin_id)
	for t in _targets:
		if item.bins.has(t.bin_id):
			t.set_state("correct")
		elif t.bin_id == bin_id:
			t.set_state("wrong")
		else:
			t.set_state("dim")
	_progress.text = "%d / %d" % [_session.index + 1, _session.total]
	if ok:
		_feedback.text = "Верно!"
		_feedback.add_theme_color_override("font_color", Design.tokens.success)
		Sfx.play("correct")
		_advance.start(DELAY_OK)
	else:
		var names := PackedStringArray()
		for id in item.bins:
			names.append(BinDB.title(id))
		var prefix: String = "Время вышло! " if bin_id.is_empty() else "Не туда. "
		_feedback.text = prefix + "Нужно: " + " или ".join(names)
		_feedback.add_theme_color_override("font_color", Design.tokens.danger)
		Sfx.play("wrong")
		_advance.start(DELAY_WRONG)


func _finish() -> void:
	Router.go("results", {
		"game_id": GAME_ID,
		"score": _session.score,
		"total": _session.total,
		"mistakes": _session.mistakes,
		"retry_screen": "bins_game",
	})


func _on_back() -> void:
	_timer.pause(true)
	var dlg := confirm("Выйти из игры?", "Результат этой партии не сохранится.", "Выйти", _leave, false, "Продолжить")
	dlg.closed.connect(_on_exit_dialog_closed)


func _leave() -> void:
	Router.go("menu")


func _on_exit_dialog_closed(was_confirmed: bool) -> void:
	if not was_confirmed:
		_timer.pause(false)
