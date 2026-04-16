using Godot;
using Godot.Collections;
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Text;
using System.Threading.Tasks;

namespace Sanhai.NetWork.Network
{
    // Godot 兼容版 HttpManager：保留旧命名，移除 Unity 协程依赖。
    [GlobalClass]
    public partial class HttpManager : Node
    {
        [Signal]
        public delegate void RequestCompletedEventHandler(int requestId, Dictionary result);

        private readonly NetCryptoService _cryptoService;
        private readonly System.Net.Http.HttpClient _httpClient = new()
        {
            Timeout = TimeSpan.FromSeconds(10),
        };
        private readonly ConcurrentQueue<(int requestId, Dictionary result)> _pendingSignalQueue = new();

        public HttpManager()
        {
            _cryptoService = new NetCryptoService();
        }

        public override void _Ready()
        {
            SetProcess(true);
        }

        public override void _Process(double delta)
        {
            while (_pendingSignalQueue.TryDequeue(out var item))
            {
                EmitSignal(SignalName.RequestCompleted, item.requestId, item.result);
            }
        }

        /// <summary>
        /// 与旧 Lua 调用签名兼容：完成后回调原始文本。
        /// </summary>
        public async void Request(
            int openType,
            string url,
            Action<string> callback,
            bool unzip = false,
            bool useDecrypt = false,
            string param = "")
        {
            Dictionary result = await RequestAsync(openType, url, unzip, useDecrypt, param);
            string raw = result.TryGetValue("raw_text", out Variant rawText) ? rawText.AsString() : string.Empty;
            callback.Invoke(raw);
        }

        public async Task<Dictionary> RequestAsync(
            int openType,
            string url,
            bool unzip,
            bool useDecrypt,
            string param)
        {
            HttpMethod method = openType == 1 ? HttpMethod.Post : HttpMethod.Get;
            string requestUrl = method == HttpMethod.Get && !string.IsNullOrWhiteSpace(param)
                ? $"{url}?{param}"
                : url;

            HttpRequestMessage request = new(method, requestUrl);
            if (method == HttpMethod.Post)
            {
                request.Content = new StringContent(param ?? string.Empty, Encoding.UTF8, "application/x-www-form-urlencoded");
            }

            Dictionary result = new Dictionary();
            try
            {
                HttpResponseMessage response = await _httpClient.SendAsync(request);
                byte[] rawBytes = await response.Content.ReadAsByteArrayAsync();
                string text = Encoding.UTF8.GetString(rawBytes);

                if (useDecrypt)
                {
                    try
                    {
                        text = _cryptoService.SpecialXorDecode(text);
                    }
                    catch
                    {
                        // 解密失败保留原文，交给上层判定。
                    }
                }

                // unzip 分支保留接口语义；当前后端主流程不依赖该压缩格式。
                if (unzip)
                {
                    byte[] unzipBytes = _cryptoService.TryUnzip(rawBytes);
                    if (unzipBytes.Length > 0)
                    {
                        text = Encoding.UTF8.GetString(unzipBytes);
                    }
                }

                result["success"] = response.IsSuccessStatusCode;
                result["http_code"] = (int)response.StatusCode;
                result["raw_text"] = text;
                MergeDecodedJson(text, result);
            }
            catch (Exception ex)
            {
                result["success"] = false;
                result["error_message"] = ex.Message;
            }

            return result;
        }

        public void RequestAsyncById(
            int requestId,
            int openType,
            string url,
            bool unzip,
            bool useDecrypt,
            string param)
        {
            _ = RequestAndEmitAsync(requestId, openType, url, unzip, useDecrypt, param);
        }

        private async Task RequestAndEmitAsync(
            int requestId,
            int openType,
            string url,
            bool unzip,
            bool useDecrypt,
            string param)
        {
            Dictionary result = await RequestAsync(openType, url, unzip, useDecrypt, param);
            _pendingSignalQueue.Enqueue((requestId, result));
        }

        private static void MergeDecodedJson(string text, Dictionary result)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return;
            }

            Variant parsed = Json.ParseString(text);
            if (parsed.VariantType != Variant.Type.Dictionary)
            {
                return;
            }

            Dictionary parsedDict = (Dictionary)parsed;
            foreach (KeyValuePair<Variant, Variant> entry in parsedDict)
            {
                result[entry.Key] = entry.Value;
            }
        }
    }
}
