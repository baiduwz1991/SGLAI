class_name NetworkedController
extends BaseController

var _socket_client: INetworkClient
var _protocol_router: ProtocolRouter
var _protocol_bindings: Array[Dictionary] = []
var _socket_signal_bindings: Array[Dictionary] = []


func _init() -> void:
	_socket_client = NetworkClient.get_socket_client()
	_protocol_router = NetworkClient.get_protocol_router()


func register_protocol_handler(command: StringName, handler: Callable) -> void:
	if not handler.is_valid():
		push_error("NetworkedController 注册协议失败：无效回调。")
		return

	_protocol_router.register_handler(command, handler)
	if _has_protocol_binding(command, handler):
		return

	_protocol_bindings.append({
		"command": command,
		"handler": handler
	})


func register_socket_signal(signal_ref: Signal, handler: Callable) -> void:
	if not handler.is_valid():
		push_error("NetworkedController 注册信号失败：无效回调。")
		return

	if signal_ref.is_connected(handler):
		return

	signal_ref.connect(handler)
	if _has_socket_signal_binding(signal_ref, handler):
		return

	_socket_signal_bindings.append({
		"signal_ref": signal_ref,
		"handler": handler
	})


func unregister_socket_signal(signal_ref: Signal, handler: Callable) -> void:
	if signal_ref.is_connected(handler):
		signal_ref.disconnect(handler)

	var index: int = 0
	while index < _socket_signal_bindings.size():
		var binding: Dictionary = _socket_signal_bindings[index]
		var binding_signal: Signal = binding.get("signal_ref", Signal())
		var binding_handler: Callable = binding.get("handler", Callable())
		if binding_signal == signal_ref and binding_handler == handler:
			_socket_signal_bindings.remove_at(index)
			continue
		index += 1


func unregister_protocol_handler(command: StringName, handler: Callable) -> void:
	_protocol_router.unregister_handler(command, handler)
	var index: int = 0
	while index < _protocol_bindings.size():
		var binding: Dictionary = _protocol_bindings[index]
		var binding_command: StringName = binding.get("command", StringName())
		var binding_handler: Callable = binding.get("handler", Callable())
		if binding_command == command and binding_handler == handler:
			_protocol_bindings.remove_at(index)
			continue
		index += 1


func clear_protocol_handlers() -> void:
	if _protocol_router == null:
		_protocol_bindings.clear()
		return

	for binding in _protocol_bindings:
		var command: StringName = binding.get("command", StringName())
		var handler: Callable = binding.get("handler", Callable())
		_protocol_router.unregister_handler(command, handler)
	_protocol_bindings.clear()


func clear_socket_signals() -> void:
	for binding in _socket_signal_bindings:
		var signal_ref: Signal = binding.get("signal_ref", Signal())
		var handler: Callable = binding.get("handler", Callable())
		if signal_ref.is_null():
			continue
		if signal_ref.is_connected(handler):
			signal_ref.disconnect(handler)
	_socket_signal_bindings.clear()


func on_release() -> void:
	clear_socket_signals()
	clear_protocol_handlers()

func _has_protocol_binding(command: StringName, handler: Callable) -> bool:
	for binding in _protocol_bindings:
		var binding_command: StringName = binding.get("command", StringName())
		var binding_handler: Callable = binding.get("handler", Callable())
		if binding_command == command and binding_handler == handler:
			return true
	return false


func _has_socket_signal_binding(signal_ref: Signal, handler: Callable) -> bool:
	for binding in _socket_signal_bindings:
		var binding_signal: Signal = binding.get("signal_ref", Signal())
		var binding_handler: Callable = binding.get("handler", Callable())
		if binding_signal == signal_ref and binding_handler == handler:
			return true
	return false
