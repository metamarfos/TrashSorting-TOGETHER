extends Control
## Игра «Выбери бак»: перетащи отход пальцем в нужный бак.
## Логика раунда в GameSession, перетаскивание в DraggableItem, зоны в BinView.

const HINT_TEXT := "Перетащи отход в нужный бак"
const CARD_MAX := 470.0
const CAPTION_H := 170.0
const HINT_H := 70.0

var _session: GameSession
var _zones: Array[BinView] = []
var _hover_zone: BinView = null
var _busy: bool = false
var _hint_token: int = 0

var _area: Control
var _hint: Label
var _caption: Label
var _item: DraggableItem
var _item_image: TextureRect
var _progress: Label
var _overlay: Control = null


func _ready() -> void:
	_build_ui()
	_start_round()


# ---------------------------------------------------------------- интерфейс

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_bottom", 48)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# Верхняя панель: выход и "Пройдено / Всего"
	var top := HBoxContainer.new()
	col.add_child(top)
	var exit_btn := UIKit.make_button("Выйти", Palette.RED, Vector2(240, 100), 40)
	exit_btn.pressed.connect(on_back_requested)
	top.add_child(exit_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var pill := PanelContainer.new()
	var pill_style := UIKit.box(Palette.CARD, 50)
	pill_style.content_margin_left = 40
	pill_style.content_margin_right = 40
	pill_style.content_margin_top = 12
	pill_style.content_margin_bottom = 12
	pill.add_theme_stylebox_override("panel", pill_style)
	_progress = UIKit.make_label("0 / 0", 56, Palette.GREEN_DARK)
	_progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill.add_child(_progress)
	top.add_child(pill)

	# Центральная область: подсказка, отход, подпись
	_area = Control.new()
	_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_area)

	_hint = UIKit.make_label(HINT_TEXT, 40, Palette.TEXT_SOFT)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_hint)

	_caption = UIKit.make_label("", 48, Palette.TEXT)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_area.add_child(_caption)

	_item = DraggableItem.new()
	_area.add_child(_item)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UIKit.box(Palette.CARD, 56))
	_item.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_item_image = TextureRect.new()
	_item_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item.add_child(_item_image)
	_item_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 30)
	for c in _item.get_children():
		UIKit.ignore_mouse(c)

	_item.drag_moved.connect(_on_drag_moved)
	_item.drag_released.connect(_on_drag_released)
	_item.drag_cancelled.connect(_on_drag_cancelled)
	_area.resized.connect(_layout_area)

	# Баки: ряд из 3 и ряд из 2
	var bins_box := VBoxContainer.new()
	bins_box.add_theme_constant_override("separation", 24)
	bins_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bins_box)
	var containers := GameData.load_containers()
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 24)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 24)
	bins_box.add_child(row1)
	bins_box.add_child(row2)
	for i in containers.size():
		var b := BinView.new()
		b.setup(containers[i])
		b.custom_minimum_size = Vector2(0, 290)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(row1 if i < 3 else row2).add_child(b)
		_zones.append(b)


func _layout_area() -> void:
	var a := _area.size
	var s := minf(CARD_MAX, minf(a.x * 0.7, a.y - CAPTION_H - HINT_H - 30.0))
	s = maxf(s, 200.0)
	var free_h := maxf(0.0, a.y - HINT_H - s - CAPTION_H)
	var home := Vector2((a.x - s) / 2.0, HINT_H + free_h / 2.0)
	_item.size = Vector2(s, s)
	_item.home_position = home
	if not _item.dragging and not _busy:
		_item.position = home
	_hint.position = Vector2.ZERO
	_hint.size = Vector2(a.x, HINT_H)
	_caption.position = Vector2(0.0, home.y + s + 18.0)
	_caption.size = Vector2(a.x, CAPTION_H)


# ---------------------------------------------------------------- раунд

func _start_round() -> void:
	var all := GameData.load_waste()
	var count := int(Settings.get_value("items_per_round", 10))
	var order := str(Settings.get_value("order", "random"))
	_session = GameSession.new(GameData.pick_round(all, count, order))
	_busy = false
	if _session.is_empty():
		_show_hint("В базе нет отходов для игры", Palette.RED, false)
		_item.visible = false
		return
	_item.visible = true
	_update_progress()
	_layout_area()
	_show_current()


func _show_current() -> void:
	var it := _session.current()
	var path := str(it.get("image", ""))
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		push_warning("Нет изображения для отхода: " + str(it.get("id", "?")))
	_item_image.texture = tex
	_caption.text = str(it.get("display_name", it.get("name", "")))

	_item.reset_state()
	_item.enabled = true
	_item.scale = Vector2(0.6, 0.6)
	_item.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(_item, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_item, "modulate:a", 1.0, 0.2)
	_busy = false


func _update_progress() -> void:
	_progress.text = "%d / %d" % [_session.correct_count, _session.total()]


func _finish() -> void:
	_item.visible = false
	_caption.text = ""
	_show_overlay()


# ---------------------------------------------------------------- перетаскивание

func _on_drag_moved(finger: Vector2, center: Vector2) -> void:
	var zone := _find_zone(finger)
	if zone == null:
		zone = _find_zone(center)
	_set_hover(zone)


func _on_drag_cancelled() -> void:
	_set_hover(null)


func _on_drag_released(finger: Vector2, center: Vector2) -> void:
	_set_hover(null)
	if _busy:
		return
	var zone := _find_zone(finger)
	if zone == null:
		zone = _find_zone(center)
	if zone == null:
		_item.return_home()
		_show_hint("Брось отход в один из баков", Palette.TEXT_SOFT, true)
		return
	_handle_drop(zone)


func _find_zone(global_pos: Vector2) -> BinView:
	var best: BinView = null
	var best_dist := INF
	for z in _zones:
		if z.contains_point(global_pos):
			var d := z.get_global_rect().get_center().distance_to(global_pos)
			if d < best_dist:
				best_dist = d
				best = z
	return best


func _set_hover(zone: BinView) -> void:
	if zone == _hover_zone:
		return
	if _hover_zone != null:
		_hover_zone.set_hover(false)
	_hover_zone = zone
	if _hover_zone != null:
		_hover_zone.set_hover(true)


func _handle_drop(zone: BinView) -> void:
	var item := _session.current()
	if _session.is_correct(item, zone.zone_id):
		_busy = true
		_item.enabled = false
		zone.flash(true)
		_show_hint("Верно!", Palette.GREEN, true)
		var target := zone.get_global_rect().get_center() - _item.size / 2.0
		var t := create_tween().set_parallel(true)
		t.tween_property(_item, "global_position", target, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t.tween_property(_item, "scale", Vector2(0.25, 0.25), 0.28)
		t.tween_property(_item, "modulate:a", 0.0, 0.28)
		await t.finished
		_session.register_correct()
		_update_progress()
		if _session.advance():
			_show_current()
		else:
			_finish()
	else:
		_session.register_mistake()
		zone.flash(false)
		_show_hint("Не тот бак. Попробуй ещё!", Palette.RED, true)
		_item.return_home()


# ---------------------------------------------------------------- подсказка

func _show_hint(text: String, color: Color, temporary: bool) -> void:
	_hint.text = text
	_hint.add_theme_color_override("font_color", color)
	_hint_token += 1
	if temporary:
		get_tree().create_timer(1.6).timeout.connect(_on_hint_timeout.bind(_hint_token))


func _on_hint_timeout(token: int) -> void:
	if token == _hint_token:
		_hint.text = HINT_TEXT
		_hint.add_theme_color_override("font_color", Palette.TEXT_SOFT)


# ---------------------------------------------------------------- итог (простая версия; полный экран на Этапе 3)

func _show_overlay() -> void:
	_overlay = Control.new()
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Palette.DIM
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	var sb := UIKit.box(Palette.CARD, 56)
	sb.set_content_margin_all(56)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	panel.add_child(v)
	v.add_child(UIKit.make_label("Молодец!", 80, Palette.GREEN_DARK))
	v.add_child(UIKit.make_label("Правильно: %d из %d" % [_session.correct_count, _session.total()], 46, Palette.TEXT))
	var err_text := "Без ошибок!" if _session.mistakes == 0 else "Ошибок: %d" % _session.mistakes
	v.add_child(UIKit.make_label(err_text, 40, Palette.TEXT_SOFT))
	var again := UIKit.make_button("Играть ещё", Palette.GREEN, Vector2(0, 120), 46)
	again.pressed.connect(_on_again_pressed)
	v.add_child(again)
	var menu := UIKit.make_button("В меню", Palette.BLUE, Vector2(0, 120), 46)
	menu.pressed.connect(on_back_requested)
	v.add_child(menu)


func _on_again_pressed() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	_start_round()


func on_back_requested() -> void:
	SceneRouter.go_back()
