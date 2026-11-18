extends Node
## Автозагрузка «Design»: загружает токены дизайна, собирает тему и применяет её ко всему приложению.

const TOKENS_PATH := "res://design/tokens.tres"

var tokens: DesignTokens
var theme: Theme


func _ready() -> void:
	reload()


## Пересобирает тему (можно вызывать после правки токенов во время отладки).
func reload() -> void:
	tokens = null
	if ResourceLoader.exists(TOKENS_PATH):
		tokens = load(TOKENS_PATH) as DesignTokens
	if tokens == null:
		tokens = DesignTokens.new()
	theme = ThemeBuilder.build(tokens)
	get_tree().root.theme = theme
	RenderingServer.set_default_clear_color(tokens.bg)


func hazard_color(cls: int) -> Color:
	var arr: PackedColorArray = tokens.class_colors
	if arr.is_empty():
		return tokens.border
	return arr[clampi(cls, 0, arr.size() - 1)]


## Цвет текста, читаемый поверх заданного фона.
func on_color(bg_color: Color) -> Color:
	return ThemeBuilder.on_color(tokens, bg_color)
