extends Node

signal Opened
signal Closed(code: int, reason: String)
signal Errored(reason: String)
signal TextMessageReceived(message: String)

const DEFAULT_CLOSE_CODE: int = 1000

var IsConnected: bool:
	get:
		return _peer.get_ready_state() == WebSocketPeer.STATE_OPEN

var _peer: WebSocketPeer = WebSocketPeer.new()
var _is_websocket: bool = false
var _is_kcp: bool = false
var _is_connecting: bool = false
var _last_state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED

var _state_cb: Callable = Callable()
var _receive_cb: Callable = Callable()
var _send_data: TcpSendData = TcpSendData.new()


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if not _is_websocket:
		return
	_poll_websocket()


func ConfigureTransport(is_websocket: bool, is_kcp: bool) -> void:
	_is_websocket = is_websocket
	_is_kcp = is_kcp


func Connect(
	ip: String,
	_port: int,
	state_call_back: Callable,
	receive_call_back: Callable,
	_connect_timeout: int = 5000
) -> void:
	_state_cb = state_call_back
	_receive_cb = receive_call_back

	if _is_kcp:
		_emit_transport_error("kcp_not_supported")
		return
	if not _is_websocket:
		_emit_transport_error("tcp_not_supported")
		return

	var connect_error: Error = ConnectWebSocket(ip)
	if connect_error != OK:
		_emit_transport_error("connect_failed:%s" % int(connect_error))


func ConnectWebSocket(url: String) -> Error:
	if not _is_websocket:
		return ERR_UNAVAILABLE
	if url.is_empty():
		return ERR_INVALID_PARAMETER
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		return ERR_INVALID_PARAMETER

	Close()
	_peer = WebSocketPeer.new()
	var connect_error: Error = _peer.connect_to_url(url)
	if connect_error != OK:
		return connect_error

	_is_connecting = true
	_last_state = _peer.get_ready_state()
	return OK


func ConnectAsync(url: String) -> Dictionary:
	var connect_error: Error = ConnectWebSocket(url)
	if connect_error == OK:
		return {"ok": true, "error": ""}
	return {"ok": false, "error": str(connect_error)}


func Close() -> void:
	if _peer.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_peer.close()
	_is_connecting = false
	_last_state = WebSocketPeer.STATE_CLOSED


func SendText(text: String) -> bool:
	if not IsConnected:
		return false
	return _peer.send_text(text) == OK


func SendBinary(data: PackedByteArray) -> bool:
	if not IsConnected:
		return false
	return _peer.send(data) == OK


func SendMsg(
	request_id: int,
	msg_id: int,
	data: PackedByteArray,
	logic_id: String = "",
	extend_data: PackedByteArray = PackedByteArray()
) -> void:
	var logic_bytes: PackedByteArray = PackedByteArray()
	if not logic_id.is_empty():
		logic_bytes = logic_id.to_ascii_buffer()
	_send_data.Build(request_id, msg_id, logic_bytes, extend_data, data)
	var packet: PackedByteArray = _send_data.GetBytes()
	if _is_websocket:
		SendBinary(packet)


func SendTextAsync(text: String) -> Dictionary:
	var success: bool = SendText(text)
	return {"ok": success, "error": "" if success else "socket_not_connected"}


func DisconnectAsync() -> void:
	Close()


func UpdateNetwork() -> void:
	if _is_websocket:
		_poll_websocket()


func _poll_websocket() -> void:
	_peer.poll()

	var current_state: WebSocketPeer.State = _peer.get_ready_state()
	_handle_state_transition(current_state)

	if current_state != WebSocketPeer.STATE_OPEN:
		return

	while _peer.get_available_packet_count() > 0:
		var packet: PackedByteArray = _peer.get_packet()
		if _peer.was_string_packet():
			var text_message: String = packet.get_string_from_utf8()
			TextMessageReceived.emit(text_message)
			continue
		if _receive_cb.is_valid():
			_receive_cb.call(0, 0, packet)


func _handle_state_transition(current_state: WebSocketPeer.State) -> void:
	if current_state == _last_state:
		return

	if current_state == WebSocketPeer.STATE_OPEN:
		_is_connecting = false
		Opened.emit()
		if _state_cb.is_valid():
			_state_cb.call(0, "connected")
	elif current_state == WebSocketPeer.STATE_CLOSED:
		var close_code: int = _peer.get_close_code()
		if close_code == -1:
			close_code = DEFAULT_CLOSE_CODE
		var close_reason: String = _peer.get_close_reason()

		if _is_connecting:
			_is_connecting = false
			var reason: String = "connect_closed:%s:%s" % [close_code, close_reason]
			Errored.emit(reason)
			if _state_cb.is_valid():
				_state_cb.call(3, reason)

		Closed.emit(close_code, close_reason)
		if _state_cb.is_valid():
			_state_cb.call(1, close_reason)

	_last_state = current_state


func _emit_transport_error(reason: String) -> void:
	Errored.emit(reason)
	if _state_cb.is_valid():
		_state_cb.call(3, reason)
