extends Control

signal back_requested
signal login_completed(token: String)

const SERVER_LIST: Array[Dictionary] = [
	{"id": "s1", "name": "1服-青龙", "gateway_url": "mock://gateway/s1"},
	{"id": "s2", "name": "2服-白虎机", "gateway_url": "mock://gateway/s2"},
	{"id": "s3", "name": "3服-玄武", "gateway_url": "mock://gateway/s3"}
]

@onready var account_edit: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/AccountEdit
@onready var password_edit: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PasswordEdit
@onready var selected_server_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SelectedServerLabel
@onready var select_server_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SelectServerButton
@onready var connect_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/ConnectButton
@onready var login_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/LoginButton
@onready var disconnect_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/DisconnectButton
@onready var back_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton
@onready var status_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var server_select_popup: ServerSelectPopup = $ServerSelectPopup

var _controller: LoginController
var _selected_server_id: StringName = StringName()
var _selected_server_name: String = ""
var _selected_gateway_url: String = "mock://gateway/s1"


func _ready() -> void:
	_controller = _resolve_controller()
	_connect_controller_signals()
	_connect_view_signals()
	_apply_default_server()
	_update_status("未连接")


func _exit_tree() -> void:
	if _controller != null and _controller.state_changed.is_connected(_on_state_changed):
		_controller.state_changed.disconnect(_on_state_changed)
	if _controller != null and _controller.login_succeeded.is_connected(_on_login_succeeded):
		_controller.login_succeeded.disconnect(_on_login_succeeded)


func _resolve_controller() -> LoginController:
	var resolved_controller: BaseController = ControllerManager.get_or_register_controller(
		LoginController.CONTROLLER_ID,
		func() -> BaseController:
			return LoginController.new()
	)
	return resolved_controller as LoginController


func _connect_controller_signals() -> void:
	if not _controller.state_changed.is_connected(_on_state_changed):
		_controller.state_changed.connect(_on_state_changed)
	if not _controller.login_succeeded.is_connected(_on_login_succeeded):
		_controller.login_succeeded.connect(_on_login_succeeded)


func _connect_view_signals() -> void:
	select_server_button.pressed.connect(_on_select_server_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	login_button.pressed.connect(_on_login_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	back_button.pressed.connect(_on_back_pressed)
	server_select_popup.server_selected.connect(_on_server_selected)
	server_select_popup.cancelled.connect(_on_server_select_cancelled)


func _apply_default_server() -> void:
	if SERVER_LIST.is_empty():
		return
	var default_server: Dictionary = SERVER_LIST[0]
	_set_selected_server(
		StringName(str(default_server.get("id", ""))),
		str(default_server.get("name", "未命名服务器")),
		str(default_server.get("gateway_url", "mock://gateway"))
	)


func _set_selected_server(server_id: StringName, server_name: String, gateway_url: String) -> void:
	_selected_server_id = server_id
	_selected_server_name = server_name
	_selected_gateway_url = gateway_url
	selected_server_label.text = "当前服务器：%s" % _selected_server_name


func _on_select_server_pressed() -> void:
	server_select_popup.open_popup(SERVER_LIST, _selected_server_id)


func _on_connect_pressed() -> void:
	_controller.request_connect(_selected_gateway_url)


func _on_login_pressed() -> void:
	_controller.request_login(account_edit.text, password_edit.text)


func _on_disconnect_pressed() -> void:
	_controller.request_disconnect()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_server_selected(server_id: StringName, server_name: String, gateway_url: String) -> void:
	_set_selected_server(server_id, server_name, gateway_url)
	_update_status("已切换到服务器：%s" % server_name)


func _on_server_select_cancelled() -> void:
	_update_status("已取消服务器选择")


func _on_state_changed(_status: StringName, message: String) -> void:
	_update_status(message)


func _on_login_succeeded(token: String) -> void:
	login_completed.emit(token)


func _update_status(message: String) -> void:
	status_label.text = "状态：%s" % message
