using System;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Sanhai.NetWork.Network
{
    public enum NetWebSocketHandle
    {
        OPEN = 0,
        MESSAGE = 1,
        ERROE = 2, // 保持与旧 Lua 拼写兼容。
        CLOSED = 3,
    }

    public enum NetCompressType
    {
        NONE = 0,
        ZIP = 1,
        LZ4 = 2,
    }

    /// <summary>
    /// Godot 兼容版 NetWebSocket：替代 BestHTTP.WebSocket。
    /// </summary>
    public sealed class NetWebSocket : IDisposable
    {
        private ClientWebSocket _socket = new ClientWebSocket();
        private CancellationTokenSource _cts = new CancellationTokenSource();
        private readonly WebSocketRecieveData _recieveData = new();

        private Action<string>? _onOpen;
        private Action<string>? _onMessage;
        private Action<string>? _onError;
        private Action<string>? _onClosed;
        private Task? _receiveLoopTask;

        public bool IsConnected => _socket.State == WebSocketState.Open;

        public void RegisterHandler(NetWebSocketHandle handle, Action<string> callback)
        {
            switch (handle)
            {
                case NetWebSocketHandle.OPEN:
                    _onOpen = callback;
                    break;
                case NetWebSocketHandle.MESSAGE:
                    _onMessage = callback;
                    break;
                case NetWebSocketHandle.ERROE:
                    _onError = callback;
                    break;
                case NetWebSocketHandle.CLOSED:
                    _onClosed = callback;
                    break;
            }
        }

        public bool Connect(string url)
        {
            if (string.IsNullOrWhiteSpace(url))
            {
                return false;
            }

            _ = ConnectAsync(url);
            return true;
        }

        public async Task<(bool ok, string error)> ConnectAsync(string url)
        {
            try
            {
                if (_socket.State == WebSocketState.Open)
                {
                    return (true, string.Empty);
                }

                _socket.Dispose();
                _cts.Cancel();
                _cts = new CancellationTokenSource();
                _socket = new ClientWebSocket();
                await _socket.ConnectAsync(new Uri(url), _cts.Token);
                _onOpen?.Invoke("opened");
                _receiveLoopTask = Task.Run(() => ReceiveLoopAsync(_cts.Token), _cts.Token);
                return (true, string.Empty);
            }
            catch (Exception ex)
            {
                _onError?.Invoke(ex.Message);
                return (false, ex.Message);
            }
        }

        public bool Send(byte[] data)
        {
            if (!IsConnected)
            {
                return false;
            }

            _ = SendAsync(data);
            return true;
        }

        public bool Send(string text)
        {
            if (!IsConnected)
            {
                return false;
            }

            _ = SendAsync(text);
            return true;
        }

        public async Task<(bool ok, string error)> SendAsync(byte[] data)
        {
            if (!IsConnected)
            {
                return (false, "socket not connected");
            }

            try
            {
                await _socket.SendAsync(data, WebSocketMessageType.Binary, true, _cts.Token);
                return (true, string.Empty);
            }
            catch (Exception ex)
            {
                _onError?.Invoke(ex.Message);
                return (false, ex.Message);
            }
        }

        public async Task<(bool ok, string error)> SendAsync(string text)
        {
            if (!IsConnected)
            {
                return (false, "socket not connected");
            }

            try
            {
                byte[] payload = Encoding.UTF8.GetBytes(text);
                await _socket.SendAsync(payload, WebSocketMessageType.Text, true, _cts.Token);
                return (true, string.Empty);
            }
            catch (Exception ex)
            {
                _onError?.Invoke(ex.Message);
                return (false, ex.Message);
            }
        }

        private async Task ReceiveLoopAsync(CancellationToken token)
        {
            byte[] buffer = new byte[64 * 1024];
            while (!token.IsCancellationRequested && IsConnected)
            {
                try
                {
                    WebSocketReceiveResult result = await _socket.ReceiveAsync(new ArraySegment<byte>(buffer), token);
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        _onClosed?.Invoke("closed by peer");
                        await DisconnectAsync();
                        break;
                    }

                    if (result.MessageType == WebSocketMessageType.Binary)
                    {
                        byte[] payload = new byte[result.Count];
                        Buffer.BlockCopy(buffer, 0, payload, 0, result.Count);
                        if (_recieveData.Read(payload))
                        {
                            string message = Encoding.UTF8.GetString(_recieveData.BytesData);
                            _onMessage?.Invoke(message);
                        }
                        else
                        {
                            _onMessage?.Invoke(Convert.ToBase64String(payload));
                        }
                    }
                    else
                    {
                        string message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        _onMessage?.Invoke(message);
                    }
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _onError?.Invoke(ex.Message);
                    break;
                }
            }
        }

        public async Task<(bool ok, string error)> ReceiveAsync()
        {
            if (!IsConnected)
            {
                return (false, "socket not connected");
            }

            try
            {
                byte[] buffer = new byte[8 * 1024];
                WebSocketReceiveResult receiveResult = await _socket.ReceiveAsync(new ArraySegment<byte>(buffer), _cts.Token);
                if (receiveResult.MessageType == WebSocketMessageType.Close)
                {
                    return (false, "closed");
                }
                return (true, Encoding.UTF8.GetString(buffer, 0, receiveResult.Count));
            }
            catch (Exception ex)
            {
                return (false, ex.Message);
            }
        }

        public void Close()
        {
            _ = DisconnectAsync();
        }

        public async Task DisconnectAsync()
        {
            try
            {
                _cts.Cancel();
                if (_socket.State == WebSocketState.Open)
                {
                    await _socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "disconnect", _cts.Token);
                }
            }
            catch
            {
                // 断开时忽略异常。
            }
            finally
            {
                _onClosed?.Invoke("closed");
            }
        }

        public void Dispose()
        {
            _cts.Cancel();
            _cts.Dispose();
            _socket.Dispose();
            GC.SuppressFinalize(this);
        }
    }
}
