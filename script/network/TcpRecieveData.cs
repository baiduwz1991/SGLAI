using System;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// TCP 粘包拆包读取器。
    /// </summary>
    public sealed class TcpRecieveData
    {
        public const int TcpHeaderLen = 12;

        public int RequestId { get; private set; }
        public int Protocol { get; private set; }
        public int Length { get; private set; }
        public byte[] BytesData { get; private set; } = Array.Empty<byte>();

        private byte[] _readBuffer = new byte[10 * 1024];
        private int _readLength;

        public bool Read(byte[]? incoming, out int requestId, out int protocol, out byte[] body)
        {
            if (incoming != null && incoming.Length + _readLength > _readBuffer.Length)
            {
                int newSize = (int)(_readBuffer.Length * 1.5f);
                if (newSize < incoming.Length + _readLength)
                {
                    newSize = incoming.Length + _readLength;
                }
                Array.Resize(ref _readBuffer, newSize);
            }

            if (incoming != null && incoming.Length > 0)
            {
                Array.Copy(incoming, 0, _readBuffer, _readLength, incoming.Length);
                _readLength += incoming.Length;
            }

            if (_readLength < TcpHeaderLen)
            {
                requestId = 0;
                protocol = 0;
                body = Array.Empty<byte>();
                return false;
            }

            RequestId = BitConverter.ToInt32(_readBuffer, 0);
            Protocol = BitConverter.ToInt32(_readBuffer, 4);
            Length = BitConverter.ToInt32(_readBuffer, 8);
            if (Length < 0 || Length + TcpHeaderLen > _readLength)
            {
                requestId = 0;
                protocol = 0;
                body = Array.Empty<byte>();
                return false;
            }

            BytesData = new byte[Length];
            if (Length > 0)
            {
                Array.Copy(_readBuffer, TcpHeaderLen, BytesData, 0, Length);
            }

            int consumed = TcpHeaderLen + Length;
            _readLength -= consumed;
            if (_readLength > 0)
            {
                Array.Copy(_readBuffer, consumed, _readBuffer, 0, _readLength);
            }

            requestId = RequestId;
            protocol = Protocol;
            body = BytesData;
            return true;
        }
    }
}
