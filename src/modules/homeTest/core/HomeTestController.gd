class_name HomeTestController
extends BaseController

const CONTROLLER_ID: StringName = &"home_test_controller"

signal status_changed(message: String)


func get_id() -> StringName:
	return CONTROLLER_ID


func on_game_start() -> void:
	status_changed.emit("已进入 homeTest。")


func on_game_server_login(back: Callable = Callable()) -> void:
	_call_back(back)


func on_reconnection(back: Callable = Callable()) -> void:
	_call_back(back)


func on_login_out() -> void:
	pass


func on_module_button_pressed(module_name: String) -> void:
	var message: String = "点击了：%s" % module_name
	print("[HomeTestController] %s" % message)
	status_changed.emit(message)
