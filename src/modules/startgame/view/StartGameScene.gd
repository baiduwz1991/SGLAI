class_name StartGameScene
extends BaseUI

#region 常量
const LOGIN_CONTROLLER_SCRIPT: Script = preload("res://src/modules/login/core/LoginController.gd")
const HOME_TEST_CONTROLLER_SCRIPT: Script = preload("res://src/modules/homeTest/core/HomeTestController.gd")
#endregion

#region 状态
var _login_ui: BaseUI = null
#endregion

#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	_register_all_controllers()

	var platform: Node = get_tree().root.get_node_or_null("Platform")
	if platform == null:
		push_warning("StartGameScene 未找到 Platform autoload，按开发模式直接进入登录界面。")
		ControllerManager.notify_game_start()
		_try_open_login_panel_for_dev_test()
		return

	platform.init_completed.connect(_on_platform_init_completed, CONNECT_ONE_SHOT)
	platform.call("init")


func _on_platform_init_completed() -> void:
	ControllerManager.notify_game_start()
	_try_open_login_panel_for_dev_test()
#endregion

#region 内部逻辑
func _register_all_controllers() -> void:
	ControllerManager.get_or_register_controller(
		LoginController.CONTROLLER_ID,
		func() -> BaseController:
			return LOGIN_CONTROLLER_SCRIPT.new() as LoginController
	)
	ControllerManager.get_or_register_controller(
		HomeTestController.CONTROLLER_ID,
		func() -> BaseController:
			return HOME_TEST_CONTROLLER_SCRIPT.new() as HomeTestController
	)


func _try_open_login_panel_for_dev_test() -> void:
	if not _is_dev_test_environment():
		return
	_open_login_panel()


func _is_dev_test_environment() -> bool:
	return OS.has_feature("editor") or OS.has_feature("debug")


func _open_login_panel() -> void:
	if is_instance_valid(_login_ui):
		return

	_login_ui = UIManager.open_attach(ui_id, &"default", UIRegistry.LOGIN_PANEL, {})
	if _login_ui == null:
		push_error("StartGameScene 以 MODE_ATTACH 打开 LoginPanel 失败。")
#endregion
