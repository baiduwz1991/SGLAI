class_name HomeGeneralTab
extends HomeModuleTabBase

#region 生命周期
func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_general_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_general_open(params)
#endregion


#region 扩展点
func _get_default_title() -> String:
	return "武将"


func _on_general_create(_params: Dictionary) -> void:
	pass


func _on_general_open(_params: Dictionary) -> void:
	pass
#endregion
