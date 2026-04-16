class_name LoginController
extends BaseController

const CONTROLLER_ID: StringName = &"login_controller"
const GAME_LOGIN_MGR_SCRIPT: Script = preload("res://src/modules/login/core/GameLoginMgr.gd")
const LOGIN_NODE_SCRIPT: Script = preload("res://src/modules/login/core/LoginNode.gd")

signal login_state_changed(state: StringName, message: String)
signal login_failed(error_payload: Dictionary)
signal server_list_ready
signal login_flow_completed(init_payload: Dictionary)
signal login_flow_failed(error_payload: Dictionary)

var _game_login_mgr: GameLoginMgr = GAME_LOGIN_MGR_SCRIPT.new() as GameLoginMgr
var _login_node: LoginNode = null
var _host: Node = null


func get_id() -> StringName:
	return CONTROLLER_ID


func bind_host(host: Node) -> void:
	_host = host
	_ensure_login_node()
	if _host == null or _login_node == null:
		return
	if _login_node.get_parent() == null:
		_host.add_child(_login_node)


func on_game_start() -> void:
	_bind_game_login_mgr_signals()
	_game_login_mgr.init()
	if _host != null and _login_node != null and _login_node.get_parent() == null:
		_host.add_child(_login_node)


func on_game_server_login(back: Callable = Callable()) -> void:
	_game_login_mgr.clear()
	_call_back(back)


func on_reconnection(back: Callable = Callable()) -> void:
	_call_back(back)


func on_login_out() -> void:
	_game_login_mgr.clear()


func on_release() -> void:
	if is_instance_valid(_login_node):
		_login_node.queue_free()
	_login_node = null
	_host = null
	super.on_release()


func request_login(username: String, password: String) -> void:
	_game_login_mgr.clear()
	_game_login_mgr.request_login(username, password)


func request_register(username: String, password: String) -> void:
	_game_login_mgr.clear()
	_game_login_mgr.request_register(username, password)


func get_server_list() -> Array[Dictionary]:
	return _game_login_mgr.get_server_list()


func set_current_server(server_data: Dictionary) -> void:
	_game_login_mgr.set_current_server(server_data)


func get_current_server() -> Dictionary:
	return _game_login_mgr.get_current_server()


func reset_login_context() -> void:
	_game_login_mgr.clear()


func try_login_game() -> void:
	if _login_node == null:
		login_flow_failed.emit({"reason": "LoginNode 未初始化"})
		return
	_login_node.try_login_game()


func _ensure_login_node() -> void:
	if _login_node != null:
		return
	_login_node = LOGIN_NODE_SCRIPT.new() as LoginNode
	if _login_node == null:
		push_error("LoginController 创建 LoginNode 失败。")
		return
	_login_node.game_login_mgr = _game_login_mgr
	if not _login_node.login_flow_completed.is_connected(_on_login_flow_completed):
		_login_node.login_flow_completed.connect(_on_login_flow_completed)
	if not _login_node.login_flow_failed.is_connected(_on_login_flow_failed):
		_login_node.login_flow_failed.connect(_on_login_flow_failed)


func _bind_game_login_mgr_signals() -> void:
	if not _game_login_mgr.login_state_changed.is_connected(_on_login_state_changed):
		_game_login_mgr.login_state_changed.connect(_on_login_state_changed)
	if not _game_login_mgr.login_failed.is_connected(_on_login_failed):
		_game_login_mgr.login_failed.connect(_on_login_failed)
	if not _game_login_mgr.server_list_ready.is_connected(_on_server_list_ready):
		_game_login_mgr.server_list_ready.connect(_on_server_list_ready)
	_ensure_login_node()


func _on_login_state_changed(state: StringName, message: String) -> void:
	login_state_changed.emit(state, message)


func _on_login_failed(error_payload: Dictionary) -> void:
	login_failed.emit(error_payload)


func _on_server_list_ready() -> void:
	server_list_ready.emit()


func _on_login_flow_completed(init_payload: Dictionary) -> void:
	_game_login_mgr.mark_login_flow_completed()
	ControllerManager.notify_game_server_login(func() -> void:
		login_flow_completed.emit(init_payload)
	)


func _on_login_flow_failed(error_payload: Dictionary) -> void:
	login_flow_failed.emit(error_payload)
