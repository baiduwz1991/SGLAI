extends Node


var _push_handlers: Dictionary = {}


func add_push_by_command(command: StringName, handler: Callable) -> void:
	if not handler.is_valid():
		return
	var handlers: Array[Callable] = _push_handlers.get(command, [])
	if handlers.has(handler):
		return
	handlers.append(handler)
	_push_handlers[command] = handlers


func remove_push_by_command(command: StringName, handler: Callable) -> void:
	if not _push_handlers.has(command):
		return
	var handlers: Array[Callable] = _push_handlers[command]
	handlers.erase(handler)
	if handlers.is_empty():
		_push_handlers.erase(command)
		return
	_push_handlers[command] = handlers


func dispatch_push(command: StringName, payload: Dictionary) -> void:
	if not _push_handlers.has(command):
		return
	var handlers: Array[Callable] = _push_handlers[command]
	for handler in handlers:
		if handler.is_valid():
			handler.call(payload)
