namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// 兼容旧协议的异或加密器。
    /// </summary>
    public sealed class Encry
    {
        private readonly string _encryKey;

        public Encry(string encryKey)
        {
            _encryKey = encryKey;
        }

        public void DoEncry(byte[] data, int startIndex = 0)
        {
            if (data.Length == 0 || string.IsNullOrEmpty(_encryKey) || startIndex >= data.Length)
            {
                return;
            }

            int keyId = 0;
            for (int index = startIndex; index < data.Length; index++)
            {
                data[index] ^= (byte)_encryKey[keyId];
                keyId++;
                if (keyId >= _encryKey.Length)
                {
                    keyId = 0;
                }
            }
        }
    }
}
