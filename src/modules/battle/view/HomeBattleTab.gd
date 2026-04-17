class_name HomeBattleTab
extends HomeModuleTabBase


func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_battle_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_battle_open(params)


func _get_default_title() -> String:
	return "战斗"


func _on_battle_create(_params: Dictionary) -> void:
	pass


func _on_battle_open(_params: Dictionary) -> void:
	pass
