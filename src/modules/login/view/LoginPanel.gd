class_name LoginPanel
extends BaseUI

@export var default_username: String = "yy@y1.yy"
@export var default_password: String = "yy"

@export var status_label_path: NodePath
@export var username_input_path: NodePath
@export var password_input_path: NodePath
@export var login_button_path: NodePath
@export var register_button_path: NodePath

@onready var status_label: Label = get_node(status_label_path) as Label
@onready var username_input: LineEdit = get_node(username_input_path) as LineEdit
@onready var password_input: LineEdit = get_node(password_input_path) as LineEdit
@onready var login_button: Button = get_node(login_button_path) as Button
@onready var register_button: Button = get_node(register_button_path) as Button

var _login_controller: LoginController = null


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

	username_input.focus_entered.connect(_on_username_focus_entered)
	password_input.focus_entered.connect(_on_password_focus_entered)
	login_button.pressed.connect(_on_login_button_pressed)
	register_button.pressed.connect(_on_register_button_pressed)

	_apply_default_credentials_if_needed()


func on_ui_open(_params: Dictionary) -> void:
	refresh_view()


func refresh_view() -> void:
	if _login_controller == null:
		return
	_login_controller.reset_login_context()
	_set_status_text("请输入账号密码，点击登录开始联调。")


func _on_login_button_pressed() -> void:
	if _login_controller == null:
		return
	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text
	_login_controller.request_login(username, password)


func _on_register_button_pressed() -> void:
	if _login_controller == null:
		return
	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text
	_login_controller.request_register(username, password)


func _on_login_state_changed(_state: StringName, message: String) -> void:
	print("[LoginPanel] %s" % message)
	_set_status_text(message)


func _on_login_failed(error_payload: Dictionary) -> void:
	push_warning("[LoginPanel] 登录失败：%s" % JSON.stringify(error_payload))
	_set_status_text("登录失败：%s" % JSON.stringify(error_payload))


func _on_server_list_ready() -> void:
	print("[LoginPanel] 服表准备完成，切换到 SelectServerPanel。")
	var parent_id: StringName = parent_ui_id
	if parent_id == StringName():
		parent_id = UIRegistry.START_GAME_LAYER
	var target_slot: StringName = slot_id
	if target_slot == StringName():
		target_slot = &"default"

	var next_panel: BaseUI = UIManager.switch_attach(
		parent_id,
		target_slot,
		UIRegistry.SELECT_SERVER_PANEL,
		{}
	)
	if next_panel == null:
		push_warning("[LoginPanel] 切换 SelectServerPanel 失败。")


func _set_status_text(text: String) -> void:
	status_label.text = text


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
