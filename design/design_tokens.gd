class_name DesignTokens
extends Resource
## «Паспорт дизайна» приложения: все цвета, шрифты, размеры и скины в одном месте.
##
## Как менять дизайн:
##   1. Откройте design/tokens.tres в редакторе Godot — все поля ниже появятся в Инспекторе.
##   2. Поменяйте цвет/размер/шрифт/картинку — тема (ThemeBuilder) пересоберётся при запуске.
##   3. Значения по умолчанию заданы здесь; tokens.tres хранит только ваши отличия.
##
## Ничего из этого не «зашито» в экраны: экраны берут оформление из темы по именам
## вариантов (TitleLabel, SecondaryButton, CardPanel ...) — см. design/theme_builder.gd.

@export_group("Цвета")
@export var bg: Color = Color("#EAF6EC")               ## фон экранов
@export var surface: Color = Color("#FFFFFF")          ## карточки, поля ввода
@export var surface_alt: Color = Color("#F1F7F2")      ## вторичные поверхности, выключенные кнопки
@export var border: Color = Color("#CFE3D3")           ## рамки
@export var text: Color = Color("#1F2D26")             ## основной текст
@export var text_muted: Color = Color("#5F7468")       ## подписи, подсказки
@export var text_on_primary: Color = Color("#FFFFFF")  ## текст на главных кнопках
@export var primary: Color = Color("#2E9E5B")          ## главный цвет (кнопки «Начать»)
@export var accent: Color = Color("#FFC93C")           ## акцент (плашка «Скоро», звёзды)
@export var text_on_accent: Color = Color("#3A2A00")   ## текст на акцентном
@export var success: Color = Color("#2FB563")          ## верный ответ
@export var danger: Color = Color("#E5484D")           ## ошибка, удаление
@export var overlay: Color = Color(0.05, 0.12, 0.08, 0.62)  ## затемнение под окнами
@export var shadow: Color = Color(0.10, 0.25, 0.15, 0.16)   ## тени карточек
## Цвета классов опасности I–V (индекс 0 не используется). Первые три — оттенки красного.
@export var class_colors: PackedColorArray = PackedColorArray([
	Color("#9AA5A0"), Color("#E0301E"), Color("#EB6A4C"), Color("#F4A07E"),
	Color("#6FBDE6"), Color("#6DD58A")
])

@export_group("Шрифты")
@export var font_regular: Font      ## пусто = Inter Regular из assets/fonts
@export var font_bold: Font         ## пусто = Inter Bold из assets/fonts
@export var font_size_title: int = 76
@export var font_size_heading: int = 52
@export var font_size_body: int = 38
@export var font_size_small: int = 30
@export var font_size_button: int = 44

@export_group("Формы и отступы")
@export var radius: int = 36
@export var radius_small: int = 22
@export var border_width: int = 4
@export var button_height: int = 140
@export var screen_margin: int = 44
@export var spacing: int = 28
@export var shadow_size: int = 14

@export_group("Графические скины (необязательно)")
## Если задана текстура — она используется вместо плоской заливки (9-patch).
@export var tex_background: Texture2D   ## фон экранов (растягивается на весь экран)
@export var tex_button: Texture2D       ## главные кнопки
@export var tex_button_margin: int = 40
@export var tex_card: Texture2D         ## карточки/панели
@export var tex_card_margin: int = 40

@export_group("Анимация")
@export var transition_time: float = 0.22   ## длительность затемнения при смене экранов
