class_name GameMenuItem
extends Button
## Пункт главного меню: иконка, название и (для ещё не готовых игр) плашка «Скоро».

signal chosen(game: Dictionary)

var _game: Dictionary = {}
var _badge_text: String = ""

@onready var _icon_badge: PanelContainer = %IconBadge
@onready var _icon: TextureRect = %Icon
@onready var _texts: VBoxContainer = %Texts
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _badge: PanelContainer = %Badge
@onready var _badge_label: Label = %BadgeText


func setup(game: Dictionary, badge_text: String) -> void:
	_game = game
	_badge_text = badge_text


func _ready() -> void:
	var enabled: bool = bool(_game.get("enabled", false))
	_title.text = str(_game.get("title", ""))
	var sub: String = str(_game.get("subtitle", ""))
	_subtitle.text = sub
	_subtitle.visible = not sub.is_empty()
	_icon.texture = ImageStore.get_texture(str(_game.get("icon", "")))
	var col := Color(str(_game.get("color", "#2E86DE")))
	_icon_badge.add_theme_stylebox_override("panel", ThemeBuilder.flat_box(col, 999))
	_badge_label.text = _badge_text
	_badge.visible = not enabled
	disabled = not enabled          # «нерабочая» кнопка
	if not enabled:
		_icon_badge.modulate = Color(1, 1, 1, 0.55)
		_texts.modulate = Color(1, 1, 1, 0.7)
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	chosen.emit(_game)
