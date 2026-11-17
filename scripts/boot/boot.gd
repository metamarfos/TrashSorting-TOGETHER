extends Node
## Загрузочная сцена: ждёт кадр (инициализация автозагрузок) и открывает меню.


func _ready() -> void:
	await get_tree().process_frame
	SceneRouter.change_scene(SceneRouter.MENU_SCENE, false)
