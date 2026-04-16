extends Node


const HttpRequestServiceScript: Script = preload("res://src/core/net/facade/http_request_service.gd")
const PlatformNetAdapterScript: Script = preload("res://src/core/net/facade/platform_net_adapter.gd")
const AccountAuthServiceScript: Script = preload("res://src/core/net/facade/account_auth_service.gd")
const ServerListServiceScript: Script = preload("res://src/core/net/facade/server_list_service.gd")

const ACCOUNT_BASE_URL: String = "https://passport.7qule.com/sdk"
const ACCOUNT_APP_ID: String = "99"
const ACCOUNT_ENCODE_KEY: String = "537b9b7a-a18c-11ea-afae-6c92bf62e626"

signal login_completed(payload: Dictionary)
signal login_failed(error_payload: Dictionary)
signal init_completed

@export var partner_id: String = "1001"
@export var version: String = "100"
@export var login_key: String = "a0482eaf-14e8-4a65-950e-864214f62da5"
@export var resource_version_name: String = "dev"
@export var game_center_url: String = "https://loginservertest-lang-dsn.7qule.com/Api/ServerList_Client.ashx"

var _http_service: HttpRequestService
var _adapter: PlatformNetAdapter
var _account_auth_service: AccountAuthService
var _server_list_service: ServerListService


func _ready() -> void:
	_http_service = HttpRequestServiceScript.new()
	add_child(_http_service)
	_adapter = PlatformNetAdapterScript.new()
	_account_auth_service = AccountAuthServiceScript.new()
	_account_auth_service.configure(_http_service, ACCOUNT_BASE_URL, ACCOUNT_APP_ID, ACCOUNT_ENCODE_KEY)
	_server_list_service = ServerListServiceScript.new()
	_server_list_service.configure(_http_service, _adapter, game_center_url)


func init() -> void:
	init_completed.emit()


func login(username: String, _password: String) -> void:
	if username.is_empty():
		login_failed.emit({
			"reason": "username_is_empty"
		})
		return
	var password: String = _password
	_account_auth_service.request_account(
		"Login",
		{
			"email": username,
			"pwd": password.md5_text()
		},
		func(response: Dictionary) -> void:
			var state: int = _account_auth_service.read_state(response)
			if state != 1:
				login_failed.emit({
					"reason": "account_login_failed",
					"state": state,
					"message": _account_auth_service.read_message(response),
					"raw": response
				})
				return

			var user_id: String = _account_auth_service.read_user_id(response)
			if user_id.is_empty():
				login_failed.emit({
					"reason": "account_login_missing_user_id",
					"raw": response
				})
				return

			var login_info: Dictionary = {
				"method": "Login",
				"sessionId": user_id,
				"PartnerId": str(partner_id)
			}
			var payload: Dictionary = _adapter.build_login_payload(user_id, user_id, login_info)
			login_completed.emit(payload)
	)


func register_account(username: String, _password: String) -> void:
	if username.is_empty():
		login_failed.emit({
			"reason": "username_is_empty"
		})
		return
	var password: String = _password
	_account_auth_service.request_account(
		"Register",
		{
			"email": username,
			"pwd": password.md5_text(),
			"udid": username
		},
		func(response: Dictionary) -> void:
			var state: int = _account_auth_service.read_state(response)
			if state != 1:
				var message: String = _account_auth_service.read_message(response)
				# 兼容旧流程：注册遇到“账号已存在”时直接转登录，不阻断联调。
				if _account_auth_service.looks_like_account_exists(state, message):
					print("[Platform] Register returned exists, fallback to Login. state=%d message=%s" % [state, message])
					login(username, password)
					return
				login_failed.emit({
					"reason": "account_register_failed",
					"state": state,
					"message": message,
					"raw": response
				})
				return
			login(username, password)
	)


func request_server_list(request_data: Dictionary, callback: Callable) -> void:
	_server_list_service.update_game_center_url(game_center_url)
	_server_list_service.request_server_list(request_data, callback)
