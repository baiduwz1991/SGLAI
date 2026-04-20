class_name HomeBackpackTabContent
extends TabContentBase

#region 配置与常量
const TAB_ID: StringName = &"backpack"
@export var module_title: String = "背包"
#endregion

#region 状态
var _demo_grid_data: Array[Variant] = []
#endregion

#region 节点引用
@export var title_label_path: NodePath
@export var desc_label_path: NodePath
@export var grid_view_path: NodePath

@onready var title_label: Label = get_node(title_label_path) as Label
@onready var desc_label: Label = get_node(desc_label_path) as Label
@onready var grid_view: ScrollContainer = get_node(grid_view_path) as ScrollContainer
#endregion


#region 扩展点
func _get_tab_id() -> StringName:
	return TAB_ID


func _on_tab_content_create(_params: Dictionary) -> void:
	if grid_view.has_signal("top_line_triggered"):
		if not grid_view.is_connected("top_line_triggered", Callable(self, "_on_grid_top_line_triggered")):
			grid_view.connect("top_line_triggered", Callable(self, "_on_grid_top_line_triggered"))
	if grid_view.has_signal("down_line_triggered"):
		if not grid_view.is_connected("down_line_triggered", Callable(self, "_on_grid_down_line_triggered")):
			grid_view.connect("down_line_triggered", Callable(self, "_on_grid_down_line_triggered"))
	if grid_view.has_method("init_list_view"):
		grid_view.call("init_list_view", 0)


func _on_tab_content_open(_params: Dictionary) -> void:
	_demo_grid_data.clear()
	var idx: int = 1
	while idx <= 100:
		_demo_grid_data.append(idx)
		idx += 1
	if grid_view.has_method("set_data_list"):
		grid_view.call("set_data_list", _demo_grid_data, true)


func _on_tab_context_changed(tab_context: Dictionary) -> void:
	var title: String = _resolve_title(tab_context)
	title_label.text = title
	desc_label.text = "当前页签：%s" % title
#endregion


#region 交互与显示
func _on_grid_top_line_triggered() -> void:
	print("[BackpackGrid] 触发顶部边界事件，可在这里执行下拉刷新。")


func _on_grid_down_line_triggered() -> void:
	print("[BackpackGrid] 触发底部边界事件，可在这里执行上拉加载更多。")
#endregion


#region 内部逻辑
func _resolve_title(params: Dictionary) -> String:
	var fallback_title: String = module_title
	if fallback_title == "":
		fallback_title = "背包"
	return str(params.get("title", fallback_title))
#endregion
