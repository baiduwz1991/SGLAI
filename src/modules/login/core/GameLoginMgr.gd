class_name GameLoginMgr
extends RefCounted

const LoginFlowStateScript: Script = preload("res://src/modules/login/core/LoginFlowState.gd")
const ServerListMapperScript: Script = preload("res://src/core/net/facade/server_list_mapper.gd")
const ServerListRequestBuilderScript: Script = preload("res://src/modules/login/core/ServerListRequestBuilder.gd")
const ServerSelectionServiceScript: Script = preload("res://src/modules/login/core/ServerSelectionService.gd")

## 登录状态变化通知（用于面板刷新提示文案）。
signal login_state_changed(state: StringName, message: String)
## 平台登录后服表拉取完成通知。
signal server_list_ready
## 平台登录失败通知。
signal login_failed(error_payload: Dictionary)

var _state: StringName = LoginFlowStateScript.IDLE
var _platform_bound: bool = false

var _server_map: Dictionary = {}
var _history_servers: Array[Dictionary] = []
var _recommend_servers: Array[Dictionary] = []
var _allow_register: bool = false
var _current_server: Dictionary = {}

var _login_payload: Dictionary = {}
var _rand_num: int = 0
var _server_user_id: String = ""
var _server_list_mapper: ServerListMapper = ServerListMapperScript.new()
var _server_list_request_builder: ServerListRequestBuilder = ServerListRequestBuilderScript.new()
var _server_selection_service: ServerSelectionService = ServerSelectionServiceScript.new()


func init() -> void:
	if _platform_bound:
		return
	var platform: Node = _get_platform()
	if platform == null:
		push_warning("GameLoginMgr.init 未找到 Platform autoload。")
		return
	_platform_bound = true
	platform.login_completed.connect(_on_platform_login_completed)
	platform.login_failed.connect(_on_platform_login_failed)


## 对齐 Lua 的 RefreshView -> Clear()。
func clear() -> void:
	_state = LoginFlowStateScript.IDLE
	_server_map.clear()
	_history_servers.clear()
	_recommend_servers.clear()
	_allow_register = false
	_current_server = {}
	_login_payload = {}
	_server_user_id = ""
	if _rand_num <= 0:
		_rand_num = randi_range(1, 100000000)
	login_state_changed.emit(_state, "登录状态已重置")


## 对齐 Lua 的 RequestLogin()：触发平台登录（账号服/SDK）。
func request_login(username: String, password: String) -> void:
	if not _platform_bound:
		init()
	var platform: Node = _get_platform()
	if platform == null:
		_state = LoginFlowStateScript.ERROR
		login_state_changed.emit(_state, "平台模块未初始化")
		login_failed.emit({"reason": "Platform autoload 缺失"})
		return
	_state = LoginFlowStateScript.LOGGING_IN
	login_state_changed.emit(_state, "正在请求平台登录...")
	platform.call("login", username, password)


func request_register(username: String, password: String) -> void:
	if not _platform_bound:
		init()
	var platform: Node = _get_platform()
	if platform == null:
		_state = LoginFlowStateScript.ERROR
		login_state_changed.emit(_state, "平台模块未初始化")
		login_failed.emit({"reason": "Platform autoload 缺失"})
		return
	_state = LoginFlowStateScript.LOGGING_IN
	login_state_changed.emit(_state, "正在请求账号注册...")
	platform.call("register_account", username, password)


## 对齐 Lua：平台登录回调后拉服表。
func request_server_list() -> void:
	var platform: Node = _get_platform()
	if platform == null:
		_state = LoginFlowStateScript.ERROR
		login_state_changed.emit(_state, "平台模块未初始化")
		login_failed.emit({"reason": "Platform autoload 缺失"})
		return
	var request_data: Dictionary = _build_server_list_request_data(platform)
	_state = LoginFlowStateScript.LOADING_SERVER_LIST
	login_state_changed.emit(_state, "正在拉取服务器列表...")
	platform.call("request_server_list", request_data, _on_server_list_response)
	print("[GameLoginMgr] 服务器列表请求参数: %s" % JSON.stringify(request_data))


func mark_login_flow_completed() -> void:
	_state = LoginFlowStateScript.FLOW_COMPLETED
	login_state_changed.emit(_state, "登录主流程完成")


func get_current_server() -> Dictionary:
	return _current_server.duplicate(true)


func get_server_map() -> Dictionary:
	return _server_map.duplicate(true)


func get_server_list() -> Array[Dictionary]:
	var server_list: Array[Dictionary] = []
	for server in _server_map.values():
		server_list.append((server as Dictionary).duplicate(true))
	return server_list


func get_history_servers() -> Array[Dictionary]:
	return _history_servers.duplicate(true)


func get_recommend_servers() -> Array[Dictionary]:
	return _recommend_servers.duplicate(true)


func get_allow_register() -> bool:
	return _allow_register


func get_login_payload() -> Dictionary:
	return _login_payload.duplicate(true)


func set_current_server_by_id(server_id: String) -> bool:
	if not _server_map.has(server_id):
		return false
	_current_server = (_server_map[server_id] as Dictionary).duplicate(true)
	return true


func set_current_server(server_data: Dictionary) -> void:
	_current_server = server_data.duplicate(true)


func _on_platform_login_completed(payload: Dictionary) -> void:
	_login_payload = payload.duplicate(true)
	request_server_list()


func _on_platform_login_failed(error_payload: Dictionary) -> void:
	_state = LoginFlowStateScript.ERROR
	var reason: String = str(error_payload.get("reason", "unknown"))
	var state: int = int(error_payload.get("state", 0))
	var message: String = str(error_payload.get("message", ""))
	login_state_changed.emit(_state, "平台登录失败(reason=%s state=%d message=%s)" % [reason, state, message])
	login_failed.emit(error_payload)


func _on_server_list_response(response: Dictionary) -> void:
	print("[GameLoginMgr] 服务器列表响应摘要: %s" % JSON.stringify(_build_response_summary(response)))
	var returned_user_id: String = _server_list_mapper.extract_returned_user_id(response)
	if not returned_user_id.is_empty():
		_server_user_id = returned_user_id
	var code: int = int(response.get("Code", -1))
	var is_business_success: bool = code == 0
	if not bool(response.get("success", false)) or not is_business_success:
		_state = LoginFlowStateScript.ERROR
		var message: String = str(response.get("Message", response.get("business_message", "UnknownError")))
		login_state_changed.emit(_state, "服务器列表请求失败(Code=%d, Message=%s)" % [code, message])
		login_failed.emit(response)
		return

	_build_server_data(response)
	if _state == LoginFlowStateScript.ERROR:
		return
	print("[GameLoginMgr] 服务器数量统计: total=%d recommend=%d history=%d" % [_server_map.size(), _recommend_servers.size(), _history_servers.size()])
	print("[GameLoginMgr] 当前选中服务器摘要: %s" % JSON.stringify(_build_server_summary(_current_server)))
	_state = LoginFlowStateScript.SERVER_READY
	login_state_changed.emit(_state, "服务器列表已就绪")
	server_list_ready.emit()


## 服表结构兼容策略（强校验模式）：
## - 优先读取 response.Data.server_list / response.Data.ServerList
## - 其次读取 response.result.server_list / response.server_list
## - 若为空，直接判定为业务失败，不再兜底默认服
func _build_server_data(response: Dictionary) -> void:
	var selection_result: Dictionary = _server_selection_service.build_selection_result(response, _server_list_mapper)
	_allow_register = bool(selection_result.get("allow_register", true))
	if not bool(selection_result.get("ok", false)):
		_server_map.clear()
		_history_servers.clear()
		_recommend_servers.clear()
		_current_server = {}
		push_warning("GameLoginMgr 服务器列表为空，保持失败态等待后端返回可用服表。")
		push_warning("[GameLoginMgr] Data keys: %s" % str(selection_result.get("data_keys_summary", "[]")))
		_state = LoginFlowStateScript.ERROR
		login_state_changed.emit(_state, "服务器列表为空，请检查账号区服权限或后端返回。")
		login_failed.emit(response)
		return
	var server_map_variant: Variant = selection_result.get("server_map", {})
	if server_map_variant is Dictionary:
		_server_map = (server_map_variant as Dictionary).duplicate(true)
	else:
		_server_map = {}
	_history_servers = _to_dictionary_array(selection_result.get("history_servers", []))
	_recommend_servers = _to_dictionary_array(selection_result.get("recommend_servers", []))
	var current_server_variant: Variant = selection_result.get("current_server", {})
	if current_server_variant is Dictionary:
		_current_server = (current_server_variant as Dictionary).duplicate(true)
	else:
		_current_server = {}


func _get_platform() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("Platform")


func _build_server_list_request_data(platform: Node) -> Dictionary:
	# 对齐 Lua GameLoginMgr:RequestServerList 参数结构（字段名大小写保持一致）。
	if _rand_num <= 0:
		_rand_num = randi_range(1, 100000000)

	var request_bundle: Dictionary = _server_list_request_builder.build_request_bundle(
		platform,
		_login_payload,
		_server_user_id,
		_rand_num,
		TranslationServer.get_locale()
	)
	var debug_meta_variant: Variant = request_bundle.get("debug_meta", {})
	var debug_meta: Dictionary = debug_meta_variant as Dictionary
	print(
		"[GameLoginMgr] EncryptedString inputs: PartnerID=%s GameVersionID=%s RandNum=%s LoginKeyTail=%s EncryptedString=%s"
		% [
			str(debug_meta.get("PartnerID", "")),
			str(debug_meta.get("GameVersionID", "")),
			str(debug_meta.get("RandNum", 0)),
			str(debug_meta.get("LoginKeyTail", "")),
			str(debug_meta.get("EncryptedString", ""))
		]
	)
	var request_data_variant: Variant = request_bundle.get("request_data", {})
	if request_data_variant is Dictionary:
		return request_data_variant as Dictionary
	return {}


func _build_response_summary(response: Dictionary) -> Dictionary:
	return _server_list_mapper.build_response_summary(response)


func _build_server_summary(server: Dictionary) -> Dictionary:
	return _server_list_mapper.build_server_summary(server)


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not (value is Array):
		return result
	for item in value as Array:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result
