class_name NetWebSocket
extends RefCounted

const NetWebSocketHandle_OPEN: int = 0
const NetWebSocketHandle_MESSAGE: int = 1
const NetWebSocketHandle_ERROE: int = 2
const NetWebSocketHandle_CLOSED: int = 3

const NetCompressType_NONE: int = 0
const NetCompressType_ZIP: int = 1
const NetCompressType_LZ4: int = 2

var _peer: WebSocketPeer = WebSocketPeer.new()
var _recieve_data: WebSocketRecieveData = WebSocketRecieveData.new()

var _on_open: Callable = Callable()
var _on_message: Callable = Callable()
var _on_error: Callable = Callable()
var _on_closed: Callable = Callable()

var _pending_connected: bool = false


func IsConnected() -> bool:
	return _peer.get_ready_state() == WebSocketPeer.STATE_OPEN


func RegisterHandler(handle: int, callback: Callable) -> void:
	match handle:
		NetWebSocketHandle_OPEN:
			_on_open = callback
		NetWebSocketHandle_MESSAGE:
			_on_message = callback
		NetWebSocketHandle_ERROE:
			_on_error = callback
		NetWebSocketHandle_CLOSED:
			_on_closed = callback


func Connect(url: String) -> bool:
	if url.is_empty():
		return false
	var connect_error: Error = ConnectWebSocket(url)
	return connect_error == OK


func ConnectAsync(url: String) -> Dictionary:
	var connect_error: Error = ConnectWebSocket(url)
	if connect_error == OK:
		return {"ok": true, "error": ""}
	return {"ok": false, "error": str(connect_error)}


func ConnectWebSocket(url: String) -> Error:
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		return ERR_INVALID_PARAMETER
	_peer = WebSocketPeer.new()
	var connect_error: Error = _peer.connect_to_url(url)
	if connect_error == OK:
		_pending_connected = true
	return connect_error


func Send(data: Variant) -> bool:
	if not IsConnected():
		return false
	if data is PackedByteArray:
		return _peer.send(data) == OK
	if data is String:
		return _peer.send_text(data) == OK
	return false


func SendAsync(data: Variant) -> Dictionary:
	var success: bool = Send(data)
	return {"ok": success, "error": "" if success else "socket_not_connected"}


func ReceiveAsync() -> Dictionary:
	_poll()
	if not IsConnected():
		return {"ok": false, "error": "socket_not_connected"}
	return {"ok": true, "error": ""}


func Close() -> void:
	_peer.close()
	if _on_closed.is_valid():
		_on_closed.call("closed")


func DisconnectAsync() -> void:
	Close()


func Poll() -> void:
	_poll()


func _poll() -> void:
	_peer.poll()
	var state: WebSocketPeer.State = _peer.get_ready_state()
	if _pending_connected and state == WebSocketPeer.STATE_OPEN:
		_pending_connected = false
		if _on_open.is_valid():
			_on_open.call("opened")
	if state == WebSocketPeer.STATE_CLOSED and _pending_connected:
		_pending_connected = false
		if _on_error.is_valid():
			_on_error.call("connect_failed")

	if state != WebSocketPeer.STATE_OPEN:
		return

	while _peer.get_available_packet_count() > 0:
		var packet: PackedByteArray = _peer.get_packet()
		if _peer.was_string_packet():
			if _on_message.is_valid():
				_on_message.call(packet.get_string_from_utf8())
			continue
		if _recieve_data.Read(packet):
			var message: String = _recieve_data.BytesData.get_string_from_utf8()
			if _on_message.is_valid():
				_on_message.call(message)
		elif _on_message.is_valid():
			_on_message.call(Marshalls.raw_to_base64(packet))
