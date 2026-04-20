class_name HomeController
extends BaseController

const CONTROLLER_ID: StringName = &"home_controller"

signal status_changed(message: String)


func get_id() -> StringName:
	return CONTROLLER_ID


func on_game_start() -> void:
	status_changed.emit("已进入 home。")


func on_game_server_login(back: Callable = Callable()) -> void:
	_call_back(back)


func on_reconnection(back: Callable = Callable()) -> void:
	_call_back(back)


func on_login_out() -> void:
	pass


func on_module_tab_selected(module_name: String) -> void:
	var message: String = "切换页签：%s" % module_name
	print("[HomeController] %s" % message)
	status_changed.emit(message)
