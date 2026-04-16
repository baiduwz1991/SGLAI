using System;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// 请求包编码器，保持与旧项目一致的字段布局。
    /// </summary>
    public sealed class TcpSendData
    {
        public const int TcpHeaderLen = 12;

        private static readonly Encry Encry = new("kuaifeixia_tcp_key-123456");

        public int RequestId { get; private set; }
        public int Protocol { get; private set; }
        public byte LogicIdLen { get; private set; }
        public byte[]? LogicIdData { get; private set; }
        public byte ExtendLen { get; private set; }
        public byte[]? ExtendData { get; private set; }
        public int Length { get; private set; }
        public byte[]? BytesData { get; private set; }

        public void Build(int requestId, int protocol, byte[]? logicIdData = null, byte[]? extendData = null, byte[]? bytesData = null)
        {
            RequestId = requestId;
            Protocol = protocol;
            LogicIdData = logicIdData;
            LogicIdLen = (byte)(logicIdData?.Length ?? 0);
            ExtendData = extendData;
            ExtendLen = (byte)(extendData?.Length ?? 0);
            BytesData = bytesData;
            Length = bytesData?.Length ?? 0;
        }

        public byte[] GetBytes()
        {
            int bufferLength = 4 + 4 + (1 + LogicIdLen) + (1 + ExtendLen) + 4 + Length;
            StreamBuffer sendBuffer = StreamBufferPool.GetStream(bufferLength, canWrite: true, canRead: false);
            sendBuffer.BinaryWriter.Write(RequestId);
            sendBuffer.BinaryWriter.Write(Protocol);
            sendBuffer.BinaryWriter.Write(LogicIdLen);
            if (LogicIdData != null)
            {
                sendBuffer.BinaryWriter.Write(LogicIdData);
            }

            sendBuffer.BinaryWriter.Write(ExtendLen);
            if (ExtendData != null)
            {
                sendBuffer.BinaryWriter.Write(ExtendData);
            }

            sendBuffer.BinaryWriter.Write(Length);
            if (BytesData != null)
            {
                sendBuffer.BinaryWriter.Write(BytesData);
            }

            byte[] data = sendBuffer.MemoryStream.ToArray();
            StreamBufferPool.RecycleStream(sendBuffer);

            // 旧实现默认不启用加密，保留能力开关。
            // Encry.DoEncry(data, TcpHeaderLen);
            return data;
        }
    }
}
