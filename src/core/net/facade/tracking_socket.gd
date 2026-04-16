class_name TrackingSocketFacade
extends Node


const HttpRequestServiceScript: Script = preload("res://src/core/net/facade/http_request_service.gd")

var _http_service: HttpRequestService


func _ready() -> void:
	_http_service = HttpRequestServiceScript.new()
	add_child(_http_service)


func request_upload_data(big_data: Dictionary, event_name: String, callback: Callable = Callable()) -> void:
	var payload: Dictionary = {
		"eventName": event_name,
		"payload": big_data,
	}
	_http_service.request({
		"svrType": HttpRequestService.HTTP_SVR_TYPE_TRACKING,
		"url": str(big_data.get("url", "")),
		"headData": payload,
		"callback": callback
	})
