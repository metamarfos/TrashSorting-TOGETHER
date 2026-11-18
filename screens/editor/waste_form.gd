extends BaseScreen
## Форма записи отхода: создание, редактирование, удаление. id приходит в Router.params["id"] ("" — новая).

@onready var _header: ScreenHeader = %Header
@onready var _preview: TextureRect = %Preview
@onready var _no_image: Label = %NoImage
@onready var _pick: Button = %PickButton
@onready var _clear_image: Button = %ClearImageButton
@onready var _name_edit: TextEdit = %NameEdit
@onready var _class_chips: HBoxContainer = %ClassChips
@onready var _class_hint: Label = %ClassHint
@onready var _bin_chips: HFlowContainer = %BinChips
@onready var _note_edit: TextEdit = %NoteEdit
@onready var _problems: Label = %Problems
@onready var _save: Button = %SaveButton
@onready var _delete: Button = %DeleteButton
@onready var _spacer: Control = %KeyboardSpacer

var _item: WasteItem
var _is_new: bool = false
var _imported: Array[String] = []     # картинки, скопированные в этой сессии (чистим, если не сохранили)
var _snapshot: String = ""
var _dialog: FileDialog
var _class_buttons: Dictionary = {}


func _ready() -> void:
	var id: String = str(Router.params.get("id", ""))
	var existing: WasteItem = WasteDB.get_item(id) if not id.is_empty() else null
	_is_new = existing == null
	_item = WasteItem.new() if _is_new else existing.copy()
	_header.title = "Новая запись" if _is_new else "Редактирование"
	_header.back_pressed.connect(on_back_requested)
	_delete.visible = not _is_new
	_name_edit.text = _item.name
	_note_edit.text = _item.note
	_build_class_chips()
	_build_bin_chips()
	_update_preview()
	_update_class_hint()
	_name_edit.text_changed.connect(_refresh_problems)
	_pick.pressed.connect(_on_pick_pressed)
	_clear_image.pressed.connect(_on_clear_image)
	_save.pressed.connect(_on_save_pressed)
	_delete.pressed.connect(_on_delete_pressed)
	_refresh_problems()
	_snapshot = _signature()


func _process(_delta: float) -> void:
	# Поднимаем содержимое над экранной клавиатурой Android.
	var kb: int = DisplayServer.virtual_keyboard_get_height()
	var win_h: float = maxf(1.0, float(DisplayServer.window_get_size().y))
	var h: float = float(kb) * get_viewport().get_visible_rect().size.y / win_h
	if absf(_spacer.custom_minimum_size.y - h) > 1.0:
		_spacer.custom_minimum_size.y = h


func _make_chip(text: String, color: Color, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.theme_type_variation = &"ChipButton"
	b.custom_minimum_size = Vector2(0, 110)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	if group != null:
		b.button_group = group
	ThemeBuilder.style_chip(b, Design.tokens, color)
	return b


func _build_class_chips() -> void:
	var group := ButtonGroup.new()
	for c in range(1, 6):
		var b := _make_chip(Hazard.roman(c), Design.hazard_color(c), group)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_pressed_no_signal(_item.hazard_class == c)
		b.pressed.connect(_on_class_chosen.bind(c))
		_class_chips.add_child(b)


func _build_bin_chips() -> void:
	for bin in BinDB.bins:
		var id: String = str(bin.get("id", ""))
		var b := _make_chip(BinDB.short_name(id), BinDB.color(id), null)
		b.set_pressed_no_signal(_item.bins.has(id))
		b.toggled.connect(_on_bin_toggled.bind(id))
		_bin_chips.add_child(b)


func _on_class_chosen(c: int) -> void:
	_item.hazard_class = c
	_update_class_hint()


func _update_class_hint() -> void:
	_class_hint.text = Hazard.full(_item.hazard_class)


func _on_bin_toggled(on: bool, id: String) -> void:
	if on and not _item.bins.has(id):
		_item.bins.append(id)
	elif not on:
		_item.bins.erase(id)
	_refresh_problems()


func _update_preview() -> void:
	var tex: Texture2D = ImageStore.get_texture(_item.image)
	_preview.texture = tex
	_no_image.visible = tex == null
	_clear_image.visible = tex != null
	_refresh_problems()


func _collect() -> void:
	_item.name = _name_edit.text.strip_edges()
	_item.note = _note_edit.text.strip_edges()


func _signature() -> String:
	_collect()
	var b: Array = _item.bins.duplicate()
	b.sort()
	return JSON.stringify([_item.name, _item.hazard_class, b, _item.image, _item.note])


func _refresh_problems() -> void:
	if _item == null:
		return
	_collect()
	var p: Array[String] = _item.problems()
	_problems.visible = not p.is_empty()
	_problems.text = "В игру не попадёт, пока: " + ", ".join(PackedStringArray(p))


# ---------------------------------------------------------------- картинка

func _on_pick_pressed() -> void:
	if _dialog == null:
		_dialog = FileDialog.new()
		_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_dialog.use_native_dialog = true      # системное окно выбора (на Android — выбор из галереи/файлов)
		_dialog.title = "Выберите картинку"
		if OS.get_name() != "Android":
			_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Изображения"])
		_dialog.file_selected.connect(_on_file_selected)
		add_child(_dialog)
	_dialog.popup_centered_ratio(0.9)


func _on_file_selected(path: String) -> void:
	var imported: String = ImageStore.import_user_image(path)
	if imported.is_empty():
		_problems.visible = true
		_problems.text = "Не удалось открыть эту картинку. Попробуйте PNG или JPG."
		return
	_imported.append(imported)
	_item.image = imported
	_update_preview()


func _on_clear_image() -> void:
	_item.image = ""
	_update_preview()


# ---------------------------------------------------------------- сохранение / удаление / выход

func _on_save_pressed() -> void:
	_collect()
	if _item.name.is_empty():
		_problems.visible = true
		_problems.text = "Введите название отхода."
		_name_edit.grab_focus()
		return
	WasteDB.upsert(_item)
	_leave()


func _on_delete_pressed() -> void:
	confirm("Удалить запись?", _item.name, "Удалить", _do_delete, true)


func _do_delete() -> void:
	WasteDB.delete_item(_item.id)
	_leave()


func _on_back() -> void:
	if _signature() != _snapshot:
		confirm("Выйти без сохранения?", "Изменения будут потеряны.", "Выйти", _leave, true, "Остаться")
	else:
		_leave()


func _leave() -> void:
	for p in _imported:
		WasteDB.gc_image(p)    # удалит только те файлы, на которые не ссылается ни одна запись
	Router.go("waste_editor")
