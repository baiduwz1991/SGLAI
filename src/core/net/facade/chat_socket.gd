class_name ChatSocketFacade
extends Node


const BaseWebSocketClientScript: Script = preload("res://src/core/net/transport/base_websocket_client.gd")

signal socket_opened
signal socket_closed
signal message_received(payload: Dictionary)

var _socket: BaseWebSocketClient
var _callback_map: Dictionary = {}


func _ready() -> void:
	_socket = BaseWebSocketClientScript.new()
	add_child(_socket)
	_socket.opened.connect(_on_opened)
	_socket.closed.connect(_on_closed)
	_socket.text_message_received.connect(_on_message)


func open_socket(url: String) -> Error:
	return _socket.open_websocket(url)


func close_socket() -> void:
	_socket.close_websocket()


func is_socket_connected() -> bool:
	return _socket.is_socket_connected()


func send(method: String, data: Array = []) -> bool:
	if not is_socket_connected():
		return false
	var payload: Dictionary = {
		"MethodName": method,
		"Parameters": data
	}
	return _socket.send_text(JSON.stringify(payload))


func send_message(params: Dictionary) -> bool:
	_callback_map["sendMessage"] = params
	return send(
		"sendMessage",
		[
			params.get("channel", ""),
			params.get("text", ""),
			params.get("voice", ""),
			params.get("target", ""),
			params.get("name", "")
		]
	)


func get_history(params: Dictionary) -> bool:
	_callback_map["getHistory"] = params
	return send(
		"getHistory",
		[
			params.get("channel", ""),
			int(params.get("startIndex", 0)),
			int(params.get("count", 20)),
			params.get("target", "")
		]
	)


func _on_opened() -> void:
	socket_opened.emit()


func _on_closed(_code: int, _reason: String) -> void:
	socket_closed.emit()


func _on_message(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		message_received.emit(parsed as Dictionary)
