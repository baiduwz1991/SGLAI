class_name LoginModel
extends BaseModel

const STATUS_IDLE: StringName = &"idle"
const STATUS_CONNECTING: StringName = &"connecting"
const STATUS_CONNECTED: StringName = &"connected"
const STATUS_LOGGING_IN: StringName = &"logging_in"
const STATUS_LOGGED_IN: StringName = &"logged_in"
const STATUS_ERROR: StringName = &"error"

var _status: StringName = STATUS_IDLE
var _account: String = ""
var _token: String = ""
var _last_error: String = ""


func set_account(account: String) -> void:
	_account = account.strip_edges()


func set_status(status: StringName) -> void:
	_status = status


func set_token(token: String) -> void:
	_token = token


func set_last_error(message: String) -> void:
	_last_error = message


func get_status() -> StringName:
	return _status


func get_account() -> String:
	return _account


func get_token() -> String:
	return _token


func get_last_error() -> String:
	return _last_error


func reset() -> void:
	_status = STATUS_IDLE
	_account = ""
	_token = ""
	_last_error = ""
