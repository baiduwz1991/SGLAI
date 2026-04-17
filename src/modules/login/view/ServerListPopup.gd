class_name ServerListPopup
extends BaseUI

signal server_selected(server_data: Dictionary)

var _servers: Array[Dictionary] = []

@onready var _item_list: ItemList = get_node_or_null("Panel/Margin/VBox/ServerItemList")
@onready var _confirm_button: Button = get_node_or_null("Panel/Margin/VBox/PopupButtonRow/ConfirmButton")
@onready var _cancel_button: Button = get_node_or_null("Panel/Margin/VBox/PopupButtonRow/CancelButton")
@onready var _hint_label: Label = get_node_or_null("Panel/Margin/VBox/HintLabel")


#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	if _confirm_button != null:
		_confirm_button.pressed.connect(_on_confirm_pressed)
	if _cancel_button != null:
		_cancel_button.pressed.connect(_on_cancel_pressed)
	if _item_list != null:
		_item_list.item_activated.connect(_on_item_activated)


func on_ui_open(params: Dictionary) -> void:
	_servers = _to_dictionary_array(params.get("servers", []))
	var current_server: Dictionary = params.get("current_server", {})
	_refresh_item_list(current_server)
#endregion


#region 交互
func _on_confirm_pressed() -> void:
	if _item_list == null:
		_close_self()
		return
	var selected_indexes: PackedInt32Array = _item_list.get_selected_items()
	if selected_indexes.is_empty():
		_set_hint_text("请先选择一个服务器。")
		return
	_emit_selected(selected_indexes[0])


func _on_cancel_pressed() -> void:
	_close_self()


func _on_item_activated(index: int) -> void:
	_emit_selected(index)
#endregion


#region 内部逻辑
func _refresh_item_list(current_server: Dictionary) -> void:
	if _item_list == null:
		return
	_item_list.clear()
	for server in _servers:
		var server_name: String = str(server.get("server_name", "未命名服务器"))
		var server_id: String = str(server.get("server_id", ""))
		_item_list.add_item("%s (%s)" % [server_name, server_id])

	if _servers.is_empty():
		_set_hint_text("暂无可选服务器。")
		return

	var selected_index: int = _find_server_index_by_id(str(current_server.get("server_id", "")))
	if selected_index < 0:
		selected_index = 0
	_item_list.select(selected_index)
	_set_hint_text("请选择服务器。")


func _find_server_index_by_id(server_id: String) -> int:
	if server_id.is_empty():
		return -1
	var index: int = 0
	while index < _servers.size():
		var server: Dictionary = _servers[index]
		if str(server.get("server_id", "")) == server_id:
			return index
		index += 1
	return -1


func _emit_selected(index: int) -> void:
	if index < 0 or index >= _servers.size():
		return
	var selected_server: Dictionary = _servers[index].duplicate(true)
	server_selected.emit(selected_server)
	_close_self()


func _set_hint_text(text: String) -> void:
	if _hint_label != null:
		_hint_label.text = text


func _close_self() -> void:
	UIManager.close_ui(get_instance_id())


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not (value is Array):
		return result
	for item in value as Array:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result
#endregion
