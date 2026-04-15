class_name ProtocolRouter
extends RefCounted

var _handlers: Dictionary[StringName, Array] = {}


func register_handler(command: StringName, handler: Callable) -> void:
	if not handler.is_valid():
		push_error("ProtocolRouter 注册失败：无效的回调。")
		return

	if not _handlers.has(command):
		_handlers[command] = []

	var handlers: Array = _handlers[command]
	if handlers.has(handler):
		return

	handlers.append(handler)
	_handlers[command] = handlers


func unregister_handler(command: StringName, handler: Callable) -> void:
	if not _handlers.has(command):
		return

	var handlers: Array = _handlers[command]
	handlers.erase(handler)
	if handlers.is_empty():
		_handlers.erase(command)
		return

	_handlers[command] = handlers


func dispatch(message: Dictionary) -> void:
	var command: StringName = StringName(str(message.get("cmd", "")))
	if command == StringName():
		return

	if not _handlers.has(command):
		return

	var handlers: Array = _handlers[command]
	for handler_variant in handlers:
		var handler: Callable = handler_variant as Callable
		if not handler.is_valid():
			continue
		handler.call(message)
