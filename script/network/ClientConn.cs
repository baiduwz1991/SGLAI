using System;
using System.Collections.Generic;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace Sanhai.NetWork.Network
{
    public enum ESocketState
    {
        Connecting = 0,
        Connected = 1,
        Closed = 2,
    }

    public enum ESocketError
    {
        SendRecieveError = -1,
        Unknown = -2,
        ConnectError = -3,
        ConnectOutOfDate = -4,
        ClosedSocket = -5,
    }

    /// <summary>
    /// 迁移版 TCP 连接器：保留旧回调协议，移除 Thread.Abort。
    /// </summary>
    public sealed class ClientConn : IDisposable
    {
        private const int IdleWaitMs = 5;

        public Action<int, string>? onStateChanged;
        public Action<byte[]>? onReceivedMsg;

        private readonly MessageQueue _sendQueue = new();
        private readonly MessageQueue _receiveQueue = new();
        private readonly SendSemaphore _sendSemaphore = new();
        private readonly List<byte[]> _tempMessageList = new();

        private readonly int _maxReceiveBuffer;
        private readonly int _maxSendBuffer;

        private readonly object _socketLock = new();
        private Socket? _socket;
        private CancellationTokenSource? _cts;
        private Task? _sendTask;
        private Task? _receiveTask;

        private string _host = string.Empty;
        private int _port;
        private float _connectTimeoutSeconds = 5f;
        private DateTime _connectStartTimeUtc;

        public ESocketState State { get; private set; } = ESocketState.Closed;
        public bool IsConnected => _socket is { Connected: true } && State == ESocketState.Connected;

        public ClientConn(int receiveBuffer = 1024 * 1024, int sendBuffer = 8 * 1024)
        {
            _maxReceiveBuffer = receiveBuffer;
            _maxSendBuffer = sendBuffer;
        }

        public void SetHostPort(string host, int port)
        {
            _host = host;
            _port = port;
        }

        public void SetConnectTimeLimit(float seconds)
        {
            if (seconds > 0f)
            {
                _connectTimeoutSeconds = seconds;
            }
        }

        public void Connect()
        {
            Close();

            try
            {
                Socket socket = new(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp)
                {
                    SendTimeout = 3000,
                    SendBufferSize = _maxSendBuffer,
                    NoDelay = true,
                };

                State = ESocketState.Connecting;
                _connectStartTimeUtc = DateTime.UtcNow;
                lock (_socketLock)
                {
                    _socket = socket;
                }

                socket.BeginConnect(_host, _port, ar =>
                {
                    try
                    {
                        socket.EndConnect(ar);
                        State = ESocketState.Connected;
                        ReportSocketState(0, "connected");
                        StartNetworkLoop();
                    }
                    catch (Exception ex)
                    {
                        State = ESocketState.Closed;
                        ReportSocketState((int)ESocketError.ConnectError, ex.Message);
                        Close();
                    }
                }, null);
            }
            catch (Exception ex)
            {
                State = ESocketState.Closed;
                ReportSocketState((int)ESocketError.ConnectError, ex.Message);
            }
        }

        public void SendMessage(byte[] message)
        {
            _sendQueue.Add(message);
            _sendSemaphore.ProduceResource();
        }

        public void UpdateNetwork()
        {
            UpdateSocketState();
            UpdatePacket();
        }

        public void Close()
        {
            CancellationTokenSource? cts;
            Socket? socket;

            lock (_socketLock)
            {
                cts = _cts;
                _cts = null;
                socket = _socket;
                _socket = null;
            }

            if (cts != null)
            {
                cts.Cancel();
                // 唤醒发送线程，避免阻塞在 WaitResource。
                _sendSemaphore.ProduceResource();
                cts.Dispose();
            }

            State = ESocketState.Closed;
            if (socket != null)
            {
                SafeClose(socket);
            }
        }

        private void StartNetworkLoop()
        {
            _cts = new CancellationTokenSource();
            CancellationToken token = _cts.Token;
            _sendTask = Task.Run(() => SendLoop(token), token);
            _receiveTask = Task.Run(() => ReceiveLoop(token), token);
        }

        private void SendLoop(CancellationToken token)
        {
            while (!token.IsCancellationRequested)
            {
                _sendSemaphore.WaitResource();
                if (token.IsCancellationRequested || _socket == null || !IsConnected)
                {
                    WaitForIdle(token);
                    continue;
                }

                if (_sendQueue.Empty())
                {
                    WaitForIdle(token);
                    continue;
                }

                _sendQueue.MoveTo(_tempMessageList);
                try
                {
                    for (int index = 0; index < _tempMessageList.Count; index++)
                    {
                        byte[] bytes = _tempMessageList[index];
                        _socket.Send(bytes, bytes.Length, SocketFlags.None);
                        StreamBufferPool.RecycleBuffer(bytes);
                    }
                    _tempMessageList.Clear();
                }
                catch (Exception ex)
                {
                    ReportSocketState((int)ESocketError.SendRecieveError, ex.Message);
                    Close();
                }
            }
        }

        private void ReceiveLoop(CancellationToken token)
        {
            byte[] receiveBuffer = new byte[_maxReceiveBuffer];
            while (!token.IsCancellationRequested)
            {
                if (_socket == null || !IsConnected)
                {
                    WaitForIdle(token);
                    continue;
                }

                try
                {
                    int readLen = _socket.Receive(receiveBuffer, 0, receiveBuffer.Length, SocketFlags.None);
                    if (readLen <= 0)
                    {
                        throw new SocketException((int)SocketError.ConnectionReset);
                    }

                    byte[] packet = new byte[readLen];
                    Buffer.BlockCopy(receiveBuffer, 0, packet, 0, readLen);
                    _receiveQueue.Add(packet);
                }
                catch (Exception ex)
                {
                    ReportSocketState((int)ESocketError.SendRecieveError, ex.Message);
                    Close();
                }
            }
        }

        private void UpdatePacket()
        {
            if (_receiveQueue.Empty())
            {
                return;
            }

            _receiveQueue.MoveTo(_tempMessageList);
            for (int index = 0; index < _tempMessageList.Count; index++)
            {
                byte[] msg = _tempMessageList[index];
                onReceivedMsg?.Invoke(msg);
                StreamBufferPool.RecycleBuffer(msg);
            }
            _tempMessageList.Clear();
        }

        private void UpdateSocketState()
        {
            if (State != ESocketState.Connecting)
            {
                return;
            }

            double elapsed = (DateTime.UtcNow - _connectStartTimeUtc).TotalSeconds;
            if (elapsed < _connectTimeoutSeconds)
            {
                return;
            }

            ReportSocketState((int)ESocketError.ConnectOutOfDate, "connection timeout");
            Close();
        }

        private void ReportSocketState(int code, string message)
        {
            onStateChanged?.Invoke(code, message);
        }

        private static void SafeClose(Socket socket)
        {
            try
            {
                if (socket.Connected)
                {
                    socket.Shutdown(SocketShutdown.Both);
                }
            }
            catch
            {
                // ignore
            }
            finally
            {
                socket.Close();
                socket.Dispose();
            }
        }

        private static void WaitForIdle(CancellationToken token)
        {
            try
            {
                Task.Delay(IdleWaitMs, token).Wait(token);
            }
            catch (OperationCanceledException)
            {
                // closing
            }
        }

        public void Dispose()
        {
            Close();
            _sendQueue.Dispose();
            _receiveQueue.Dispose();
            onStateChanged = null;
            onReceivedMsg = null;
            GC.SuppressFinalize(this);
        }
    }
}
