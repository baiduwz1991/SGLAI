class_name StreamBufferPool
extends RefCounted

const BUFFER_POOL_SIZE: int = 500

static var _stream_pool: Dictionary = {}
static var _buffer_pool: Dictionary = {}
static var _stream_count: int = 0
static var _buffer_count: int = 0


static func GetStream(expected_size: int, can_write: bool, can_read: bool) -> StreamBuffer:
	if expected_size <= 0:
		push_error("StreamBufferPool.GetStream expected_size must > 0")
		return StreamBuffer.new(1, can_write, can_read)

	var cache: Array = _stream_pool.get(expected_size, [])
	if not cache.is_empty():
		_stream_count = maxi(_stream_count - 1, 0)
		var stream_buffer: StreamBuffer = cache.pop_back() as StreamBuffer
		_stream_pool[expected_size] = cache
		stream_buffer.SetOperate(can_write, can_read)
		return stream_buffer

	return StreamBuffer.new(expected_size, can_write, can_read)


static func RecycleStream(stream: StreamBuffer) -> void:
	if stream == null:
		return
	var stream_size: int = stream.Size()
	if stream_size <= 0:
		return

	var cache: Array = _stream_pool.get(stream_size, [])
	stream.ClearBuffer()
	stream.ResetStream()
	_stream_count += 1
	cache.append(stream)
	_stream_pool[stream_size] = cache


static func GetBuffer(stream_buffer: StreamBuffer, start: int = 0, length: int = -1) -> PackedByteArray:
	if stream_buffer == null:
		return PackedByteArray()
	if length < 0:
		return stream_buffer.ToArray()
	return stream_buffer.ToArray(start, length)


static func GetBufferBySize(expected_size: int) -> PackedByteArray:
	if expected_size <= 0:
		push_error("StreamBufferPool.GetBufferBySize expected_size must > 0")
		return PackedByteArray()

	var cache: Array = _buffer_pool.get(expected_size, [])
	if not cache.is_empty():
		_buffer_count = maxi(_buffer_count - 1, 0)
		var buffer: PackedByteArray = cache.pop_back() as PackedByteArray
		_buffer_pool[expected_size] = cache
		return buffer

	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(expected_size)
	return bytes


static func DeepCopy(source: PackedByteArray) -> PackedByteArray:
	if source.is_empty():
		return PackedByteArray()
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(source.size())
	var index: int = 0
	while index < source.size():
		bytes[index] = source[index]
		index += 1
	return bytes


static func RecycleBuffer(buffer: PackedByteArray) -> void:
	if buffer.is_empty() or _buffer_count > BUFFER_POOL_SIZE:
		return

	var cleaned: PackedByteArray = PackedByteArray()
	cleaned.resize(buffer.size())
	var cache: Array = _buffer_pool.get(buffer.size(), [])
	_buffer_count += 1
	cache.append(cleaned)
	_buffer_pool[buffer.size()] = cache
