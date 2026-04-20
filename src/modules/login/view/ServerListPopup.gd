class_name ServerListPopup
extends BaseUI

signal server_selected(server_data: Dictionary)

var _servers: Array[Dictionary] = []
var _selected_index: int = -1
var _item_payloads: Array[Dictionary] = []

@export var server_list_view_path: NodePath
@export var confirm_button_path: NodePath
@export var cancel_button_path: NodePath
@export var hint_label_path: NodePath

@onready var server_list_view: ScrollContainer = get_node(server_list_view_path) as ScrollContainer
@onready var confirm_button: Button = get_node(confirm_button_path) as Button
@onready var cancel_button: Button = get_node(cancel_button_path) as Button
@onready var hint_label: Label = get_node(hint_label_path) as Label


#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	if server_list_view.has_signal("item_bound"):
		if not server_list_view.is_connected("item_bound", Callable(self, "_on_item_bound")):
			server_list_view.connect("item_bound", Callable(self, "_on_item_bound"))
	if server_list_view.has_signal("item_recycled"):
		if not server_list_view.is_connected("item_recycled", Callable(self, "_on_item_recycled")):
			server_list_view.connect("item_recycled", Callable(self, "_on_item_recycled"))
	if server_list_view.has_method("init_list_view"):
		server_list_view.call("init_list_view", 0)


func on_ui_open(params: Dictionary) -> void:
	_servers = _to_dictionary_array(params.get("servers", []))
	var current_server: Dictionary = params.get("current_server", {})
	_refresh_item_list(current_server)
#endregion


#region 交互
func _on_confirm_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _servers.size():
		_set_hint_text("请先选择一个服务器。")
		return
	_emit_selected(_selected_index)


func _on_cancel_pressed() -> void:
	_close_self()


func _refresh_item_list(current_server: Dictionary) -> void:
	if _servers.is_empty():
		_selected_index = -1
		_item_payloads.clear()
		if server_list_view.has_method("set_count_and_refresh"):
			server_list_view.call("set_count_and_refresh", 0, true)
		_set_hint_text("暂无可选服务器。")
		return

	_selected_index = _find_server_index_by_id(str(current_server.get("server_id", "")))
	if _selected_index < 0:
		_selected_index = 0
	_item_payloads = _build_item_payloads()
	if server_list_view.has_method("set_count_and_refresh"):
		server_list_view.call("set_count_and_refresh", _item_payloads.size(), true)
	if server_list_view.has_method("refresh_all_shown_item"):
		server_list_view.call("refresh_all_shown_item")
	_set_hint_text("请选择服务器。")


func _on_item_bound(index: int, item: Node) -> void:
	if item == null:
		return
	if index < 0 or index >= _item_payloads.size():
		return
	if item.has_method("bind_server_data"):
		var payload: Dictionary = _item_payloads[index]
		item.call("bind_server_data", index, payload.get("server", {}), bool(payload.get("selected", false)))
	if item.has_signal("clicked"):
		if not item.is_connected("clicked", Callable(self, "_on_server_item_clicked")):
			item.connect("clicked", Callable(self, "_on_server_item_clicked"))


func _on_item_recycled(item: Node) -> void:
	if item == null:
		return
	if item.has_method("reset_item_state"):
		item.call("reset_item_state")


func _on_server_item_clicked(index: int) -> void:
	if index < 0 or index >= _servers.size():
		return
	_selected_index = index
	_item_payloads = _build_item_payloads()
	if server_list_view.has_method("refresh_all_shown_item"):
		server_list_view.call("refresh_all_shown_item")


func _build_item_payloads() -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	var index: int = 0
	while index < _servers.size():
		payloads.append({
			"server": _servers[index],
			"selected": index == _selected_index
		})
		index += 1
	return payloads


#endregion


#region 内部逻辑
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
	hint_label.text = text


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
