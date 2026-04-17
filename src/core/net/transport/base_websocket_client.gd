class_name BaseWebSocketClient
extends Node


signal opened
signal text_message_received(message: String)
signal binary_message_received(data: PackedByteArray)
signal errored(reason: String)
signal closed(code: int, reason: String)
signal connection_attempt_started(url: String)
signal connection_attempt_failed(reason: String)


var _transport_socket: Object
var _url: String = ""
var _signals_bound: bool = false


func _ready() -> void:
	_log_debug("_ready begin")
	_ensure_transport_socket()


func open_websocket(url: String) -> Error:
	_log_debug("open_websocket url=%s" % url)
	close_websocket()
	if url.is_empty():
		push_warning("[BaseWebSocketClient] open_websocket failed: url is empty")
		errored.emit("url_is_empty")
		return ERR_INVALID_PARAMETER

	_url = url
	if not _ensure_transport_socket():
		push_error("[BaseWebSocketClient] open_websocket failed: NetSocket autoload unavailable.")
		errored.emit("transport_socket_unavailable")
		connection_attempt_failed.emit("transport_socket_unavailable")
		return ERR_UNAVAILABLE

	if _transport_socket != null and _transport_socket.has_method("ConnectWebSocket"):
		connection_attempt_started.emit(url)
		var connect_error: Error = _transport_socket.call("ConnectWebSocket", url)
		_log_debug("ConnectWebSocket returned error=%s" % int(connect_error))
		if connect_error != OK:
			push_warning("[BaseWebSocketClient] ConnectWebSocket start failed, error=%s" % int(connect_error))
			connection_attempt_failed.emit("connect_start_failed:%s" % int(connect_error))
		return connect_error

	push_error("[BaseWebSocketClient] transport_socket_unavailable. _transport_socket=%s has ConnectWebSocket=%s" % [
		str(_transport_socket),
		str(_transport_socket != null and _transport_socket.has_method("ConnectWebSocket"))
	])
	errored.emit("transport_socket_unavailable")
	connection_attempt_failed.emit("transport_socket_unavailable")
	return ERR_UNAVAILABLE


func close_websocket() -> void:
	if not _ensure_transport_socket():
		return
	if _transport_socket != null and _transport_socket.has_method("Close"):
		_transport_socket.call("Close")
		_log_debug("Close called")


func is_socket_connected() -> bool:
	if not _ensure_transport_socket():
		return false
	if _transport_socket != null:
		return bool(_transport_socket.get("IsConnected"))
	return false


func send_text(content: String) -> bool:
	if not _ensure_transport_socket():
		return false
	if _transport_socket != null and _transport_socket.has_method("SendText"):
		return bool(_transport_socket.call("SendText", content))
	return false


func send_binary(content: PackedByteArray) -> bool:
	if not _ensure_transport_socket():
		return false
	if _transport_socket != null and _transport_socket.has_method("SendBinary"):
		return bool(_transport_socket.call("SendBinary", content))
	return false


func _on_transport_opened() -> void:
	_log_debug("signal Opened")
	opened.emit()


func _on_transport_closed(code: int, reason: String) -> void:
	_log_debug("signal Closed code=%s reason=%s" % [code, reason])
	closed.emit(code, reason)


func _on_transport_errored(reason: String) -> void:
	push_warning("[BaseWebSocketClient] signal Errored reason=%s" % reason)
	errored.emit(reason)


func _on_transport_text_received(message: String) -> void:
	_log_debug("signal TextMessageReceived len=%s" % message.length())
	text_message_received.emit(message)


func _log_debug(message: String) -> void:
	print("[BaseWebSocketClient] %s" % message)


func _ensure_transport_socket() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false

	if _transport_socket == null:
		_transport_socket = tree.root.get_node_or_null("NetSocket")
		_log_debug("resolve NetSocket autoload: %s" % str(_transport_socket))
		if _transport_socket == null:
			return false

	if _transport_socket.has_method("ConfigureTransport"):
		_transport_socket.call("ConfigureTransport", true, false)
	else:
		push_error("[BaseWebSocketClient] NetSocket missing ConfigureTransport method.")
		return false

	if _signals_bound:
		return true

	if _transport_socket.has_signal("Opened"):
		_transport_socket.connect("Opened", Callable(self, "_on_transport_opened"))
		_transport_socket.connect("Closed", Callable(self, "_on_transport_closed"))
		_transport_socket.connect("Errored", Callable(self, "_on_transport_errored"))
		_transport_socket.connect("TextMessageReceived", Callable(self, "_on_transport_text_received"))
		_signals_bound = true
		_log_debug("transport socket signals connected")
		return true

	push_error("[BaseWebSocketClient] NetSocket signals missing: Opened/Closed/Errored/TextMessageReceived")
	return false
