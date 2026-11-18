class_name ThemeBuilder
extends RefCounted
## Собирает Theme из DesignTokens.
##
## Экраны НЕ задают цвета/шрифты вручную — они ссылаются на «варианты типов»,
## которые объявлены здесь (theme_type_variation в сценах):
##
##   Label:        TitleLabel, HeadingLabel, MutedLabel, BadgeLabel, TagLabel
##   Button:       (по умолчанию — главная), SecondaryButton, DangerButton,
##                 GhostButton, IconButton, MenuItemButton, ChipButton
##   PanelContainer: (по умолчанию — карточка), CardPanel, InsetPanel, RowPanel,
##                 BadgePanel, IconBadge
##   Panel:        ScreenBackground, ModalDim
##   ProgressBar:  TimeBar
##
## Чтобы поменять вид, достаточно поправить токены или (для тонкой настройки) этот файл.

const FONT_REGULAR := "res://assets/fonts/Inter-Regular.otf"
const FONT_BOLD := "res://assets/fonts/Inter-Bold.otf"


static func build(t: DesignTokens) -> Theme:
	var th := Theme.new()
	var reg: Font = t.font_regular
	if reg == null:
		reg = _load_font(FONT_REGULAR)
	var bold: Font = t.font_bold
	if bold == null:
		bold = _load_font(FONT_BOLD)
	if reg != null:
		th.default_font = reg
	th.default_font_size = t.font_size_body
	_build_labels(th, t, reg, bold)
	_build_buttons(th, t, bold)
	_build_panels(th, t)
	_build_inputs(th, t)
	_build_misc(th, t)
	return th


# --------------------------------------------------------------------- публичные помощники

## Плоский стайлбокс. Используется и темой, и компонентами (кнопки баков, теги).
static func flat_box(color: Color, radius: int, border_color: Color = Color(0, 0, 0, 0),
		border_w: int = 0, pad_h: int = 0, pad_v: int = 0,
		shadow_color: Color = Color(0, 0, 0, 0), shadow_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border_color
	sb.shadow_color = shadow_color
	sb.shadow_size = shadow_size
	sb.shadow_offset = Vector2(0, float(shadow_size) * 0.4)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


## Набор стайлбоксов для кнопки: normal / hover / pressed / hover_pressed.
static func button_boxes(t: DesignTokens, fill: Color, outline: Color = Color(0, 0, 0, 0),
		outline_w: int = 0, use_skin: bool = false, radius: int = -1,
		with_shadow: bool = true) -> Dictionary:
	var r: int = t.radius if radius < 0 else radius
	var sh_col: Color = t.shadow if with_shadow else Color(0, 0, 0, 0)
	var sh_size: int = t.shadow_size if with_shadow else 0
	var out := {}
	out["normal"] = flat_box(fill, r, outline, outline_w, 36, 18, sh_col, sh_size)
	out["hover"] = flat_box(fill.lightened(0.05), r, outline, outline_w, 36, 18, sh_col, sh_size)
	out["pressed"] = flat_box(fill.darkened(0.14), r, outline, outline_w, 36, 18)
	out["hover_pressed"] = flat_box(fill.darkened(0.14), r, outline, outline_w, 36, 18)
	if use_skin and t.tex_button != null:
		for key in out:
			var sk := StyleBoxTexture.new()
			sk.texture = t.tex_button
			sk.set_texture_margin_all(t.tex_button_margin)
			sk.content_margin_left = 36
			sk.content_margin_right = 36
			sk.content_margin_top = 18
			sk.content_margin_bottom = 18
			if key == "pressed" or key == "hover_pressed":
				sk.modulate_color = Color(0.85, 0.85, 0.85, 1.0)
			out[key] = sk
	return out


## Окрашивает переключаемую кнопку-«чип» в заданный цвет:
## выключена — белая с цветной рамкой, включена — залита цветом.
static func style_chip(btn: Button, t: DesignTokens, color: Color) -> void:
	var off := flat_box(t.surface, t.radius_small, color, t.border_width, 28, 14)
	var on := flat_box(color, t.radius_small, color.darkened(0.25), t.border_width, 28, 14)
	var on_text: Color = on_color(t, color)
	btn.add_theme_stylebox_override("normal", off)
	btn.add_theme_stylebox_override("hover", off)
	btn.add_theme_stylebox_override("pressed", on)
	btn.add_theme_stylebox_override("hover_pressed", on)
	btn.add_theme_color_override("font_color", t.text)
	btn.add_theme_color_override("font_hover_color", t.text)
	btn.add_theme_color_override("font_pressed_color", on_text)
	btn.add_theme_color_override("font_hover_pressed_color", on_text)
	btn.add_theme_color_override("font_focus_color", t.text)


## Читаемый цвет текста поверх заданного фона.
static func on_color(t: DesignTokens, bg_color: Color) -> Color:
	return t.text if bg_color.get_luminance() > 0.5 else Color.WHITE


# --------------------------------------------------------------------- внутреннее

static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null


static func _label_variation(th: Theme, variation: String, font: Font, size: int, color: Color) -> void:
	th.set_type_variation(variation, "Label")
	if font != null:
		th.set_font("font", variation, font)
	th.set_font_size("font_size", variation, size)
	th.set_color("font_color", variation, color)


static func _build_labels(th: Theme, t: DesignTokens, reg: Font, bold: Font) -> void:
	th.set_color("font_color", "Label", t.text)
	th.set_font_size("font_size", "Label", t.font_size_body)
	_label_variation(th, "TitleLabel", bold, t.font_size_title, t.text)
	_label_variation(th, "HeadingLabel", bold, t.font_size_heading, t.text)
	_label_variation(th, "MutedLabel", reg, t.font_size_small, t.text_muted)
	_label_variation(th, "BadgeLabel", bold, t.font_size_small, t.text_on_accent)
	_label_variation(th, "TagLabel", bold, t.font_size_small - 4, t.text)


static func _apply_button(th: Theme, type_name: String, boxes: Dictionary, font_color: Color,
		disabled_font: Color, pressed_font: Color) -> void:
	for state in boxes:
		th.set_stylebox(state, type_name, boxes[state])
	th.set_stylebox("focus", type_name, StyleBoxEmpty.new())
	th.set_color("font_color", type_name, font_color)
	th.set_color("font_hover_color", type_name, font_color)
	th.set_color("font_focus_color", type_name, font_color)
	th.set_color("font_pressed_color", type_name, pressed_font)
	th.set_color("font_hover_pressed_color", type_name, pressed_font)
	th.set_color("font_disabled_color", type_name, disabled_font)


static func _build_buttons(th: Theme, t: DesignTokens, bold: Font) -> void:
	# База: главная (зелёная) кнопка.
	if bold != null:
		th.set_font("font", "Button", bold)
	th.set_font_size("font_size", "Button", t.font_size_button)
	th.set_constant("h_separation", "Button", 16)
	var disabled_box := flat_box(t.surface_alt.darkened(0.04), t.radius, t.border, t.border_width, 36, 18)
	var primary_boxes := button_boxes(t, t.primary, Color(0, 0, 0, 0), 0, true)
	primary_boxes["disabled"] = disabled_box
	_apply_button(th, "Button", primary_boxes, t.text_on_primary, t.text_muted, t.text_on_primary)

	_variation(th, "SecondaryButton")
	var sec := button_boxes(t, t.surface, t.primary, t.border_width)
	sec["disabled"] = disabled_box
	_apply_button(th, "SecondaryButton", sec, t.primary.darkened(0.25), t.text_muted, t.primary.darkened(0.25))

	_variation(th, "DangerButton")
	var dan := button_boxes(t, t.danger)
	dan["disabled"] = disabled_box
	_apply_button(th, "DangerButton", dan, Color.WHITE, t.text_muted, Color.WHITE)

	_variation(th, "GhostButton")
	var ghost := button_boxes(t, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, false, -1, false)
	ghost["pressed"] = flat_box(t.border, t.radius, Color(0, 0, 0, 0), 0, 36, 18)
	ghost["hover_pressed"] = ghost["pressed"]
	ghost["hover"] = flat_box(Color(1, 1, 1, 0.5), t.radius, Color(0, 0, 0, 0), 0, 36, 18)
	ghost["disabled"] = flat_box(Color(0, 0, 0, 0), t.radius, Color(0, 0, 0, 0), 0, 36, 18)
	_apply_button(th, "GhostButton", ghost, t.primary.darkened(0.25), t.text_muted, t.primary.darkened(0.25))

	# Квадратная кнопка-иконка (стрелка «назад», «+»).
	_variation(th, "IconButton")
	var icon := button_boxes(t, t.surface, t.border, t.border_width, false, t.radius)
	for key in icon:
		var sb: StyleBoxFlat = icon[key]
		sb.content_margin_left = 8
		sb.content_margin_right = 8
	icon["disabled"] = disabled_box
	_apply_button(th, "IconButton", icon, t.text, t.text_muted, t.text)
	th.set_font_size("font_size", "IconButton", t.font_size_heading + 8)

	# Большая карточка-кнопка пункта меню.
	_variation(th, "MenuItemButton")
	var mi := button_boxes(t, t.surface, t.border, t.border_width, false, t.radius)
	for key in mi:
		var sbm: StyleBoxFlat = mi[key]
		sbm.content_margin_left = 0
		sbm.content_margin_right = 0
		sbm.content_margin_top = 0
		sbm.content_margin_bottom = 0
	mi["disabled"] = flat_box(t.surface_alt, t.radius, t.border, t.border_width)
	_apply_button(th, "MenuItemButton", mi, t.text, t.text_muted, t.text)

	# Переключаемая кнопка-«чип» (фильтры, выбор бака/класса). Цвет можно переопределить в коде.
	_variation(th, "ChipButton")
	var chip_off := flat_box(t.surface, t.radius_small, t.border, t.border_width, 28, 14)
	var chip_on := flat_box(t.primary, t.radius_small, t.primary.darkened(0.25), t.border_width, 28, 14)
	var chip := {"normal": chip_off, "hover": chip_off, "pressed": chip_on, "hover_pressed": chip_on, "disabled": disabled_box}
	_apply_button(th, "ChipButton", chip, t.text, t.text_muted, t.text_on_primary)
	th.set_font_size("font_size", "ChipButton", t.font_size_small + 2)


static func _variation(th: Theme, variation: String) -> void:
	th.set_type_variation(variation, "Button")


static func _card_box(t: DesignTokens) -> StyleBox:
	var flat := flat_box(t.surface, t.radius, t.border, t.border_width, 32, 28, t.shadow, t.shadow_size)
	if t.tex_card == null:
		return flat
	var sk := StyleBoxTexture.new()
	sk.texture = t.tex_card
	sk.set_texture_margin_all(t.tex_card_margin)
	sk.content_margin_left = 32
	sk.content_margin_right = 32
	sk.content_margin_top = 28
	sk.content_margin_bottom = 28
	return sk


static func _build_panels(th: Theme, t: DesignTokens) -> void:
	var card := _card_box(t)
	th.set_stylebox("panel", "PanelContainer", card)
	th.set_type_variation("CardPanel", "PanelContainer")
	th.set_stylebox("panel", "CardPanel", card)

	th.set_type_variation("InsetPanel", "PanelContainer")
	th.set_stylebox("panel", "InsetPanel", flat_box(t.surface_alt, t.radius_small, t.border, 2, 20, 16))

	th.set_type_variation("RowPanel", "PanelContainer")
	th.set_stylebox("panel", "RowPanel", flat_box(t.surface, t.radius_small + 4, t.border, 3, 20, 18, t.shadow, 8))

	th.set_type_variation("BadgePanel", "PanelContainer")
	th.set_stylebox("panel", "BadgePanel", flat_box(t.accent, 999, t.accent.darkened(0.15), 3, 26, 8))

	th.set_type_variation("IconBadge", "PanelContainer")
	th.set_stylebox("panel", "IconBadge", flat_box(t.primary, 999, Color(0, 0, 0, 0), 0, 0, 0))

	# Фон экрана.
	th.set_type_variation("ScreenBackground", "Panel")
	if t.tex_background != null:
		var bgt := StyleBoxTexture.new()
		bgt.texture = t.tex_background
		th.set_stylebox("panel", "ScreenBackground", bgt)
	else:
		th.set_stylebox("panel", "ScreenBackground", flat_box(t.bg, 0))

	# Затемнение под модальными окнами.
	th.set_type_variation("ModalDim", "Panel")
	th.set_stylebox("panel", "ModalDim", flat_box(t.overlay, 0))


static func _build_inputs(th: Theme, t: DesignTokens) -> void:
	var normal := flat_box(t.surface, t.radius_small, t.border, t.border_width, 28, 22)
	var focus := flat_box(t.surface, t.radius_small, t.primary, t.border_width, 28, 22)
	var ro := flat_box(t.surface_alt, t.radius_small, t.border, t.border_width, 28, 22)
	for type_name in ["LineEdit", "TextEdit"]:
		th.set_stylebox("normal", type_name, normal)
		th.set_stylebox("focus", type_name, focus)
		th.set_stylebox("read_only", type_name, ro)
		th.set_color("font_color", type_name, t.text)
		th.set_color("font_placeholder_color", type_name, t.text_muted)
		th.set_color("caret_color", type_name, t.primary)
		th.set_color("selection_color", type_name, Color(t.primary.r, t.primary.g, t.primary.b, 0.35))
		th.set_font_size("font_size", type_name, t.font_size_body)


static func _build_misc(th: Theme, t: DesignTokens) -> void:
	# Полоса времени: красная подложка (прошедшее время) + зелёная заливка (оставшееся).
	th.set_type_variation("TimeBar", "ProgressBar")
	th.set_stylebox("background", "TimeBar", flat_box(t.danger.lightened(0.25), 999))
	th.set_stylebox("fill", "TimeBar", flat_box(t.success, 999))

	# Тонкие полосы прокрутки.
	var track := flat_box(Color(0, 0, 0, 0), 999, Color(0, 0, 0, 0), 0, 5, 5)
	var grab := flat_box(Color(t.primary.r, t.primary.g, t.primary.b, 0.45), 999, Color(0, 0, 0, 0), 0, 5, 5)
	var grab_hi := flat_box(Color(t.primary.r, t.primary.g, t.primary.b, 0.7), 999, Color(0, 0, 0, 0), 0, 5, 5)
	for bar in ["VScrollBar", "HScrollBar"]:
		th.set_stylebox("scroll", bar, track)
		th.set_stylebox("scroll_focus", bar, track)
		th.set_stylebox("grabber", bar, grab)
		th.set_stylebox("grabber_highlight", bar, grab_hi)
		th.set_stylebox("grabber_pressed", bar, grab_hi)
