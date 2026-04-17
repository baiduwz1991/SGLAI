class_name SendSemaphore
extends RefCounted

var _resource: int = 0
var _resource_lock: Mutex = Mutex.new()
var _semaphore: Semaphore = Semaphore.new()


func WaitResource(count: int = 1) -> void:
	while true:
		_resource_lock.lock()
		if _resource >= count:
			_resource -= count
			_resource_lock.unlock()
			return
		_resource_lock.unlock()
		_semaphore.wait()


func ProduceResource(count: int = 1) -> void:
	_resource_lock.lock()
	_resource += count
	_resource_lock.unlock()

	var index: int = 0
	while index < count:
		_semaphore.post()
		index += 1
