using System;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// 网络层轻量加解密与解压服务。
    /// </summary>
    public sealed class NetCryptoService
    {
        private readonly string _encodeKey;

        public NetCryptoService(string encodeKey = "537b9b7a-a18c-11ea-afae-6c92bf62e626")
        {
            _encodeKey = encodeKey;
        }

        public string SpecialXorDecode(string input)
        {
            if (string.IsNullOrEmpty(input))
            {
                return string.Empty;
            }

            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(input);
            }
            catch
            {
                return input;
            }

            byte[] keyBytes = Encoding.UTF8.GetBytes(_encodeKey);
            if (keyBytes.Length == 0)
            {
                return input;
            }

            for (int index = 0; index < bytes.Length; index++)
            {
                bytes[index] ^= keyBytes[index % keyBytes.Length];
            }
            return Encoding.UTF8.GetString(bytes);
        }

        public byte[] TryUnzip(byte[] rawBytes)
        {
            if (rawBytes.Length < 2)
            {
                return Array.Empty<byte>();
            }

            try
            {
                // gzip: 1F 8B
                bool isGzip = rawBytes[0] == 0x1f && rawBytes[1] == 0x8b;
                if (isGzip)
                {
                    using MemoryStream sourceStream = new(rawBytes);
                    using GZipStream gzipStream = new(sourceStream, CompressionMode.Decompress);
                    using MemoryStream targetStream = new();
                    gzipStream.CopyTo(targetStream);
                    return targetStream.ToArray();
                }

                // zlib(deflate): 常见头 78 01 / 78 9C / 78 DA
                bool isZlib = rawBytes[0] == 0x78 && (rawBytes[1] == 0x01 || rawBytes[1] == 0x5E || rawBytes[1] == 0x9C || rawBytes[1] == 0xDA);
                if (isZlib)
                {
                    using MemoryStream sourceStream = new(rawBytes);
                    using ZLibStream zlibStream = new(sourceStream, CompressionMode.Decompress);
                    using MemoryStream targetStream = new();
                    zlibStream.CopyTo(targetStream);
                    return targetStream.ToArray();
                }

                return Array.Empty<byte>();
            }
            catch
            {
                return Array.Empty<byte>();
            }
        }
    }
}
