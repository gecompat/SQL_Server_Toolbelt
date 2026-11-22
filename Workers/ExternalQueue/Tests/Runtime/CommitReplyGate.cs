using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

// Single owned test connection. The gate never parses or records SQL/TLS
// traffic. The orchestrator arms it after observing the commit boundary.
public sealed class CommitReplyGate : IDisposable
{
    private readonly TcpListener listener = new TcpListener(IPAddress.Loopback, 0);
    private readonly CancellationTokenSource stopping = new CancellationTokenSource();
    private readonly TaskCompletionSource<bool> withheld =
        new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
    private readonly Task completion;
    private int armed;
    private int disposed;

    public int Port { get; }
    public Task ReplyWithheld => withheld.Task;
    public Task Completion => completion;

    public CommitReplyGate(int upstreamPort)
    {
        if (upstreamPort < 1 || upstreamPort > 65535)
            throw new ArgumentOutOfRangeException(nameof(upstreamPort));
        listener.Start(1);
        Port = ((IPEndPoint)listener.LocalEndpoint).Port;
        completion = Relay(upstreamPort, stopping.Token);
    }

    public void WithholdReply()
    {
        if (stopping.IsCancellationRequested || Interlocked.Exchange(ref armed, 1) != 0)
            throw new InvalidOperationException("Commit reply gate can only be armed once.");
    }

    private async Task Relay(int upstreamPort, CancellationToken cancellation)
    {
        using (TcpClient client = await listener.AcceptTcpClientAsync(cancellation).ConfigureAwait(false))
        using (TcpClient server = new TcpClient(AddressFamily.InterNetwork))
        using (CancellationTokenSource lanes = CancellationTokenSource.CreateLinkedTokenSource(cancellation))
        {
            listener.Stop();
            await server.ConnectAsync(IPAddress.Loopback, upstreamPort, cancellation).ConfigureAwait(false);
            Task request = client.GetStream().CopyToAsync(server.GetStream(), lanes.Token);
            Task response = RelayReply(server.GetStream(), client.GetStream(), lanes.Token);
            await Task.WhenAny(request, response).ConfigureAwait(false);
            lanes.Cancel();
            try
            {
                await Task.WhenAll(request, response).ConfigureAwait(false);
            }
            catch (OperationCanceledException) when (lanes.IsCancellationRequested) { }
            catch (IOException) when (cancellation.IsCancellationRequested) { }
        }
    }

    private async Task RelayReply(NetworkStream server, NetworkStream client, CancellationToken cancellation)
    {
        byte[] buffer = new byte[8192];
        int count;
        while ((count = await server.ReadAsync(buffer.AsMemory(), cancellation).ConfigureAwait(false)) != 0)
        {
            if (Volatile.Read(ref armed) != 0)
            {
                withheld.TrySetResult(true);
                await Task.Delay(Timeout.Infinite, cancellation).ConfigureAwait(false);
            }
            await client.WriteAsync(buffer.AsMemory(0, count), cancellation).ConfigureAwait(false);
        }
    }

    public void Abort() => stopping.Cancel();

    public void Dispose()
    {
        if (Interlocked.Exchange(ref disposed, 1) != 0)
            return;
        try
        {
            Abort();
            try { completion.WaitAsync(TimeSpan.FromSeconds(5)).GetAwaiter().GetResult(); }
            catch (OperationCanceledException) when (stopping.IsCancellationRequested) { }
        }
        finally
        {
            listener.Stop();
            stopping.Dispose();
        }
    }
}
