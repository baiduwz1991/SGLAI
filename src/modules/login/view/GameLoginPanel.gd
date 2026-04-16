class_name GameLoginPanel
extends Control

@export var default_username: String = "yy@y1.yy"
@export var default_password: String = "yy"

const GAME_LOGIN_MGR_SCRIPT: Script = preload("res://src/modules/login/core/GameLoginMgr.gd")
const LOGIN_NODE_SCRIPT: Script = preload("res://src/modules/login/core/LoginNode.gd")

var _game_login_mgr: RefCounted = GAME_LOGIN_MGR_SCRIPT.new()
var _login_node: Node
var _popup_server_candidates: Array[Dictionary] = []

@onready var _status_label: Label = get_node_or_null("Panel/Margin/RootVBox/StatusLabel")

@onready var _login_root: VBoxContainer = get_node_or_null("Panel/Margin/RootVBox/LoginRoot")
@onready var _username_input: LineEdit = get_node_or_null("Panel/Margin/RootVBox/LoginRoot/UsernameInput")
@onready var _password_input: LineEdit = get_node_or_null("Panel/Margin/RootVBox/LoginRoot/PasswordInput")
@onready var _login_button: Button = get_node_or_null("Panel/Margin/RootVBox/LoginRoot/ButtonRow/LoginButton")
@onready var _register_button: Button = get_node_or_null("Panel/Margin/RootVBox/LoginRoot/ButtonRow/RegisterButton")

@onready var _server_root: VBoxContainer = get_node_or_null("Panel/Margin/RootVBox/ServerRoot")
@onready var _server_label: Label = get_node_or_null("Panel/Margin/RootVBox/ServerRoot/CurrentServerLabel")
@onready var _open_server_list_button: Button = get_node_or_null("Panel/Margin/RootVBox/ServerRoot/ServerButtonRow/OpenServerListButton")
@onready var _enter_game_button: Button = get_node_or_null("Panel/Margin/RootVBox/ServerRoot/ServerButtonRow/EnterGameButton")

@onready var _server_popup: PopupPanel = get_node_or_null("ServerListPopup")
@onready var _server_item_list: ItemList = get_node_or_null("ServerListPopup/Margin/VBox/ServerItemList")
@onready var _server_popup_confirm_button: Button = get_node_or_null("ServerListPopup/Margin/VBox/PopupButtonRow/ConfirmButton")
@onready var _server_popup_cancel_button: Button = get_node_or_null("ServerListPopup/Margin/VBox/PopupButtonRow/CancelButton")


func _ready() -> void:
	_game_login_mgr.init()
	_game_login_mgr.login_state_changed.connect(_on_login_state_changed)
	_game_login_mgr.login_failed.connect(_on_login_failed)
	_game_login_mgr.server_list_ready.connect(_on_server_list_ready)

	_login_node = LOGIN_NODE_SCRIPT.new()
	_login_node.game_login_mgr = _game_login_mgr
	_login_node.login_flow_completed.connect(_on_login_flow_completed)
	_login_node.login_flow_failed.connect(_on_login_flow_failed)
	add_child(_login_node)

	if _username_input != null:
		_username_input.text = default_username
	if _password_input != null:
		_password_input.text = default_password
	_switch_to_login_view()

	if _login_button != null:
		_login_button.pressed.connect(_on_login_button_pressed)
	if _register_button != null:
		_register_button.pressed.connect(_on_register_button_pressed)
	if _open_server_list_button != null:
		_open_server_list_button.pressed.connect(_on_open_server_list_button_pressed)
	if _enter_game_button != null:
		_enter_game_button.pressed.connect(_on_enter_game_button_pressed)
	if _server_popup_confirm_button != null:
		_server_popup_confirm_button.pressed.connect(_on_server_popup_confirm_pressed)
	if _server_popup_cancel_button != null:
		_server_popup_cancel_button.pressed.connect(_on_server_popup_cancel_pressed)
	if _server_item_list != null:
		_server_item_list.item_activated.connect(_on_server_item_activated)


## 对齐 Lua 流程：RefreshView() 先 Clear()，再 RequestLogin()。
func refresh_view() -> void:
	_game_login_mgr.clear()
	_switch_to_login_view()
	_set_status_text("请输入账号密码，点击登录开始联调。")


func on_click_start_game() -> void:
	_login_node.try_login_game()


func _on_login_button_pressed() -> void:
	var username: String = default_username
	var password: String = default_password
	if _username_input != null:
		username = _username_input.text.strip_edges()
	if _password_input != null:
		password = _password_input.text
	_game_login_mgr.clear()
	_game_login_mgr.request_login(username, password)


func _on_register_button_pressed() -> void:
	var username: String = default_username
	var password: String = default_password
	if _username_input != null:
		username = _username_input.text.strip_edges()
	if _password_input != null:
		password = _password_input.text
	_game_login_mgr.clear()
	_game_login_mgr.request_register(username, password)


func _on_open_server_list_button_pressed() -> void:
	_open_server_popup()


func _on_enter_game_button_pressed() -> void:
	on_click_start_game()


func _on_login_state_changed(_state: StringName, message: String) -> void:
	print("[GameLoginPanel] %s" % message)
	_set_status_text(message)


func _on_login_failed(error_payload: Dictionary) -> void:
	push_warning("[GameLoginPanel] 登录失败：%s" % JSON.stringify(error_payload))
	_set_status_text("登录失败：%s" % JSON.stringify(error_payload))
	_switch_to_login_view()


func _on_server_list_ready() -> void:
	print("[GameLoginPanel] 服表准备完成，进入选服界面。")
	_switch_to_server_view()
	_refresh_current_server_label()
	_set_status_text("请选择服务器，点击“进入游戏”发起网关登录。")


func _on_login_flow_completed(_init_payload: Dictionary) -> void:
	print("[GameLoginPanel] 登录主流程完成，进入主场景或创角流程。")
	_set_status_text("登录主流程完成，联调成功。")


func _on_login_flow_failed(error_payload: Dictionary) -> void:
	push_warning("[GameLoginPanel] 登录主流程失败：%s" % JSON.stringify(error_payload))
	_set_status_text("登录主流程失败：%s" % JSON.stringify(error_payload))


func _open_server_popup() -> void:
	if _server_popup == null or _server_item_list == null:
		return

	_popup_server_candidates = _game_login_mgr.get_server_list()
	_server_item_list.clear()
	for server in _popup_server_candidates:
		var server_name: String = str(server.get("server_name", "未命名服务器"))
		var server_id: String = str(server.get("server_id", ""))
		_server_item_list.add_item("%s (%s)" % [server_name, server_id])

	if _popup_server_candidates.is_empty():
		_set_status_text("暂无可选服务器。")
		return

	_server_item_list.select(0)
	_server_popup.popup_centered_ratio(0.6)


func _on_server_popup_confirm_pressed() -> void:
	if _server_item_list == null:
		return
	var selected_indexes: PackedInt32Array = _server_item_list.get_selected_items()
	if selected_indexes.is_empty():
		_set_status_text("请先选择一个服务器。")
		return
	_apply_server_selection(selected_indexes[0])


func _on_server_popup_cancel_pressed() -> void:
	if _server_popup != null:
		_server_popup.hide()


func _on_server_item_activated(index: int) -> void:
	_apply_server_selection(index)


func _apply_server_selection(index: int) -> void:
	if index < 0 or index >= _popup_server_candidates.size():
		return
	var server_data: Dictionary = _popup_server_candidates[index]
	_game_login_mgr.set_current_server(server_data)
	_refresh_current_server_label()
	_set_status_text("已切换服务器：%s" % str(server_data.get("server_name", "未命名服务器")))
	if _server_popup != null:
		_server_popup.hide()


func _refresh_current_server_label() -> void:
	var current_server: Dictionary = _game_login_mgr.get_current_server()
	var server_name: String = str(current_server.get("server_name", "未命名服务器"))
	var server_url: String = str(current_server.get("server_url", ""))
	if _server_label != null:
		_server_label.text = "当前服务器：%s\n地址：%s" % [server_name, server_url]


func _switch_to_login_view() -> void:
	if _login_root != null:
		_login_root.visible = true
	if _server_root != null:
		_server_root.visible = false


func _switch_to_server_view() -> void:
	if _login_root != null:
		_login_root.visible = false
	if _server_root != null:
		_server_root.visible = true


func _set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
