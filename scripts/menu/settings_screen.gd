extends Control
## Экран «Настройка уровня». Значения хранит автозагрузка Settings.

# Описание строк: key (ключ настройки), title, values (допустимые значения),
# kind (формат вывода), depends (ключ-переключатель, от которого зависит строка).
const ROWS: Array = [
	{"key": "items_per_round", "title": "Отходов за раунд", "values": [3, 5, 10, 15, 20, 30, 50, 0], "kind": "count"},
	{"key": "time_enabled", "title": "Ограничение времени", "values": [false, true], "kind": "onoff"},
	{"key": "seconds_per_item", "title": "Секунд на отход", "values": [3, 5, 8, 10, 15, 20, 30, 45, 60], "kind": "seconds", "depends": "time_enabled"},
	{"key": "order", "title": "Порядок отходов", "values": ["random", "sequential"], "kind": "order"},
	{"key": "max_attempts", "title": "Попыток при ошибке", "values": [0, 1, 2, 3, 5], "kind": "attempts"},
	{"key": "sound_enabled", "title": "Звуки", "values": [false, true], "kind": "onoff"},
]

var _value_labels: Dictionary = {}
var _row_panels: Dictionary = {}


func _ready() -> void:
	_build()
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 26)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	col.add_child(top)
	var back := UIKit.make_button("Назад", Palette.GREEN, Vector2(240, 110), 40)
	back.pressed.connect(on_back_requested)
	top.add_child(back)
	var title := UIKit.make_label("Настройка уровня", 54, Palette.GREEN_DARK, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	col.add_child(UIKit.make_label("Быстрый выбор", 34, Palette.TEXT_SOFT, HORIZONTAL_ALIGNMENT_LEFT))
	var presets_row := HBoxContainer.new()
	presets_row.add_theme_constant_override("separation", 20)
	col.add_child(presets_row)
	var preset_colors := [Palette.GREEN, Palette.YELLOW, Palette.RED]
	var ci := 0
	for preset_id in Settings.presets.keys():
		var p: Dictionary = Settings.presets[preset_id]
		var b := UIKit.make_button(str(p.get("label", preset_id)), preset_colors[ci % preset_colors.size()], Vector2(0, 110), 38)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_preset_pressed.bind(str(preset_id)))
		presets_row.add_child(b)
		ci += 1

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 20)
	scroll.add_child(list)

	for i in ROWS.size():
		list.add_child(_make_row(i))

	var reset := UIKit.make_button("Сбросить настройки", Palette.TEXT_SOFT, Vector2(0, 110), 38)
	reset.pressed.connect(_on_reset_pressed)
	col.add_child(reset)


func _make_row(index: int) -> PanelContainer:
	var row: Dictionary = ROWS[index]
	var panel := PanelContainer.new()
	var sb := UIKit.box(Palette.CARD, 40)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UIKit.make_label(str(row["title"]), 36, Palette.TEXT_SOFT, HORIZONTAL_ALIGNMENT_LEFT))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)

	var minus := UIKit.make_button("-", Palette.BLUE, Vector2(130, 120), 60)
	minus.pressed.connect(_on_step.bind(index, -1))
	h.add_child(minus)

	var value_label := UIKit.make_label("", 50, Palette.TEXT)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(value_label)

	var plus := UIKit.make_button("+", Palette.BLUE, Vector2(130, 120), 60)
	plus.pressed.connect(_on_step.bind(index, 1))
	h.add_child(plus)

	_value_labels[index] = value_label
	_row_panels[index] = panel
	return panel


func _on_step(index: int, direction: int) -> void:
	var row: Dictionary = ROWS[index]
	var values: Array = row["values"]
	var current: Variant = Settings.get_value(str(row["key"]))
	var idx := values.find(current)
	if idx < 0:
		idx = 0
	idx = clampi(idx + direction, 0, values.size() - 1)
	Settings.set_value(str(row["key"]), values[idx])
	_refresh()


func _on_preset_pressed(preset_id: String) -> void:
	Settings.apply_preset(preset_id)
	_refresh()


func _on_reset_pressed() -> void:
	Settings.reset_to_defaults()
	_refresh()


func _refresh() -> void:
	for i in ROWS.size():
		var row: Dictionary = ROWS[i]
		var v: Variant = Settings.get_value(str(row["key"]))
		(_value_labels[i] as Label).text = _format(str(row["kind"]), v)
		var active := true
		if row.has("depends"):
			active = bool(Settings.get_value(str(row["depends"]), true))
		(_row_panels[i] as Control).modulate.a = 1.0 if active else 0.45


func _format(kind: String, v: Variant) -> String:
	match kind:
		"count":
			return "Все" if int(v) == 0 else str(int(v))
		"seconds":
			return str(int(v)) + " с"
		"onoff":
			return "Вкл" if bool(v) else "Выкл"
		"order":
			return "Случайно" if str(v) == "random" else "По порядку"
		"attempts":
			return "Без лимита" if int(v) == 0 else str(int(v))
	return str(v)


func on_back_requested() -> void:
	SceneRouter.go_back()
