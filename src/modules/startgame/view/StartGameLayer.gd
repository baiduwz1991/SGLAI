class_name StartGameLayer
extends BaseUI

#region 常量
const LOGIN_CONTROLLER_SCRIPT: Script = preload("res://src/modules/login/core/LoginController.gd")
const HOME_CONTROLLER_SCRIPT: Script = preload("res://src/modules/home/core/HomeController.gd")
#endregion

#region 状态
var _login_ui: BaseUI = null
@export var auto_open_login_panel: bool = true
@export var wechat_follow_dev_login_flow: bool = true
#endregion

#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	_register_all_controllers()

	var platform: Node = get_tree().root.get_node_or_null("Platform")
	if platform == null:
		push_warning("StartGameLayer 未找到 Platform autoload，按开发模式直接进入登录界面。")
		ControllerManager.notify_game_start()
		_try_open_login_panel()
		return

	platform.init_completed.connect(_on_platform_init_completed, CONNECT_ONE_SHOT)
	platform.call("init")


func _on_platform_init_completed() -> void:
	ControllerManager.notify_game_start()
	_try_open_login_panel()
#endregion

#region 内部逻辑
func _register_all_controllers() -> void:
	ControllerManager.get_or_register_controller(
		LoginController.CONTROLLER_ID,
		func() -> BaseController:
			return LOGIN_CONTROLLER_SCRIPT.new() as LoginController
	)
	ControllerManager.get_or_register_controller(
		HomeController.CONTROLLER_ID,
		func() -> BaseController:
			return HOME_CONTROLLER_SCRIPT.new() as HomeController
	)


func _try_open_login_panel() -> void:
	if not _should_open_login_panel():
		return
	_open_login_panel()


func _should_open_login_panel() -> bool:
	if not auto_open_login_panel:
		return false
	if _is_dev_test_environment():
		return true
	if _is_wechat_runtime() and wechat_follow_dev_login_flow:
		return true
	return false


func _is_dev_test_environment() -> bool:
	return OS.has_feature("editor") or OS.has_feature("debug")


func _is_wechat_runtime() -> bool:
	# 临时策略：将微信小游戏运行时按开发端流程打开登录面板。
	return OS.has_feature("web") and not OS.has_feature("editor")


func _open_login_panel() -> void:
	if is_instance_valid(_login_ui):
		return

	_login_ui = UIManager.open_attach(ui_id, &"default", UIRegistry.LOGIN_PANEL, {})
	if _login_ui == null:
		push_error("StartGameLayer 以 MODE_ATTACH 打开 LoginPanel 失败。")
#endregion
