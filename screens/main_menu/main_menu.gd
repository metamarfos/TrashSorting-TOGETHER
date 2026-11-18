extends BaseScreen
## Главное меню: список игр из data/games.json + вход в редактор таблицы отходов.

const GameMenuItemScene := preload("res://screens/main_menu/game_menu_item.tscn")

@onready var _items: VBoxContainer = %Items
@onready var _editor_button: Button = %EditorButton
@onready var _sound_button: Button = %SoundButton


func _ready() -> void:
	for g in GameRegistry.games:
		var item: GameMenuItem = GameMenuItemScene.instantiate()
		item.setup(g, GameRegistry.badge_text)
		item.chosen.connect(_on_game_chosen)
		_items.add_child(item)
	_editor_button.pressed.connect(_on_editor_pressed)
	_sound_button.pressed.connect(_on_sound_pressed)
	_update_sound_button()


func _on_game_chosen(game: Dictionary) -> void:
	var screen: String = str(game.get("screen", ""))
	if not screen.is_empty():
		Router.go(screen)


func _on_editor_pressed() -> void:
	Router.go("waste_editor")


func _on_sound_pressed() -> void:
	Store.sound_enabled = not Store.sound_enabled
	_update_sound_button()


func _update_sound_button() -> void:
	_sound_button.text = "Звук: вкл" if Store.sound_enabled else "Звук: выкл"


func _on_back() -> void:
	confirm("Выйти из игры?", "", "Выйти", get_tree().quit, false, "Остаться")
