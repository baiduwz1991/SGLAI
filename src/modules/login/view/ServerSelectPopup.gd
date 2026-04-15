class_name ServerSelectPopup
extends Control

signal server_selected(server_id: StringName, server_name: String, gateway_url: String)
signal cancelled

@onready var server_list_widget: ItemList = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ServerList
@onready var confirm_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/ConfirmButton
@onready var cancel_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/CancelButton

var _servers: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func open_popup(servers: Array[Dictionary], selected_server_id: StringName) -> void:
	_servers = servers.duplicate(true)
	_rebuild_server_list(selected_server_id)
	visible = true


func close_popup() -> void:
	visible = false


func _rebuild_server_list(selected_server_id: StringName) -> void:
	server_list_widget.clear()
	for index in range(_servers.size()):
		var server_entry: Dictionary = _servers[index]
		var server_name: String = str(server_entry.get("name", "未知服务器"))
		var gateway_url: String = str(server_entry.get("gateway_url", ""))
		server_list_widget.add_item("%s (%s)" % [server_name, gateway_url])

		var server_id: StringName = StringName(str(server_entry.get("id", "")))
		if selected_server_id != StringName() and server_id == selected_server_id:
			server_list_widget.select(index)

	if server_list_widget.item_count > 0 and server_list_widget.get_selected_items().is_empty():
		server_list_widget.select(0)


func _on_confirm_pressed() -> void:
	var selected_items: PackedInt32Array = server_list_widget.get_selected_items()
	if selected_items.is_empty():
		return

	var selected_index: int = selected_items[0]
	if selected_index < 0 or selected_index >= _servers.size():
		return

	var selected_server: Dictionary = _servers[selected_index]
	var server_id: StringName = StringName(str(selected_server.get("id", "")))
	var server_name: String = str(selected_server.get("name", "未知服务器"))
	var gateway_url: String = str(selected_server.get("gateway_url", ""))
	server_selected.emit(server_id, server_name, gateway_url)
	close_popup()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	close_popup()
