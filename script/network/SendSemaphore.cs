using System.Threading;

namespace Sanhai.NetWork.Network
{
    /// <summary>
    /// 与旧网络代码兼容的资源信号量。
    /// </summary>
    public sealed class SendSemaphore
    {
        private int _resource;
        private readonly object _resourceObj = new();
        private readonly object _waitObj = new();

        public void WaitResource()
        {
            WaitResource(1);
        }

        public void WaitResource(int count)
        {
            while (true)
            {
                lock (_resourceObj)
                {
                    if (_resource >= count)
                    {
                        _resource -= count;
                        return;
                    }
                }

                lock (_waitObj)
                {
                    Monitor.Wait(_waitObj);
                }
            }
        }

        public void ProduceResource()
        {
            ProduceResource(1);
        }

        public void ProduceResource(int count)
        {
            lock (_resourceObj)
            {
                _resource += count;
            }

            lock (_waitObj)
            {
                Monitor.Pulse(_waitObj);
            }
        }
    }
}
