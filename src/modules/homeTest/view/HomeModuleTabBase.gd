class_name HomeModuleTabBase
extends BaseUI

#region 配置与节点引用
@export var module_title: String = ""
@export var title_label_path: NodePath
@export var desc_label_path: NodePath

@onready var title_label: Label = get_node(title_label_path) as Label
@onready var desc_label: Label = get_node(desc_label_path) as Label
#endregion


#region 生命周期
func on_ui_create(params: Dictionary) -> void:
	var initial_title: String = _resolve_title(params)
	_refresh_text(initial_title)
	_on_module_create(params)


func on_ui_open(params: Dictionary) -> void:
	var current_title: String = _resolve_title(params)
	_refresh_text(current_title)
	_on_module_open(params)
#endregion


#region 扩展点
func _on_module_create(_params: Dictionary) -> void:
	pass


func _on_module_open(_params: Dictionary) -> void:
	pass
#endregion


#region 内部逻辑
func _resolve_title(params: Dictionary) -> String:
	var fallback_title: String = module_title
	if fallback_title == "":
		fallback_title = _get_default_title()
	return str(params.get("title", fallback_title))


func _get_default_title() -> String:
	return ""


func _refresh_text(title: String) -> void:
	title_label.text = title
	desc_label.text = "当前页签：%s" % title
#endregion
