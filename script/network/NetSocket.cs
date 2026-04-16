using Godot;
using System.Threading.Tasks;
using System;
using System.Collections.Concurrent;
using System.Text;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// 迁移版 NetSocket：兼容 Lua 时代调用习惯。
    /// </summary>
    [GlobalClass]
    public partial class NetSocket : Node
    {
        private enum PendingSignalType
        {
            Opened,
            Closed,
            Errored,
            TextMessageReceived,
        }

        private readonly struct PendingSignal
        {
            public readonly PendingSignalType Type;
            public readonly int Code;
            public readonly string ReasonOrMessage;

            public PendingSignal(PendingSignalType type, int code, string reasonOrMessage)
            {
                Type = type;
                Code = code;
                ReasonOrMessage = reasonOrMessage;
            }
        }

        [Signal]
        public delegate void OpenedEventHandler();

        [Signal]
        public delegate void ClosedEventHandler(int code, string reason);

        [Signal]
        public delegate void ErroredEventHandler(string reason);

        [Signal]
        public delegate void TextMessageReceivedEventHandler(string message);

        private readonly NetWebSocket _webSocket = new();
        private readonly ClientConn _tcpClient = new();
        private readonly TcpSendData _sendData = new();
        private readonly TcpRecieveData _tcpRecieveData = new();
        private readonly WebSocketRecieveData _wsRecieveData = new();

        private bool _isWebSocket;
        private bool _isKcp;

        private Action<int, int, byte[]>? _receiveCb;
        private Action<int, string>? _stateCb;
        private readonly ConcurrentQueue<PendingSignal> _pendingSignalQueue = new();

        public new bool IsConnected => _isWebSocket ? _webSocket.IsConnected : _tcpClient.IsConnected;

        public NetSocket()
        {
            ConfigureTransport(false, false);

            _tcpClient.onStateChanged += OnStateChanged;
            _tcpClient.onReceivedMsg += OnTcpReceivedMsg;

            _webSocket.RegisterHandler(NetWebSocketHandle.OPEN, _ => OnStateChanged(0, "connected"));
            _webSocket.RegisterHandler(NetWebSocketHandle.ERROE, reason => OnStateChanged(3, reason));
            _webSocket.RegisterHandler(NetWebSocketHandle.CLOSED, reason => OnStateChanged(1, reason));
            _webSocket.RegisterHandler(NetWebSocketHandle.MESSAGE, OnWebSocketMessage);
        }

        public override void _Ready()
        {
            SetProcess(true);
        }

        public override void _Process(double delta)
        {
            while (_pendingSignalQueue.TryDequeue(out PendingSignal signal))
            {
                switch (signal.Type)
                {
                    case PendingSignalType.Opened:
                        EmitSignal(SignalName.Opened);
                        break;
                    case PendingSignalType.Closed:
                        EmitSignal(SignalName.Closed, signal.Code, signal.ReasonOrMessage);
                        break;
                    case PendingSignalType.Errored:
                        EmitSignal(SignalName.Errored, signal.ReasonOrMessage);
                        break;
                    case PendingSignalType.TextMessageReceived:
                        EmitSignal(SignalName.TextMessageReceived, signal.ReasonOrMessage);
                        break;
                }
            }
        }

        public void ConfigureTransport(bool isWebSocket, bool isKcp)
        {
            _isWebSocket = isWebSocket;
            _isKcp = isKcp;
        }

        public void Connect(
            string ip,
            int port,
            Action<int, string> stateCallBack,
            Action<int, int, byte[]> receiveCallBack,
            int connectTimeout = 5000)
        {
            _stateCb = stateCallBack;
            _receiveCb = receiveCallBack;

            if (_isKcp)
            {
                OnStateChanged(3, "KCP transport is not implemented yet in migration version.");
                return;
            }

            if (_isWebSocket)
            {
                _ = _webSocket.ConnectAsync(ip);
                return;
            }

            _tcpClient.SetHostPort(ip, port);
            _tcpClient.SetConnectTimeLimit(connectTimeout / 1000f);
            _tcpClient.Connect();
        }

        public Task<(bool ok, string error)> ConnectAsync(string url)
        {
            if (!_isWebSocket)
            {
                throw new InvalidOperationException("ConnectAsync only supports websocket mode.");
            }

            return _webSocket.ConnectAsync(url);
        }

        public Error ConnectWebSocket(string url)
        {
            if (!_isWebSocket)
            {
                return Error.Unavailable;
            }

            if (string.IsNullOrWhiteSpace(url))
            {
                return Error.InvalidParameter;
            }

            if (!Uri.TryCreate(url, UriKind.Absolute, out Uri? uri))
            {
                return Error.InvalidParameter;
            }

            string scheme = uri.Scheme.ToLowerInvariant();
            if (scheme != "ws" && scheme != "wss")
            {
                return Error.InvalidParameter;
            }

            _ = ConnectAsync(url);
            return Error.Ok;
        }

        public void Close()
        {
            if (_isWebSocket)
            {
                _webSocket.Close();
            }
            else
            {
                _tcpClient.Close();
            }
            _stateCb = null;
            _receiveCb = null;
        }

        public bool SendText(string text)
        {
            if (!IsConnected)
            {
                return false;
            }

            _ = SendTextAsync(text);
            return true;
        }

        public bool SendBinary(byte[] data)
        {
            if (!IsConnected)
            {
                return false;
            }

            _ = _webSocket.SendAsync(data);
            return true;
        }

        public void UpdateNetwork()
        {
            if (!_isWebSocket)
            {
                _tcpClient.UpdateNetwork();
            }
        }

        public void SendMsg(int requestId, int msgId, byte[] data, string? logicId = null, byte[]? extendData = null)
        {
            byte[]? logicIdData = string.IsNullOrEmpty(logicId) ? null : Encoding.ASCII.GetBytes(logicId);
            _sendData.Build(requestId, msgId, logicIdData, extendData, data);
            byte[] packet = _sendData.GetBytes();

            if (_isWebSocket)
            {
                _ = _webSocket.SendAsync(packet);
            }
            else if (_isKcp)
            {
                OnStateChanged(3, "KCP transport is not implemented yet in migration version.");
            }
            else
            {
                _tcpClient.SendMessage(packet);
            }
        }

        public Task<(bool ok, string error)> SendTextAsync(string text)
        {
            return _webSocket.SendAsync(text);
        }

        public Task DisconnectAsync()
        {
            return _webSocket.DisconnectAsync();
        }

        private void OnTcpReceivedMsg(byte[] packet)
        {
            if (_tcpRecieveData.Read(packet, out int requestId, out int msgId, out byte[] body))
            {
                _receiveCb?.Invoke(requestId, msgId, body);
            }
        }

        private void OnWebSocketMessage(string payload)
        {
            if (string.IsNullOrEmpty(payload))
            {
                return;
            }

            _pendingSignalQueue.Enqueue(new PendingSignal(PendingSignalType.TextMessageReceived, 0, payload));

            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(payload);
            }
            catch (FormatException)
            {
                bytes = Encoding.UTF8.GetBytes(payload);
            }

            if (_wsRecieveData.Read(bytes))
            {
                _receiveCb?.Invoke(_wsRecieveData.RequestId, _wsRecieveData.Protocol, _wsRecieveData.BytesData);
            }
        }

        private void OnStateChanged(int state, string message)
        {
            _stateCb?.Invoke(state, message);
            switch (state)
            {
                case 0:
                    _pendingSignalQueue.Enqueue(new PendingSignal(PendingSignalType.Opened, 0, string.Empty));
                    break;
                case 1:
                    _pendingSignalQueue.Enqueue(new PendingSignal(PendingSignalType.Closed, 1000, message));
                    break;
                case 3:
                    _pendingSignalQueue.Enqueue(new PendingSignal(PendingSignalType.Errored, 0, message));
                    break;
            }
        }
    }
}
