class_name SelectServerPanel
extends BaseUI

const HOME_PAGE_ID: StringName = UIRegistry.HOME_LAYER

var _login_controller: LoginController = null

@export var status_label_path: NodePath
@export var server_label_path: NodePath
@export var open_server_list_button_path: NodePath
@export var announcement_button_path: NodePath
@export var enter_game_button_path: NodePath

@onready var status_label: Label = get_node(status_label_path) as Label
@onready var server_label: Label = get_node(server_label_path) as Label
@onready var open_server_list_button: Button = get_node(open_server_list_button_path) as Button
@onready var announcement_button: Button = get_node(announcement_button_path) as Button
@onready var enter_game_button: Button = get_node(enter_game_button_path) as Button


func on_ui_create(_params: Dictionary) -> void:
	var controller: BaseController = ControllerManager.get_controller(LoginController.CONTROLLER_ID)
	_login_controller = controller as LoginController
	if _login_controller == null:
		push_error("SelectServerPanel 初始化失败：LoginController 未注册。")
		return
	_login_controller.bind_host(self)

	open_server_list_button.pressed.connect(_on_open_server_list_button_pressed)
	announcement_button.pressed.connect(_on_announcement_button_pressed)
	enter_game_button.pressed.connect(_on_enter_game_button_pressed)


func on_ui_open(_params: Dictionary) -> void:
	_refresh_current_server_label()
	_set_status_text("请选择服务器后进入游戏。")


func _on_open_server_list_button_pressed() -> void:
	if _login_controller == null:
		return
	var server_candidates: Array[Dictionary] = _login_controller.get_server_list()
	if server_candidates.is_empty():
		_set_status_text("暂无可选服务器。")
		return

	var popup_ui: BaseUI = UIManager.open_overlay(
		UIRegistry.SERVER_LIST_POP_LAYER,
		{
			"servers": server_candidates,
			"current_server": _login_controller.get_current_server()
		}
	)
	var server_popup: ServerListPopLayer = popup_ui as ServerListPopLayer
	if server_popup == null:
		push_warning("[SelectServerPanel] 打开 ServerListPopLayer 失败。")
		return

	if not server_popup.server_selected.is_connected(_on_server_selected):
		server_popup.server_selected.connect(_on_server_selected)


func _on_announcement_button_pressed() -> void:
	_set_status_text("公告功能待接入。")


func _on_enter_game_button_pressed() -> void:
	if _login_controller == null:
		return
	var current_server: Dictionary = _login_controller.get_current_server()
	if current_server.is_empty():
		_set_status_text("请先选择服务器。")
		return

	_enter_home_scene()


func _enter_home_scene() -> void:
	ControllerManager.notify_game_server_login(func() -> void:
		var home_ui: BaseUI = UIManager.open_ui(HOME_PAGE_ID, {}, UIManager.MODE_REPLACE)
		if home_ui == null:
			push_warning("[SelectServerPanel] 打开 home 页面失败。")
	)


func _on_server_selected(server_data: Dictionary) -> void:
	if _login_controller == null:
		return
	_login_controller.set_current_server(server_data)
	_refresh_current_server_label()
	_set_status_text("已切换服务器：%s" % str(server_data.get("server_name", "未命名服务器")))


func _refresh_current_server_label() -> void:
	if _login_controller == null:
		server_label.text = "当前服务器：-"
		return

	var current_server: Dictionary = _login_controller.get_current_server()
	if current_server.is_empty():
		server_label.text = "当前服务器：未选择"
		return

	var server_name: String = str(current_server.get("server_name", "未命名服务器"))
	var server_url: String = str(current_server.get("server_url", ""))
	server_label.text = "当前服务器：%s\n地址：%s" % [server_name, server_url]


func _set_status_text(text: String) -> void:
	status_label.text = text
