class_name ServerListService
extends RefCounted


var _http_service: HttpRequestService
var _adapter: PlatformNetAdapter
var _game_center_url: String = ""


func configure(http_service: HttpRequestService, adapter: PlatformNetAdapter, game_center_url: String) -> void:
	_http_service = http_service
	_adapter = adapter
	_game_center_url = game_center_url


func update_game_center_url(game_center_url: String) -> void:
	_game_center_url = game_center_url


func request_server_list(request_data: Dictionary, callback: Callable) -> void:
	if _adapter == null:
		if callback.is_valid():
			callback.call({
				"success": false,
				"reason": "platform_adapter_unavailable"
			})
		return

	if _game_center_url.is_empty():
		var local_response: Dictionary = _adapter.normalize_server_list_response({
			"success": true,
			"Code": 0,
			"Data": {
				"server_list": [
					{
						"server_id": "1",
						"server_name": "开发测试服",
						"server_url": "ws://127.0.0.1:9001/ws",
						"is_recommend": true,
						"is_history": true
					}
				]
			}
		})
		callback.call(local_response)
		return

	if _http_service == null:
		if callback.is_valid():
			callback.call({
				"success": false,
				"reason": "http_service_unavailable"
			})
		return

	_http_service.request({
		"svrType": HttpRequestService.HTTP_SVR_TYPE_MANAGE_CENTER,
		"moduleName": HttpRequestService.ACCOUNT_TYPE_GET_SERVER_LIST,
		"baseUrl": _game_center_url,
		"methodData": request_data,
		"callback": func(response: Dictionary) -> void:
			callback.call(_adapter.normalize_server_list_response(response))
	})
