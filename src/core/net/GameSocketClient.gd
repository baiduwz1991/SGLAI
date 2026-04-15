class_name GameSocketClient
extends INetworkClient

var _connected: bool = false
var _server_url: String = ""


func connect_server(server_url: String = "mock://local") -> void:
	_server_url = server_url
	call_deferred("_emit_connected")


func disconnect_server() -> void:
	call_deferred("_emit_connection_closed")


func is_transport_connected() -> bool:
	return _connected


func send_json(payload: Dictionary) -> bool:
	if not _connected:
		transport_error.emit("网络未连接，消息发送失败")
		return false

	call_deferred("_emit_mock_server_message", payload)
	return true


func _emit_connected() -> void:
	_connected = true
	connected.emit()


func _emit_connection_closed() -> void:
	_connected = false
	connection_closed.emit()


func _emit_mock_server_message(payload: Dictionary) -> void:
	var command_variant: Variant = payload.get("cmd", "")
	var command: String = str(command_variant)

	if command == "login":
		var account: String = str(payload.get("account", "")).strip_edges()
		var password: String = str(payload.get("password", "")).strip_edges()
		if account.is_empty() or password.is_empty():
			message_received.emit({
				"cmd": "login_result",
				"success": false,
				"token": "",
				"error_message": "账号或密码不能为空"
			})
			return

		message_received.emit({
			"cmd": "login_result",
			"success": true,
			"token": "mock_token_%s" % account,
			"error_message": ""
		})
		return

	message_received.emit({
		"cmd": "unknown",
		"success": false,
		"token": "",
		"error_message": "未识别的指令：%s" % command
	})
