class_name GameMain
extends Node

const GAME_LOGIN_PANEL_SCRIPT: Script = preload("res://src/modules/login/view/GameLoginPanel.gd")

## 仅用于未来“启动编排/闪屏过渡”场景：
## - 当前项目主场景是 Login.tscn（直接进入登录联调界面）
## - 因此默认启动流程不会走到 GameMain
## - 后续若需要“先启动页再登录页”，可将 run/main_scene 切到 GameMain 对应场景
@export var login_panel_scene: PackedScene
var _login_panel: Control


func _ready() -> void:
	# 当前未启用说明：
	# 只有当此脚本所在场景被设为主场景时，才会执行下面的启动编排逻辑。
	# 启动后先监听平台 Init 事件，再拉起登录面板（可在此之前加闪屏流程）。
	var platform: Node = get_tree().root.get_node_or_null("Platform")
	if platform == null:
		push_warning("GameMain 未找到 Platform autoload，跳过启动编排。")
		return
	platform.init_completed.connect(_on_platform_init_completed, CONNECT_ONE_SHOT)
	platform.call("init")


func _on_platform_init_completed() -> void:
	_open_login_panel()


func _open_login_panel() -> void:
	if login_panel_scene != null:
		var panel_instance: Node = login_panel_scene.instantiate()
		_login_panel = panel_instance as Control
		add_child(panel_instance)
	else:
		_login_panel = GAME_LOGIN_PANEL_SCRIPT.new()
		add_child(_login_panel)

	# 对齐目标流程：面板刷新触发登录请求。
	_login_panel.refresh_view()
