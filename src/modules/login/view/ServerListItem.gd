class_name ServerListItem
extends "res://script/ui/super-scroll-view/LoopListViewItem.gd"

signal clicked(index: int)

@onready var _button: Button = get_node_or_null("Button")
@onready var _name_label: Label = get_node_or_null("Button/NameLabel")


func _ready() -> void:
	if _button != null and not _button.pressed.is_connected(_on_button_pressed):
		_button.pressed.connect(_on_button_pressed)


func bind_server_data(index: int, server: Dictionary, is_selected: bool) -> void:
	item_index = index
	if _name_label == null:
		return
	var server_name: String = str(server.get("server_name", "未命名服务器"))
	var server_id: String = str(server.get("server_id", ""))
	_name_label.text = "%s (%s)" % [server_name, server_id]

	if _button != null:
		_button.toggle_mode = true
		_button.button_pressed = is_selected


func reset_item_state() -> void:
	if _button != null:
		_button.button_pressed = false


func _on_button_pressed() -> void:
	clicked.emit(item_index)
