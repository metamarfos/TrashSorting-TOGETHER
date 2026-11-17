extends Control
## Главное меню. Карточки режимов строятся из data/modes.json.

const SETTINGS_SCENE := "res://scenes/menu/settings_screen.tscn"

var _popup: ComingSoonPopup = null


func _ready() -> void:
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_add_bubble(Vector2(-160, -140), 520, Palette.GREEN_SOFT)
	_add_bubble(Vector2(760, 120), 300, Palette.YELLOW_SOFT)
	_add_bubble(Vector2(-90, 380), 200, Palette.BLUE_SOFT)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 110)
	margin.add_theme_constant_override("margin_bottom", 56)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	margin.add_child(col)

	col.add_child(UIKit.make_label("Сортируем", 112, Palette.GREEN_DARK))
	col.add_child(UIKit.make_label("вместе", 112, Palette.YELLOW))
	col.add_child(UIKit.make_label("Учимся разделять отходы", 38, Palette.TEXT_SOFT))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	col.add_child(gap)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 28)
	scroll.add_child(list)

	var modes := GameModes.load_modes()
	for i in modes.size():
		list.add_child(_make_mode_card(modes[i], i + 1))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 24)
	col.add_child(footer)

	var settings_btn := UIKit.make_button("Настройка уровня", Palette.BLUE, Vector2(0, 130), 40)
	settings_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_btn.pressed.connect(_on_settings_pressed)
	footer.add_child(settings_btn)

	var db_btn := UIKit.make_button("База отходов", Palette.YELLOW, Vector2(0, 130), 40)
	db_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	db_btn.pressed.connect(_on_database_pressed)
	footer.add_child(db_btn)


func _add_bubble(pos: Vector2, diameter: float, color: Color) -> void:
	var b := UIKit.make_circle(diameter, color)
	b.position = pos
	add_child(b)


func _make_mode_card(mode: Dictionary, number: int) -> Button:
	var enabled: bool = mode.get("enabled", false)
	var mode_color := Color(str(mode.get("color", "#2BA66B")))
	var title: String = str(mode.get("title", ""))
	var subtitle: String = str(mode.get("subtitle", ""))

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 210)
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var border := mode_color if enabled else Palette.DISABLED
	var fill := Palette.CARD if enabled else Color("#F1F5F2")
	var normal := UIKit.box(fill, 44, border, 5, enabled)
	var pressed := UIKit.box(fill.darkened(0.06), 44, border, 5, false)
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", normal)
	card.add_theme_stylebox_override("pressed", pressed)
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left", 32)
	inner.add_theme_constant_override("margin_right", 32)
	inner.add_theme_constant_override("margin_top", 24)
	inner.add_theme_constant_override("margin_bottom", 24)
	card.add_child(inner)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	inner.add_child(row)

	var badge_color := mode_color if enabled else Palette.DISABLED
	var badge := UIKit.make_circle(120, badge_color)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var num := UIKit.make_label(str(number), 64, Color.WHITE)
	num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(num)
	row.add_child(badge)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override("separation", 6)
	var title_color := Palette.TEXT if enabled else Palette.TEXT_SOFT
	texts.add_child(UIKit.make_label(title, 46, title_color, HORIZONTAL_ALIGNMENT_LEFT))
	if subtitle != "":
		texts.add_child(UIKit.make_label(subtitle, 30, Palette.TEXT_SOFT, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(texts)

	var tag_text := "Играть" if enabled else "Скоро"
	var tag_color := mode_color if enabled else Palette.DISABLED
	var tag := PanelContainer.new()
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tag_style := UIKit.box(tag_color, 30, Color(0, 0, 0, 0), 0, false)
	tag_style.content_margin_left = 24
	tag_style.content_margin_right = 24
	tag_style.content_margin_top = 10
	tag_style.content_margin_bottom = 10
	tag.add_theme_stylebox_override("panel", tag_style)
	var tag_label := UIKit.make_label(tag_text, 32, Color.WHITE)
	tag_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tag.add_child(tag_label)
	row.add_child(tag)

	UIKit.ignore_mouse(inner)
	card.pressed.connect(_on_mode_pressed.bind(mode))
	return card


func _on_mode_pressed(mode: Dictionary) -> void:
	var enabled: bool = mode.get("enabled", false)
	var scene: String = str(mode.get("scene", ""))
	if enabled and scene != "":
		SceneRouter.change_scene(scene)
	else:
		_popup = ComingSoonPopup.open(self, str(mode.get("title", "")))


func _on_settings_pressed() -> void:
	SceneRouter.change_scene(SETTINGS_SCENE)


func _on_database_pressed() -> void:
	_popup = ComingSoonPopup.open(self, "База отходов", "Редактор базы отходов появится в одном из следующих обновлений.")


func on_back_requested() -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.close()
		_popup = null
	else:
		get_tree().quit()
