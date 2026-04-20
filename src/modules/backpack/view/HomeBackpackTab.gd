class_name HomeBackpackTab
extends HomeModuleTabBase

#region 状态
var _demo_grid_data: Array[Variant] = []
#endregion

#region 节点引用
@export var grid_view_path: NodePath

@onready var grid_view: ScrollContainer = get_node(grid_view_path) as ScrollContainer
#endregion


#region 生命周期
func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_backpack_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_backpack_open(params)
#endregion


#region 扩展点
func _get_default_title() -> String:
	return "背包"
#endregion


#region 交互与显示
func _on_backpack_create(_params: Dictionary) -> void:
	if grid_view.has_signal("top_line_triggered"):
		if not grid_view.is_connected("top_line_triggered", Callable(self, "_on_grid_top_line_triggered")):
			grid_view.connect("top_line_triggered", Callable(self, "_on_grid_top_line_triggered"))
	if grid_view.has_signal("down_line_triggered"):
		if not grid_view.is_connected("down_line_triggered", Callable(self, "_on_grid_down_line_triggered")):
			grid_view.connect("down_line_triggered", Callable(self, "_on_grid_down_line_triggered"))
	if grid_view.has_method("init_list_view"):
		grid_view.call("init_list_view", 0)


func _on_backpack_open(_params: Dictionary) -> void:
	_demo_grid_data.clear()
	var idx: int = 1
	while idx <= 100:
		_demo_grid_data.append(idx)
		idx += 1
	if grid_view.has_method("set_data_list"):
		grid_view.call("set_data_list", _demo_grid_data, true)


func _on_grid_top_line_triggered() -> void:
	print("[BackpackGrid] 触发顶部边界事件，可在这里执行下拉刷新。")


func _on_grid_down_line_triggered() -> void:
	print("[BackpackGrid] 触发底部边界事件，可在这里执行上拉加载更多。")
#endregion
