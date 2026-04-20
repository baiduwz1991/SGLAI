class_name ServerListItem
extends "res://script/ui/super-scroll-view/LoopListViewItem.gd"

#region 信号
signal clicked(index: int)
#endregion

#region 节点引用
@export var button_path: NodePath
@export var name_label_path: NodePath

@onready var button: Button = get_node(button_path) as Button
@onready var name_label: Label = get_node(name_label_path) as Label
#endregion


#region 生命周期
func _ready() -> void:
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)
#endregion


#region 绑定与交互
func bind_server_data(index: int, server: Dictionary, is_selected: bool) -> void:
	item_index = index
	var server_name: String = str(server.get("server_name", "未命名服务器"))
	var server_id: String = str(server.get("server_id", ""))
	name_label.text = "%s (%s)" % [server_name, server_id]

	button.toggle_mode = true
	button.button_pressed = is_selected


func reset_item_state() -> void:
	button.button_pressed = false


func _on_button_pressed() -> void:
	clicked.emit(item_index)
#endregion
