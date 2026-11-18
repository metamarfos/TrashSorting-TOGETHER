class_name BaseScreen
extends Control
## Базовый класс экрана: обработка «Назад», модальные окна, подтверждения.
##
## В наследнике переопределяйте _on_back() — что делать по кнопке «Назад».

const ConfirmDialogScene := preload("res://ui/components/confirm_dialog.tscn")

var _modal: Control = null


## Вызывается Router-ом при нажатии «Назад». Сначала закрывает открытое окно.
func on_back_requested() -> void:
	if _modal != null and is_instance_valid(_modal):
		if _modal.has_method("dismiss"):
			_modal.call("dismiss")
		return
	_on_back()


func _on_back() -> void:
	Router.go("menu")


func show_modal(modal: Control) -> void:
	_modal = modal
	add_child(modal)
	modal.tree_exited.connect(_on_modal_closed.bind(modal))


func _on_modal_closed(modal: Control) -> void:
	if _modal == modal:
		_modal = null


## Окно подтверждения. on_ok вызывается только при нажатии главной кнопки.
func confirm(title_text: String, message: String, ok_text: String, on_ok: Callable,
		danger: bool = false, cancel_text: String = "Отмена") -> ConfirmDialog:
	var dlg: ConfirmDialog = ConfirmDialogScene.instantiate()
	dlg.setup(title_text, message, ok_text, cancel_text, danger)
	dlg.confirmed.connect(on_ok)
	show_modal(dlg)
	return dlg
