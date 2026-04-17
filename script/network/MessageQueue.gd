class_name MessageQueue
extends RefCounted

var _mutex: Mutex = Mutex.new()
var _message_list: Array[PackedByteArray] = []


func _init(capacity: int = 10) -> void:
	_message_list.resize(0)


func Add(message: PackedByteArray) -> void:
	_mutex.lock()
	_message_list.append(message)
	_mutex.unlock()


func MoveTo(bytes_list: Array[PackedByteArray]) -> void:
	_mutex.lock()
	for message in _message_list:
		bytes_list.append(message)
	_message_list.clear()
	_mutex.unlock()


func Empty() -> bool:
	_mutex.lock()
	var is_empty: bool = _message_list.is_empty()
	_mutex.unlock()
	return is_empty


func Dispose() -> void:
	_mutex.lock()
	for message in _message_list:
		StreamBufferPool.RecycleBuffer(message)
	_message_list.clear()
	_mutex.unlock()
