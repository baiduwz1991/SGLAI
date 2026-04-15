class_name LoginController
extends NetworkedController

const CONTROLLER_ID: StringName = &"login_controller"

signal state_changed(status: StringName, message: String)
signal login_succeeded(token: String)

var _model: LoginModel = LoginModel.new()


func _init() -> void:
	super._init()
	register_socket_signal(_socket_client.connected, _on_socket_connected)
	register_socket_signal(_socket_client.transport_error, _on_transport_error)
	register_socket_signal(_socket_client.connection_closed, _on_socket_connection_closed)
	register_protocol_handler(&"login_result", _on_login_result_message)


func get_id() -> StringName:
	return CONTROLLER_ID


func get_model() -> LoginModel:
	return _model


func on_logout() -> void:
	_model.reset()
	state_changed.emit(_model.get_status(), "已重置登录状态")


func request_connect(server_url: String = "mock://gateway") -> void:
	_model.set_status(LoginModel.STATUS_CONNECTING)
	_model.set_last_error("")
	state_changed.emit(_model.get_status(), "正在连接登录服务器...")
	_socket_client.connect_server(server_url)


func request_login(account: String, password: String) -> void:
	if not _socket_client.is_transport_connected():
		_model.set_status(LoginModel.STATUS_ERROR)
		_model.set_last_error("尚未连接服务器")
		state_changed.emit(_model.get_status(), _model.get_last_error())
		return

	_model.set_account(account)
	_model.set_status(LoginModel.STATUS_LOGGING_IN)
	_model.set_last_error("")
	state_changed.emit(_model.get_status(), "登录请求发送中...")
	_socket_client.send_json({
		"cmd": "login",
		"account": account,
		"password": password
	})


func request_disconnect() -> void:
	_socket_client.disconnect_server()


func _on_socket_connected() -> void:
	_model.set_status(LoginModel.STATUS_CONNECTED)
	state_changed.emit(_model.get_status(), "连接成功，请输入账号密码登录")


func _on_login_result_message(message: Dictionary) -> void:
	var success: bool = bool(message.get("success", false))
	var token: String = str(message.get("token", ""))
	var error_message: String = str(message.get("error_message", ""))

	if success:
		_model.set_status(LoginModel.STATUS_LOGGED_IN)
		_model.set_token(token)
		state_changed.emit(_model.get_status(), "登录成功")
		login_succeeded.emit(token)
		return

	_model.set_status(LoginModel.STATUS_ERROR)
	_model.set_token("")
	_model.set_last_error(error_message)
	state_changed.emit(_model.get_status(), error_message)


func _on_transport_error(error_message: String) -> void:
	_model.set_status(LoginModel.STATUS_ERROR)
	_model.set_last_error(error_message)
	state_changed.emit(_model.get_status(), error_message)


func _on_socket_connection_closed() -> void:
	_model.set_status(LoginModel.STATUS_IDLE)
	_model.set_token("")
	state_changed.emit(_model.get_status(), "连接已断开")
