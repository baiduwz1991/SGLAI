extends Node

var _controllers: Dictionary[StringName, BaseController] = {}


func register_controller(controller: BaseController) -> void:
	var controller_id: StringName = controller.get_id()
	_controllers[controller_id] = controller


func get_or_register_controller(controller_id: StringName, create_controller: Callable) -> BaseController:
	if has_controller(controller_id):
		return get_controller(controller_id)

	var created_variant: Variant = create_controller.call()
	var created_controller: BaseController = created_variant as BaseController
	if created_controller == null:
		push_error("ControllerManager 创建控制器失败：返回值不是 BaseController。")
		return null

	register_controller(created_controller)
	return created_controller


func has_controller(controller_id: StringName) -> bool:
	return _controllers.has(controller_id)


func get_controller(controller_id: StringName) -> BaseController:
	if not has_controller(controller_id):
		return null
	return _controllers[controller_id]


func unregister_controller(controller_id: StringName) -> void:
	if has_controller(controller_id):
		var controller: BaseController = _controllers[controller_id]
		controller.on_release()
	_controllers.erase(controller_id)


func clear_controllers() -> void:
	for controller in _controllers.values():
		controller.on_release()
	_controllers.clear()


func notify_game_start() -> void:
	for controller in _controllers.values():
		controller.on_game_start()


func notify_login() -> void:
	for controller in _controllers.values():
		controller.on_login()


func notify_logout() -> void:
	for controller in _controllers.values():
		controller.on_logout()
