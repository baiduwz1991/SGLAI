using System;
using System.Collections.Generic;
using System.IO;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// StreamBuffer/byte[] 对象池，兼容旧网络模块接口。
    /// </summary>
    public static class StreamBufferPool
    {
        private const int BufferPoolSize = 500;
        private static readonly Dictionary<int, Queue<StreamBuffer>> StreamPool = new();
        private static readonly Dictionary<int, Queue<byte[]>> BufferPool = new();
        private static readonly object StreamLock = new();
        private static readonly object BufferLock = new();

        private static int _streamCount;
        private static int _bufferCount;

        public static StreamBuffer GetStream(int expectedSize, bool canWrite, bool canRead)
        {
            if (expectedSize <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(expectedSize), "expectedSize must > 0");
            }

            lock (StreamLock)
            {
                if (!StreamPool.TryGetValue(expectedSize, out Queue<StreamBuffer>? cache))
                {
                    cache = new Queue<StreamBuffer>();
                    StreamPool[expectedSize] = cache;
                }

                if (cache.Count > 0)
                {
                    _streamCount--;
                    StreamBuffer streamBuffer = cache.Dequeue();
                    streamBuffer.SetOperate(canWrite, canRead);
                    return streamBuffer;
                }
            }

            return new StreamBuffer(expectedSize, canWrite, canRead);
        }

        public static void RecycleStream(StreamBuffer stream)
        {
            if (stream == null || stream.Size <= 0)
            {
                return;
            }

            lock (StreamLock)
            {
                if (!StreamPool.TryGetValue(stream.Size, out Queue<StreamBuffer>? cache))
                {
                    cache = new Queue<StreamBuffer>();
                    StreamPool[stream.Size] = cache;
                }

                stream.ClearBuffer();
                stream.ResetStream();
                _streamCount++;
                cache.Enqueue(stream);
            }
        }

        public static byte[] GetBuffer(StreamBuffer streamBuffer)
        {
            return GetBuffer(streamBuffer, 0, streamBuffer.Size);
        }

        public static byte[] GetBuffer(StreamBuffer streamBuffer, int start, int length)
        {
            byte[] buffer = GetBuffer(length);
            streamBuffer.CopyTo(buffer, start, 0, length);
            return buffer;
        }

        public static byte[] GetBuffer(int expectedSize)
        {
            if (expectedSize <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(expectedSize), "expectedSize must > 0");
            }

            lock (BufferLock)
            {
                if (!BufferPool.TryGetValue(expectedSize, out Queue<byte[]>? cache))
                {
                    cache = new Queue<byte[]>();
                    BufferPool[expectedSize] = cache;
                }

                if (cache.Count > 0)
                {
                    _bufferCount--;
                    return cache.Dequeue();
                }
            }

            return new byte[expectedSize];
        }

        public static byte[] DeepCopy(byte[]? source)
        {
            if (source == null)
            {
                return Array.Empty<byte>();
            }

            if (source.Length == 0)
            {
                return Array.Empty<byte>();
            }

            byte[] bytes = GetBuffer(source.Length);
            Buffer.BlockCopy(source, 0, bytes, 0, source.Length);
            return bytes;
        }

        public static void RecycleBuffer(byte[]? buffer)
        {
            if (buffer == null || buffer.Length == 0 || _bufferCount > BufferPoolSize)
            {
                return;
            }

            lock (BufferLock)
            {
                if (!BufferPool.TryGetValue(buffer.Length, out Queue<byte[]>? cache))
                {
                    cache = new Queue<byte[]>();
                    BufferPool[buffer.Length] = cache;
                }

                Array.Fill(buffer, (byte)0);
                _bufferCount++;
                cache.Enqueue(buffer);
            }
        }
    }

    public sealed class StreamBuffer : IDisposable
    {
        private byte[] _buffer;
        private MemoryStream? _memoryStream;
        private BinaryReader? _binaryReader;
        private BinaryWriter? _binaryWriter;

        public StreamBuffer(int bufferSize, bool canWrite, bool canRead)
        {
            if (bufferSize <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(bufferSize), "bufferSize must > 0");
            }

            _buffer = new byte[bufferSize];
            SetOperate(canWrite, canRead);
        }

        public bool CanWrite { get; private set; }
        public bool CanRead { get; private set; }
        public int Size => _buffer.Length;

        public MemoryStream MemoryStream
        {
            get
            {
                if (!CanRead && !CanWrite)
                {
                    throw new InvalidOperationException("The stream buffer can not read and can not write.");
                }

                _memoryStream ??= new MemoryStream(_buffer, 0, _buffer.Length, writable: true, publiclyVisible: true);
                return _memoryStream;
            }
        }

        public BinaryReader BinaryReader
        {
            get
            {
                if (!CanRead)
                {
                    throw new InvalidOperationException("The stream buffer can not read.");
                }

                _binaryReader ??= new BinaryReader(MemoryStream);
                return _binaryReader;
            }
        }

        public BinaryWriter BinaryWriter
        {
            get
            {
                if (!CanWrite)
                {
                    throw new InvalidOperationException("The stream buffer can not write.");
                }

                _binaryWriter ??= new BinaryWriter(MemoryStream);
                return _binaryWriter;
            }
        }

        internal void SetOperate(bool canWrite, bool canRead)
        {
            CanWrite = canWrite;
            CanRead = canRead;
        }

        public void CopyFrom(byte[] src, int srcOffset, int dstOffset, int length)
        {
            Buffer.BlockCopy(src, srcOffset, _buffer, dstOffset, length);
        }

        public void CopyTo(byte[] dst, int srcOffset, int dstOffset, int length)
        {
            Buffer.BlockCopy(_buffer, srcOffset, dst, dstOffset, length);
        }

        public byte[] ToArray()
        {
            return StreamBufferPool.GetBuffer(this);
        }

        public byte[] ToArray(int start, int length)
        {
            return StreamBufferPool.GetBuffer(this, start, length);
        }

        public byte[] GetBuffer()
        {
            return _buffer;
        }

        public void ClearBuffer()
        {
            Array.Fill(_buffer, (byte)0);
        }

        public void ResetStream()
        {
            MemoryStream.Seek(0, SeekOrigin.Begin);
            MemoryStream.SetLength(0);
        }

        public void Dispose()
        {
            _buffer = Array.Empty<byte>();
            _binaryReader?.Dispose();
            _binaryWriter?.Dispose();
            _memoryStream?.Dispose();
            _binaryReader = null;
            _binaryWriter = null;
            _memoryStream = null;
        }
    }
}
