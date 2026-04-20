class_name HomeLayer
extends BaseUI

#region 信号
signal tab_context_changed(tab_id: StringName, tab_title: String, tab_params: Dictionary)
#endregion

#region 状态
const SLOT_ID: StringName = &"ContentSlot"
const TAB_BACKPACK: StringName = &"backpack"
const TAB_BATTLE: StringName = &"battle"
const TAB_WORLD: StringName = &"world"
const TAB_GENERAL: StringName = &"general"

const TAB_UI_IDS: Dictionary[StringName, StringName] = {
	TAB_BACKPACK: UIRegistry.HOME_BACKPACK_TAB_CONTENT,
	TAB_BATTLE: UIRegistry.HOME_BATTLE_TAB_CONTENT,
	TAB_WORLD: UIRegistry.HOME_WORLD_TAB_CONTENT,
	TAB_GENERAL: UIRegistry.HOME_GENERAL_TAB_CONTENT
}

const TAB_LABELS: Dictionary[StringName, String] = {
	TAB_BACKPACK: "背包",
	TAB_BATTLE: "战斗",
	TAB_WORLD: "世界",
	TAB_GENERAL: "武将"
}

var _home_controller: HomeController = null
var _active_tab: StringName = StringName()
#endregion


#region 节点引用
@export var content_slot_path: NodePath
@export var backpack_tab_button_path: NodePath
@export var battle_tab_button_path: NodePath
@export var world_tab_button_path: NodePath
@export var general_tab_button_path: NodePath

@onready var content_slot: Control = get_node(content_slot_path) as Control
@onready var backpack_tab_button: Button = get_node(backpack_tab_button_path) as Button
@onready var battle_tab_button: Button = get_node(battle_tab_button_path) as Button
@onready var world_tab_button: Button = get_node(world_tab_button_path) as Button
@onready var general_tab_button: Button = get_node(general_tab_button_path) as Button
#endregion

#region 生命周期
func on_ui_create(_params: Dictionary) -> void:
	var controller: BaseController = ControllerManager.get_controller(HomeController.CONTROLLER_ID)
	_home_controller = controller as HomeController
	if _home_controller == null:
		push_error("HomeLayer 初始化失败：HomeController 未注册到 ControllerManager。")
		return
	_home_controller.status_changed.connect(_on_status_changed)
	_bind_tab_buttons()
	_select_tab(TAB_BACKPACK)
#endregion

#region 交互与显示
func _bind_tab_buttons() -> void:
	backpack_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_BACKPACK))
	battle_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_BATTLE))
	world_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_WORLD))
	general_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_GENERAL))


func _on_tab_pressed(tab_id: StringName) -> void:
	_select_tab(tab_id)


func _select_tab(tab_id: StringName) -> void:
	if _home_controller == null:
		return

	var tab_ui_id: StringName = TAB_UI_IDS.get(tab_id, StringName())
	if tab_ui_id == StringName():
		push_warning("[HomeLayer] 未注册页签：%s" % String(tab_id))
		return

	var tab_title: String = TAB_LABELS.get(tab_id, "")
	var tab_params: Dictionary = {
		"title": tab_title
	}

	if _active_tab == tab_id:
		_emit_tab_context_changed(tab_id, tab_title, tab_params)
		_home_controller.on_module_tab_selected(tab_title)
		return

	if _active_tab == StringName():
		UIManager.open_attach(ui_id, SLOT_ID, tab_ui_id, tab_params)
	else:
		UIManager.switch_attach(ui_id, SLOT_ID, tab_ui_id, tab_params)

	_active_tab = tab_id
	_home_controller.on_module_tab_selected(tab_title)
	_emit_tab_context_changed(tab_id, tab_title, tab_params)


func _on_status_changed(_message: String) -> void:
	# 当前界面已移除状态文本，仅保留控制器回调链路。
	pass
#endregion


#region 内部逻辑
func _emit_tab_context_changed(tab_id: StringName, tab_title: String, tab_params: Dictionary) -> void:
	tab_context_changed.emit(tab_id, tab_title, tab_params)
#endregion
