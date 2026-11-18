extends BaseScreen
## Редактор таблицы отходов: список с поиском и фильтрами, добавление, правка, удаление.

const WasteRowScene := preload("res://screens/editor/waste_row.tscn")
const PAGE_SIZE := 20

# Состояние списка переживает переход в форму и обратно.
static var _query: String = ""
static var _class_filter: int = 0
static var _bin_filter: String = ""
static var _shown: int = PAGE_SIZE
static var _scroll_pos: int = 0

@onready var _header: ScreenHeader = %Header
@onready var _search: LineEdit = %Search
@onready var _class_chips: HBoxContainer = %ClassChips
@onready var _bin_chips: HFlowContainer = %BinChips
@onready var _counter: Label = %Counter
@onready var _scroll: ScrollContainer = %Scroll
@onready var _rows: VBoxContainer = %Rows
@onready var _more: Button = %MoreButton
@onready var _reset: Button = %ResetButton

var _debounce: Timer


func _ready() -> void:
	_header.back_pressed.connect(on_back_requested)
	var add := Button.new()
	add.text = "+"
	add.theme_type_variation = &"IconButton"
	add.custom_minimum_size = Vector2(120, 120)
	add.pressed.connect(_on_add_pressed)
	_header.right_slot.add_child(add)

	_debounce = Timer.new()
	_debounce.one_shot = true
	_debounce.wait_time = 0.35
	add_child(_debounce)
	_debounce.timeout.connect(_apply_search)

	_search.text = _query
	_search.text_changed.connect(_on_search_changed)
	_build_class_chips()
	_build_bin_chips()
	_more.pressed.connect(_on_more_pressed)
	_reset.pressed.connect(_on_reset_pressed)
	_rebuild()
	_scroll.set_deferred("scroll_vertical", _scroll_pos)


func _make_chip(text: String, group: ButtonGroup, pressed: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.theme_type_variation = &"ChipButton"
	b.custom_minimum_size = Vector2(0, 90)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.set_pressed_no_signal(pressed)
	return b


func _build_class_chips() -> void:
	var group := ButtonGroup.new()
	var all := _make_chip("Все", group, _class_filter == 0)
	all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all.pressed.connect(_set_class_filter.bind(0))
	_class_chips.add_child(all)
	for c in range(1, 6):
		var b := _make_chip(Hazard.roman(c), group, _class_filter == c)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.style_chip(b, Design.tokens, Design.hazard_color(c))
		b.pressed.connect(_set_class_filter.bind(c))
		_class_chips.add_child(b)


func _build_bin_chips() -> void:
	var group := ButtonGroup.new()
	var all := _make_chip("Все баки", group, _bin_filter.is_empty())
	all.pressed.connect(_set_bin_filter.bind(""))
	_bin_chips.add_child(all)
	for b in BinDB.bins:
		var id: String = str(b.get("id", ""))
		var chip := _make_chip(BinDB.short_name(id), group, _bin_filter == id)
		ThemeBuilder.style_chip(chip, Design.tokens, BinDB.color(id))
		chip.pressed.connect(_set_bin_filter.bind(id))
		_bin_chips.add_child(chip)


func _set_class_filter(c: int) -> void:
	_class_filter = c
	_shown = PAGE_SIZE
	_rebuild()


func _set_bin_filter(id: String) -> void:
	_bin_filter = id
	_shown = PAGE_SIZE
	_rebuild()


func _on_search_changed(_text: String) -> void:
	_debounce.start()


func _apply_search() -> void:
	_query = _search.text
	_shown = PAGE_SIZE
	_rebuild()


func _rebuild() -> void:
	for r in _rows.get_children():
		r.queue_free()
	var found: Array[WasteItem] = WasteDB.filter(_query, _class_filter, _bin_filter)
	var count: int = mini(_shown, found.size())
	for i in count:
		var row: WasteRow = WasteRowScene.instantiate()
		row.setup(found[i])
		row.tapped.connect(_on_row_tapped.bind(found[i].id))
		_rows.add_child(row)
	var playable: int = WasteDB.get_playable().size()
	_counter.text = "Показано %d из %d · всего записей %d · в игре %d" % [count, found.size(), WasteDB.items.size(), playable]
	_more.visible = count < found.size()
	_more.text = "Показать ещё (%d)" % (found.size() - count)


func _on_more_pressed() -> void:
	_shown += PAGE_SIZE
	_rebuild()


func _on_row_tapped(id: String) -> void:
	_scroll_pos = _scroll.scroll_vertical
	Router.go("waste_form", {"id": id})


func _on_add_pressed() -> void:
	_scroll_pos = 0
	Router.go("waste_form", {"id": ""})


func _on_reset_pressed() -> void:
	confirm("Вернуть исходную таблицу?",
		"Все ваши изменения, добавленные записи и картинки будут удалены.",
		"Вернуть", _do_reset, true)


func _do_reset() -> void:
	WasteDB.reset_to_defaults()
	_shown = PAGE_SIZE
	_rebuild()


func _on_back() -> void:
	_query = ""
	_class_filter = 0
	_bin_filter = ""
	_shown = PAGE_SIZE
	_scroll_pos = 0
	Router.go("menu")
