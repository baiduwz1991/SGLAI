class_name LoginNode
extends Node

const GAME_LOGIN_MGR_SCRIPT: Script = preload("res://src/modules/login/core/GameLoginMgr.gd")

## 完整登录流程成功（网关登录 + 初始化数据）。
signal login_flow_completed(init_payload: Dictionary)
## 完整登录流程失败。
signal login_flow_failed(error_payload: Dictionary)

var game_login_mgr: RefCounted


func _ready() -> void:
	if game_login_mgr == null:
		game_login_mgr = GAME_LOGIN_MGR_SCRIPT.new()
		game_login_mgr.init()


## 点击“开始游戏”后调用，严格按顺序：
## 1) 维护/热更检查
## 2) Connect(current_server.server_url)
## 3) request_user_login()
func try_login_game() -> void:
	if not _check_maintenance():
		login_flow_failed.emit({"reason": "服务器维护中"})
		return
	if not _check_hot_update():
		login_flow_failed.emit({"reason": "热更校验未通过"})
		return

	var current_server: Dictionary = game_login_mgr.get_current_server()
	var server_url: String = str(current_server.get("server_url", ""))
	if server_url.is_empty():
		login_flow_failed.emit({"reason": "未选择服务器"})
		return

	print("[LoginNode] 准备连接游戏服: %s" % server_url)
	var connect_error: Error = NetManager.connect_game_server(server_url, _on_game_server_connected)
	if connect_error != OK:
		login_flow_failed.emit({"reason": "连接游戏服务器失败", "error": int(connect_error)})


func request_user_login() -> void:
	var current_server: Dictionary = game_login_mgr.get_current_server()
	var login_payload: Dictionary = game_login_mgr.get_login_payload()
	var platform: Node = _get_platform()
	if platform == null:
		login_flow_failed.emit({"reason": "Platform 未初始化"})
		return

	var request_data: Dictionary = {
		"PartnerId": str(platform.get("partner_id")),
		"ServerId": str(current_server.get("server_id", current_server.get("ServerID", ""))),
		"UserId": str(login_payload.get("user_id", "")),
		"GameVersionId": str(platform.get("version")),
		"Token": str(login_payload.get("token", ""))
	}
	print("[LoginNode] 发送网关登录请求: %s" % JSON.stringify(request_data))

	var requested: bool = NetManager.request_login(
		request_data,
		_on_gateway_login_succeeded,
		_on_gateway_login_failed
	)
	if not requested:
		login_flow_failed.emit({"reason": "发送网关登录请求失败"})


func _on_game_server_connected(connected: bool) -> void:
	if not connected:
		login_flow_failed.emit({"reason": "游戏服连接断开"})
		return
	print("[LoginNode] 游戏服连接成功，开始网关登录。")
	request_user_login()


func _on_gateway_login_succeeded(_payload: Dictionary) -> void:
	print("[LoginNode] 网关登录成功，开始拉取玩家初始化数据。")
	var requested: bool = NetManager.request_player_init_data(
		_on_player_init_data_succeeded,
		_on_player_init_data_failed
	)
	if not requested:
		login_flow_failed.emit({"reason": "请求玩家初始化数据失败"})


func _on_gateway_login_failed(error_payload: Dictionary) -> void:
	push_warning("[LoginNode] 网关登录失败: %s" % JSON.stringify(error_payload))
	login_flow_failed.emit({"reason": "网关登录失败", "raw": error_payload})


func _on_player_init_data_succeeded(init_payload: Dictionary) -> void:
	print("[LoginNode] 玩家初始化数据拉取成功。")
	login_flow_completed.emit(init_payload)


func _on_player_init_data_failed(error_payload: Dictionary) -> void:
	push_warning("[LoginNode] 玩家初始化数据拉取失败: %s" % JSON.stringify(error_payload))
	login_flow_failed.emit({"reason": "初始化数据拉取失败", "raw": error_payload})


func _check_maintenance() -> bool:
	# 维护检查占位：后续接真实维护接口或配置。
	return true


func _check_hot_update() -> bool:
	# 热更检查占位：后续接热更模块状态机。
	return true


func _get_platform() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Platform")
