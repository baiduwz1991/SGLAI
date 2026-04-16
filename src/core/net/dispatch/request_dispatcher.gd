class_name RequestDispatcher
extends RefCounted


var _request_callbacks: Dictionary = {}
var _push_handlers: Dictionary = {}


func register_request(
	request_id: int,
	response_command: StringName,
	ok_callback: Callable,
	fail_callback: Callable,
	timeout_seconds: float = 10.0
) -> void:
	_request_callbacks[request_id] = {
		"response_command": response_command,
		"ok_callback": ok_callback,
		"fail_callback": fail_callback,
		"timeout_left": timeout_seconds
	}


func add_push_handler(command: StringName, handler: Callable) -> void:
	if not handler.is_valid():
		return
	var handlers: Array[Callable] = _push_handlers.get(command, [])
	if handlers.has(handler):
		return
	handlers.append(handler)
	_push_handlers[command] = handlers


func remove_push_handler(command: StringName, handler: Callable) -> void:
	if not _push_handlers.has(command):
		return
	var handlers: Array[Callable] = _push_handlers[command]
	handlers.erase(handler)
	if handlers.is_empty():
		_push_handlers.erase(command)
		return
	_push_handlers[command] = handlers


func clear() -> void:
	_request_callbacks.clear()
	_push_handlers.clear()


func fail_all(reason: String) -> void:
	for request_id_variant in _request_callbacks.keys():
		var request_id: int = int(request_id_variant)
		var request_info: Dictionary = _request_callbacks.get(request_id, {})
		var fail_callback: Callable = request_info.get("fail_callback", Callable())
		if fail_callback.is_valid():
			fail_callback.call({
				"success": false,
				"request_id": request_id,
				"reason": reason
			})
	_request_callbacks.clear()


func advance_time(delta: float) -> void:
	if _request_callbacks.is_empty():
		return

	var timeout_ids: Array[int] = []
	for request_id_variant in _request_callbacks.keys():
		var request_id: int = int(request_id_variant)
		var request_info: Dictionary = _request_callbacks.get(request_id, {})
		var timeout_left: float = float(request_info.get("timeout_left", 0.0)) - delta
		request_info["timeout_left"] = timeout_left
		_request_callbacks[request_id] = request_info
		if timeout_left <= 0.0:
			timeout_ids.append(request_id)

	for timeout_id in timeout_ids:
		var timeout_info: Dictionary = _request_callbacks.get(timeout_id, {})
		_request_callbacks.erase(timeout_id)
		var timeout_fail: Callable = timeout_info.get("fail_callback", Callable())
		if timeout_fail.is_valid():
			timeout_fail.call({
				"success": false,
				"request_id": timeout_id,
				"reason": "request_timeout"
			})


func dispatch(packet: Dictionary) -> void:
	var request_id: int = int(packet.get("request_id", 0))
	if request_id > 0 and _request_callbacks.has(request_id):
		var request_info: Dictionary = _request_callbacks[request_id]
		_request_callbacks.erase(request_id)
		var expected_command: StringName = request_info.get("response_command", StringName())
		var response_command: StringName = StringName(packet.get("command", ""))
		if expected_command != StringName() and response_command != expected_command:
			var mismatch_fail: Callable = request_info.get("fail_callback", Callable())
			if mismatch_fail.is_valid():
				mismatch_fail.call({
					"success": false,
					"request_id": request_id,
					"reason": "response_command_mismatch",
					"expected_command": str(expected_command),
					"actual_command": str(response_command)
				})
			return

		var is_success: bool = bool(packet.get("success", true))
		if is_success:
			var ok_callback: Callable = request_info.get("ok_callback", Callable())
			if ok_callback.is_valid():
				ok_callback.call(packet.get("data", packet))
		else:
			var fail_callback: Callable = request_info.get("fail_callback", Callable())
			if fail_callback.is_valid():
				fail_callback.call(packet)
		return

	var command: StringName = StringName(packet.get("command", ""))
	if command == StringName():
		return
	if not _push_handlers.has(command):
		return

	var handlers: Array[Callable] = _push_handlers[command]
	for handler in handlers:
		if handler.is_valid():
			handler.call(packet.get("data", packet))
