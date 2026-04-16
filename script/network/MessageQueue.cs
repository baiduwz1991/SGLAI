using System;
using System.Collections.Generic;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// 线程安全消息队列，保持旧接口以便渐进迁移。
    /// </summary>
    public sealed class MessageQueue : IDisposable
    {
        private readonly object _mutex = new();
        private readonly List<byte[]> _messageList;
        private bool _disposed;

        public MessageQueue(int capacity = 10)
        {
            _messageList = new List<byte[]>(capacity);
        }

        public void Add(byte[] message)
        {
            lock (_mutex)
            {
                _messageList.Add(message);
            }
        }

        public void MoveTo(List<byte[]> bytesList)
        {
            lock (_mutex)
            {
                bytesList.AddRange(_messageList);
                _messageList.Clear();
            }
        }

        public bool Empty()
        {
            lock (_mutex)
            {
                return _messageList.Count == 0;
            }
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            lock (_mutex)
            {
                for (int index = 0; index < _messageList.Count; index++)
                {
                    StreamBufferPool.RecycleBuffer(_messageList[index]);
                }
                _messageList.Clear();
            }

            _disposed = true;
            GC.SuppressFinalize(this);
        }
    }
}
