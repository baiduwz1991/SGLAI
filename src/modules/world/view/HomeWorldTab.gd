class_name HomeWorldTab
extends HomeModuleTabBase

#region 生命周期
func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_world_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_world_open(params)
#endregion


#region 扩展点
func _get_default_title() -> String:
	return "世界"


func _on_world_create(_params: Dictionary) -> void:
	pass


func _on_world_open(_params: Dictionary) -> void:
	pass
#endregion
