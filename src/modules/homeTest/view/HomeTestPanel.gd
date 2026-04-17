class_name HomeTestPanel
extends BaseUI

#region 状态
const SLOT_ID: StringName = &"ContentSlot"
const TAB_BACKPACK: StringName = &"backpack"
const TAB_BATTLE: StringName = &"battle"
const TAB_WORLD: StringName = &"world"
const TAB_GENERAL: StringName = &"general"

const TAB_UI_IDS: Dictionary[StringName, StringName] = {
	TAB_BACKPACK: UIRegistry.HOME_TAB_BACKPACK,
	TAB_BATTLE: UIRegistry.HOME_TAB_BATTLE,
	TAB_WORLD: UIRegistry.HOME_TAB_WORLD,
	TAB_GENERAL: UIRegistry.HOME_TAB_GENERAL
}

const TAB_LABELS: Dictionary[StringName, String] = {
	TAB_BACKPACK: "背包",
	TAB_BATTLE: "战斗",
	TAB_WORLD: "世界",
	TAB_GENERAL: "武将"
}

var _home_test_controller: HomeTestController = null
var _active_tab: StringName = StringName()
@onready var _content_slot: Control = get_node_or_null("ContentSlot")
@onready var _backpack_tab_button: Button = get_node_or_null("TabBar/BackpackTabButton")
@onready var _battle_tab_button: Button = get_node_or_null("TabBar/BattleTabButton")
@onready var _world_tab_button: Button = get_node_or_null("TabBar/WorldTabButton")
@onready var _general_tab_button: Button = get_node_or_null("TabBar/GeneralTabButton")
#endregion

#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	var controller: BaseController = ControllerManager.get_controller(HomeTestController.CONTROLLER_ID)
	_home_test_controller = controller as HomeTestController
	if _home_test_controller == null:
		push_error("HomeTestPanel 初始化失败：HomeTestController 未注册到 ControllerManager。")
		return
	_home_test_controller.status_changed.connect(_on_status_changed)
	_bind_tab_buttons()
	_select_tab(TAB_BACKPACK)
#endregion

#region 交互与显示
func _bind_tab_buttons() -> void:
	if _backpack_tab_button != null:
		_backpack_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_BACKPACK))
	if _battle_tab_button != null:
		_battle_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_BATTLE))
	if _world_tab_button != null:
		_world_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_WORLD))
	if _general_tab_button != null:
		_general_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_GENERAL))


func _on_tab_pressed(tab_id: StringName) -> void:
	_select_tab(tab_id)


func _select_tab(tab_id: StringName) -> void:
	if _home_test_controller == null:
		return
	if _content_slot == null:
		push_warning("[HomeTestPanel] ContentSlot 不存在，无法切换页签。")
		return
	if _active_tab == tab_id:
		return

	var tab_ui_id: StringName = TAB_UI_IDS.get(tab_id, StringName())
	if tab_ui_id == StringName():
		push_warning("[HomeTestPanel] 未注册页签：%s" % String(tab_id))
		return

	var tab_title: String = TAB_LABELS.get(tab_id, "")
	var tab_params: Dictionary = {
		"title": tab_title
	}

	if _active_tab == StringName():
		UIManager.open_attach(ui_id, SLOT_ID, tab_ui_id, tab_params)
	else:
		UIManager.switch_attach(ui_id, SLOT_ID, tab_ui_id, tab_params)

	_active_tab = tab_id
	_home_test_controller.on_module_tab_selected(tab_title)


func _on_status_changed(_message: String) -> void:
	# 当前界面已移除状态文本，仅保留控制器回调链路。
	pass
#endregion
