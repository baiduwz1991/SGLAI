namespace KcpCSharp
{
    // Godot 兼容版：去掉 UnityEngine 依赖，保持 KCP 接口不变。
    public abstract class Output
    {
        public abstract void output(ByteBuf msg, Kcp kcp, object user);
    }
}
