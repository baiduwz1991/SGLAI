class_name LoginPanel
extends BaseUI

#region 配置与常量
@export var default_username: String = "yy@y1.yy"
@export var default_password: String = "yy"

const HOME_TEST_PAGE_ID: StringName = UIRegistry.HOME_TEST_PANEL
#endregion

#region 状态
var _login_controller: LoginController = null
#endregion

#region 节点引用
@export var status_label_path: NodePath

@export var login_root_path: NodePath
@export var username_input_path: NodePath
@export var password_input_path: NodePath
@export var login_button_path: NodePath
@export var register_button_path: NodePath

@export var server_root_path: NodePath
@export var server_label_path: NodePath
@export var open_server_list_button_path: NodePath
@export var enter_game_button_path: NodePath

@onready var status_label: Label = get_node(status_label_path) as Label
@onready var login_root: VBoxContainer = get_node(login_root_path) as VBoxContainer
@onready var username_input: LineEdit = get_node(username_input_path) as LineEdit
@onready var password_input: LineEdit = get_node(password_input_path) as LineEdit
@onready var login_button: Button = get_node(login_button_path) as Button
@onready var register_button: Button = get_node(register_button_path) as Button
@onready var server_root: VBoxContainer = get_node(server_root_path) as VBoxContainer
@onready var server_label: Label = get_node(server_label_path) as Label
@onready var open_server_list_button: Button = get_node(open_server_list_button_path) as Button
@onready var enter_game_button: Button = get_node(enter_game_button_path) as Button
#endregion

#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	var controller: BaseController = ControllerManager.get_controller(LoginController.CONTROLLER_ID)
	_login_controller = controller as LoginController
	if _login_controller == null:
		push_error("LoginPanel 初始化失败：LoginController 未注册到 ControllerManager。")
		return
	_login_controller.bind_host(self)
	_login_controller.login_state_changed.connect(_on_login_state_changed)
	_login_controller.login_failed.connect(_on_login_failed)
	_login_controller.server_list_ready.connect(_on_server_list_ready)
	_login_controller.login_flow_completed.connect(_on_login_flow_completed)
	_login_controller.login_flow_failed.connect(_on_login_flow_failed)

	username_input.focus_entered.connect(_on_username_focus_entered)
	password_input.focus_entered.connect(_on_password_focus_entered)
	_apply_default_credentials_if_needed()
	_switch_to_login_view()

	login_button.pressed.connect(_on_login_button_pressed)
	register_button.pressed.connect(_on_register_button_pressed)
	open_server_list_button.pressed.connect(_on_open_server_list_button_pressed)
	enter_game_button.pressed.connect(_on_enter_game_button_pressed)


func on_ui_open(_params: Dictionary) -> void:
	refresh_view()
#endregion

#region 业务流程
## 对齐 Lua 流程：RefreshView() 先 Clear()，再 RequestLogin()。
func refresh_view() -> void:
	if _login_controller == null:
		return
	_login_controller.reset_login_context()
	_switch_to_login_view()
	_set_status_text("请输入账号密码，点击登录开始联调。")


func on_click_start_game() -> void:
	_enter_home_test_scene()
#endregion

#region UI事件
func _on_login_button_pressed() -> void:
	var username: String = default_username
	var password: String = default_password
	username = username_input.text.strip_edges()
	password = password_input.text
	_login_controller.request_login(username, password)


func _on_register_button_pressed() -> void:
	var username: String = default_username
	var password: String = default_password
	username = username_input.text.strip_edges()
	password = password_input.text
	_login_controller.request_register(username, password)


func _on_open_server_list_button_pressed() -> void:
	_open_server_popup()


func _on_enter_game_button_pressed() -> void:
	_enter_home_test_scene()


func _on_login_state_changed(_state: StringName, message: String) -> void:
	print("[LoginPanel] %s" % message)
	_set_status_text(message)


func _on_login_failed(error_payload: Dictionary) -> void:
	push_warning("[LoginPanel] 登录失败：%s" % JSON.stringify(error_payload))
	_set_status_text("登录失败：%s" % JSON.stringify(error_payload))
	_switch_to_login_view()


func _on_server_list_ready() -> void:
	print("[LoginPanel] 服表准备完成，进入选服界面。")
	_switch_to_server_view()
	_refresh_current_server_label()
	_set_status_text("请选择服务器，点击“进入游戏”直接进入 homeTest。")


func _on_login_flow_completed(_init_payload: Dictionary) -> void:
	print("[LoginPanel] 登录主流程完成，进入主场景或创角流程。")
	_set_status_text("登录主流程完成，联调成功。")


func _on_login_flow_failed(error_payload: Dictionary) -> void:
	push_warning("[LoginPanel] 登录主流程失败：%s" % JSON.stringify(error_payload))
	_set_status_text("登录主流程失败：%s" % JSON.stringify(error_payload))
#endregion

#region 弹窗与选服
func _open_server_popup() -> void:
	if _login_controller == null:
		return

	var server_candidates: Array[Dictionary] = _login_controller.get_server_list()
	if server_candidates.is_empty():
		_set_status_text("暂无可选服务器。")
		return

	var popup_ui: BaseUI = UIManager.open_overlay(
		UIRegistry.SERVER_LIST_POPUP,
		{
			"servers": server_candidates,
			"current_server": _login_controller.get_current_server()
		}
	)
	var server_popup: ServerListPopup = popup_ui as ServerListPopup
	if server_popup == null:
		push_warning("[LoginPanel] 打开 ServerListPopup 失败。")
		return

	if not server_popup.server_selected.is_connected(_on_server_selected):
		server_popup.server_selected.connect(_on_server_selected)


func _on_server_selected(server_data: Dictionary) -> void:
	_login_controller.set_current_server(server_data)
	_refresh_current_server_label()
	_set_status_text("已切换服务器：%s" % str(server_data.get("server_name", "未命名服务器")))
#endregion

#region 视图状态
func _refresh_current_server_label() -> void:
	var current_server: Dictionary = _login_controller.get_current_server()
	var server_name: String = str(current_server.get("server_name", "未命名服务器"))
	var server_url: String = str(current_server.get("server_url", ""))
	server_label.text = "当前服务器：%s\n地址：%s" % [server_name, server_url]


func _switch_to_login_view() -> void:
	login_root.visible = true
	server_root.visible = false


func _switch_to_server_view() -> void:
	login_root.visible = false
	server_root.visible = true


func _set_status_text(text: String) -> void:
	status_label.text = text
#endregion


#region 输入体验
func _apply_default_credentials_if_needed() -> void:
	if _should_prefill_credentials():
		username_input.text = default_username
		password_input.text = default_password
		return
	# 微信/Web 端避免预填文本，规避输入桥接“只能追加不可删除”的问题。
	username_input.clear()
	password_input.clear()


func _should_prefill_credentials() -> bool:
	# 仅在编辑器/调试环境预填联调账号，发布端（尤其 Web/微信）不预填。
	return OS.has_feature("editor") or OS.has_feature("debug")


func _on_username_focus_entered() -> void:
	username_input.select_all()


func _on_password_focus_entered() -> void:
	password_input.select_all()
#endregion

#region 跳转
func _enter_home_test_scene() -> void:
	# 临时测试链路：绕过网关登录，但显式触发所有控制器 on_game_server_login，
	# 让控制器侧行为与“网关登录成功后”保持一致。
	ControllerManager.notify_game_server_login(func() -> void:
		var home_test_ui: BaseUI = UIManager.open_ui(HOME_TEST_PAGE_ID, {}, UIManager.MODE_REPLACE)
		if home_test_ui == null:
			push_warning("[LoginPanel] 打开 homeTest 页面失败。")
	)
#endregion
