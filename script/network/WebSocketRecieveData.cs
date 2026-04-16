using System;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// WebSocket 完整帧解析器。
    /// </summary>
    public sealed class WebSocketRecieveData
    {
        public const int TcpHeaderLen = 12;

        public int RequestId { get; private set; }
        public int Protocol { get; private set; }
        public int Length { get; private set; }
        public byte[] BytesData { get; private set; } = Array.Empty<byte>();

        public bool Read(byte[] data)
        {
            if (data.Length < TcpHeaderLen)
            {
                return false;
            }

            RequestId = BitConverter.ToInt32(data, 0);
            Protocol = BitConverter.ToInt32(data, 4);
            Length = BitConverter.ToInt32(data, 8);
            if (Length < 0 || Length + TcpHeaderLen != data.Length)
            {
                return false;
            }

            BytesData = new byte[Length];
            if (Length > 0)
            {
                Array.Copy(data, TcpHeaderLen, BytesData, 0, Length);
            }
            return true;
        }
    }
}
