using System;

namespace KcpCSharp
{
    /// <summary>
    /// 迁移阶段最小 ByteBuf 占位实现，后续可替换为完整 KCP 缓冲。
    /// </summary>
    public sealed class ByteBuf
    {
        private byte[] _buffer;

        public ByteBuf(int capacity = 0)
        {
            _buffer = capacity > 0 ? new byte[capacity] : Array.Empty<byte>();
        }

        public int Length => _buffer.Length;

        public byte[] ToArray()
        {
            byte[] bytes = new byte[_buffer.Length];
            Buffer.BlockCopy(_buffer, 0, bytes, 0, _buffer.Length);
            return bytes;
        }

        public void SetBytes(byte[] data)
        {
            _buffer = new byte[data.Length];
            Buffer.BlockCopy(data, 0, _buffer, 0, data.Length);
        }
    }
}
