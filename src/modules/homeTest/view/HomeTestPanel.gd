class_name HomeTestPanel
extends BaseUI

#region 状态
var _home_test_controller: HomeTestController = null
@onready var _status_label: Label = get_node_or_null("SafeArea/RootVBox/StatusLabel")
#endregion

#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	var controller: BaseController = ControllerManager.get_controller(HomeTestController.CONTROLLER_ID)
	_home_test_controller = controller as HomeTestController
	if _home_test_controller == null:
		push_error("HomeTestPanel 初始化失败：HomeTestController 未注册到 ControllerManager。")
		return
	_home_test_controller.status_changed.connect(_on_status_changed)
	_bind_button("SafeArea/RootVBox/ButtonGrid/BackpackButton", "背包")
	_bind_button("SafeArea/RootVBox/ButtonGrid/BattleButton", "战斗")
	_bind_button("SafeArea/RootVBox/ButtonGrid/WorldButton", "世界")
	_bind_button("SafeArea/RootVBox/ButtonGrid/GeneralButton", "武将")
	_set_status("已进入 homeTest。")
#endregion

#region 交互与显示
func _bind_button(path: NodePath, module_name: String) -> void:
	var button: Button = get_node_or_null(path)
	if button == null:
		push_warning("[HomeTestPanel] 按钮节点不存在：%s" % String(path))
		return
	button.pressed.connect(_on_module_button_pressed.bind(module_name))


func _on_module_button_pressed(module_name: String) -> void:
	_home_test_controller.on_module_button_pressed(module_name)


func _on_status_changed(message: String) -> void:
	_set_status(message)


func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
#endregion
