class_name ClientConn
extends RefCounted

const ESocketState_Connecting: int = 0
const ESocketState_Connected: int = 1
const ESocketState_Closed: int = 2

const ESocketError_SendRecieveError: int = -1
const ESocketError_Unknown: int = -2
const ESocketError_ConnectError: int = -3
const ESocketError_ConnectOutOfDate: int = -4
const ESocketError_ClosedSocket: int = -5

var onStateChanged: Callable = Callable()
var onReceivedMsg: Callable = Callable()

var _host: String = ""
var _port: int = 0
var _connect_timeout_seconds: float = 5.0
var _connect_started_ms: int = 0
var _state: int = ESocketState_Closed
var _socket: StreamPeerTCP = StreamPeerTCP.new()


func IsConnected() -> bool:
	return _state == ESocketState_Connected and _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED


func SetHostPort(host: String, port: int) -> void:
	_host = host
	_port = port


func SetConnectTimeLimit(seconds: float) -> void:
	if seconds > 0.0:
		_connect_timeout_seconds = seconds


func Connect() -> void:
	Close()
	if _host.is_empty() or _port <= 0:
		_report_socket_state(ESocketError_ConnectError, "invalid_host_or_port")
		return
	var connect_error: Error = _socket.connect_to_host(_host, _port)
	if connect_error != OK:
		_report_socket_state(ESocketError_ConnectError, str(connect_error))
		return
	_state = ESocketState_Connecting
	_connect_started_ms = Time.get_ticks_msec()


func SendMessage(message: PackedByteArray) -> void:
	if not IsConnected():
		return
	var send_error: Error = _socket.put_data(message)
	if send_error != OK:
		_report_socket_state(ESocketError_SendRecieveError, "send_failed:%s" % int(send_error))
		Close()


func UpdateNetwork() -> void:
	_update_socket_state()
	_update_packet()


func Close() -> void:
	if _socket.get_status() != StreamPeerTCP.STATUS_NONE:
		_socket.disconnect_from_host()
	_state = ESocketState_Closed


func Dispose() -> void:
	Close()
	onStateChanged = Callable()
	onReceivedMsg = Callable()


func _update_socket_state() -> void:
	match _socket.get_status():
		StreamPeerTCP.STATUS_CONNECTED:
			if _state != ESocketState_Connected:
				_state = ESocketState_Connected
				_report_socket_state(0, "connected")
		StreamPeerTCP.STATUS_CONNECTING:
			if _state == ESocketState_Connecting:
				var elapsed_seconds: float = float(Time.get_ticks_msec() - _connect_started_ms) / 1000.0
				if elapsed_seconds >= _connect_timeout_seconds:
					_report_socket_state(ESocketError_ConnectOutOfDate, "connection_timeout")
					Close()
		StreamPeerTCP.STATUS_ERROR:
			_report_socket_state(ESocketError_ConnectError, "socket_error")
			Close()
		StreamPeerTCP.STATUS_NONE:
			if _state == ESocketState_Connected:
				_report_socket_state(ESocketError_ClosedSocket, "closed")
			_state = ESocketState_Closed


func _update_packet() -> void:
	if not IsConnected():
		return
	var available: int = _socket.get_available_bytes()
	if available <= 0:
		return
	var received: Array = _socket.get_data(available)
	if received.size() != 2:
		return
	var get_error: int = int(received[0])
	if get_error != OK:
		_report_socket_state(ESocketError_SendRecieveError, "receive_failed:%s" % get_error)
		Close()
		return
	var payload: PackedByteArray = received[1] as PackedByteArray
	if onReceivedMsg.is_valid():
		onReceivedMsg.call(payload)


func _report_socket_state(code: int, message: String) -> void:
	if onStateChanged.is_valid():
		onStateChanged.call(code, message)
