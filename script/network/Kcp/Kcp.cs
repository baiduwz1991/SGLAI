namespace KcpCSharp
{
    /// <summary>
    /// 迁移阶段 KCP 占位对象，保证上层接口可编译。
    /// </summary>
    public sealed class Kcp
    {
        public uint Conv { get; }

        public Kcp(uint conv)
        {
            Conv = conv;
        }
    }
}
