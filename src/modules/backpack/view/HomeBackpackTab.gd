class_name HomeBackpackTab
extends HomeModuleTabBase

var _demo_grid_data: Array[Variant] = []

@onready var _grid_view: ScrollContainer = get_node_or_null("Content/CenterContainer/BackpackArea/VBox/GridArea/GridView")


func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_backpack_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_backpack_open(params)


func _get_default_title() -> String:
	return "背包"


func _on_backpack_create(_params: Dictionary) -> void:
	if _grid_view == null:
		return
	if _grid_view.has_method("init_list_view"):
		_grid_view.call("init_list_view", 0)


func _on_backpack_open(_params: Dictionary) -> void:
	if _grid_view == null:
		return
	_demo_grid_data.clear()
	var idx: int = 1
	while idx <= 100:
		_demo_grid_data.append(idx)
		idx += 1
	if _grid_view.has_method("set_data_list"):
		_grid_view.call("set_data_list", _demo_grid_data, true)
