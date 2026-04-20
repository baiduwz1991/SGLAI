class_name HomeWorldTabContent
extends TabContentBase

#region 配置与常量
const TAB_ID: StringName = &"world"
@export var module_title: String = "世界"
#endregion

#region 节点引用
@export var title_label_path: NodePath
@export var desc_label_path: NodePath

@onready var title_label: Label = get_node(title_label_path) as Label
@onready var desc_label: Label = get_node(desc_label_path) as Label
#endregion


#region 扩展点
func _get_tab_id() -> StringName:
	return TAB_ID


func _on_tab_context_changed(tab_context: Dictionary) -> void:
	var title: String = _resolve_title(tab_context)
	title_label.text = title
	desc_label.text = "当前页签：%s" % title
#endregion


#region 内部逻辑
func _resolve_title(params: Dictionary) -> String:
	var fallback_title: String = module_title
	if fallback_title == "":
		fallback_title = "世界"
	return str(params.get("title", fallback_title))
#endregion
