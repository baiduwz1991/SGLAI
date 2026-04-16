class_name BaseController
extends RefCounted

var _push_bindings: Array[Dictionary] = []


func get_id() -> StringName:
	_report_abstract_method("get_id")
	return &"base_controller"


func on_game_start() -> void:
	_report_abstract_method("on_game_start")


func on_login(back: Callable = Callable()) -> void:
	_report_abstract_method("on_login")
	_call_back(back)


func on_reconnection(back: Callable = Callable()) -> void:
	_report_abstract_method("on_reconnection")
	_call_back(back)


func get_login_dependencies() -> Array[StringName]:
	return []


func get_reconnection_dependencies() -> Array[StringName]:
	return get_login_dependencies()


func on_login_out() -> void:
	_report_abstract_method("on_login_out")


func on_release() -> void:
	clear_push_handlers()


func send_request(payload: Dictionary) -> bool:
	var net_manager: Node = _get_net_manager()
	if net_manager == null:
		push_error("BaseController 发送请求失败：NetManager 未就绪。")
		return false
	return bool(net_manager.call("send_msg", payload))


func send_request_with_response(
	payload: Dictionary,
	response_command: StringName,
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	var net_manager: Node = _get_net_manager()
	if net_manager == null:
		push_error("BaseController 发送请求失败：NetManager 未就绪。")
		return false
	return bool(net_manager.call("send_msg", payload, response_command, ok_back, fail_back))


func register_push_handler(command: StringName, handler: Callable) -> void:
	if not handler.is_valid():
		push_error("BaseController 注册 push 失败：无效回调。")
		return

	var net_manager: Node = _get_net_manager()
	if net_manager == null:
		push_error("BaseController 注册 push 失败：NetManager 未就绪。")
		return

	net_manager.call("add_push_by_command", command, handler)
	if _has_push_binding(command, handler):
		return

	_push_bindings.append({
		"command": command,
		"handler": handler
	})


func unregister_push_handler(command: StringName, handler: Callable) -> void:
	var net_manager: Node = _get_net_manager()
	if net_manager != null:
		net_manager.call("remove_push_by_command", command, handler)

	var index: int = 0
	while index < _push_bindings.size():
		var binding: Dictionary = _push_bindings[index]
		var binding_command: StringName = binding.get("command", StringName())
		var binding_handler: Callable = binding.get("handler", Callable())
		if binding_command == command and binding_handler == handler:
			_push_bindings.remove_at(index)
			continue
		index += 1


func clear_push_handlers() -> void:
	var net_manager: Node = _get_net_manager()
	for binding in _push_bindings:
		var command: StringName = binding.get("command", StringName())
		var handler: Callable = binding.get("handler", Callable())
		if net_manager != null:
			net_manager.call("remove_push_by_command", command, handler)
	_push_bindings.clear()


func _has_push_binding(command: StringName, handler: Callable) -> bool:
	for binding in _push_bindings:
		var binding_command: StringName = binding.get("command", StringName())
		var binding_handler: Callable = binding.get("handler", Callable())
		if binding_command == command and binding_handler == handler:
			return true
	return false


func _call_back(back: Callable) -> void:
	if back.is_valid():
		back.call()


func _report_abstract_method(method_name: String) -> void:
	push_error("BaseController 抽象方法未实现：%s" % method_name)


func _get_net_manager() -> Node:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null("NetManager")
