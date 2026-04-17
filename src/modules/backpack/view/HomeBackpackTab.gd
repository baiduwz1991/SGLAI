class_name HomeBackpackTab
extends HomeModuleTabBase


func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_backpack_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_backpack_open(params)


func _get_default_title() -> String:
	return "背包"


func _on_backpack_create(_params: Dictionary) -> void:
	pass


func _on_backpack_open(_params: Dictionary) -> void:
	pass
