#requires -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Runtime/CommitReplyGate.cs')

function Read-TestByte($Stream) {
    $buffer=[byte[]]::new(1)
    $count=$Stream.ReadAsync($buffer,0,1).WaitAsync([timespan]::FromSeconds(5)).GetAwaiter().GetResult()
    if ($count -eq 0) { return -1 }
    return [int]$buffer[0]
}

$upstream=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
$gate=$null;$client=$null;$server=$null
try {
    $upstream.Start()
    $gate=[CommitReplyGate]::new($upstream.LocalEndpoint.Port)
    $client=[Net.Sockets.TcpClient]::new([Net.Sockets.AddressFamily]::InterNetwork)
    [void]$client.ConnectAsync([Net.IPAddress]::Loopback,$gate.Port).WaitAsync([timespan]::FromSeconds(5)).GetAwaiter().GetResult()
    $server=$upstream.AcceptTcpClientAsync().WaitAsync([timespan]::FromSeconds(5)).GetAwaiter().GetResult()
    $clientStream=$client.GetStream();$serverStream=$server.GetStream()
    $clientStream.WriteByte(11)
    if ((Read-TestByte $serverStream) -ne 11) { throw 'COMMIT_GATE_REQUEST' }
    $serverStream.WriteByte(12)
    if ((Read-TestByte $clientStream) -ne 12) { throw 'COMMIT_GATE_RESPONSE' }

    $gate.WithholdReply()
    $clientStream.WriteByte(21)
    if ((Read-TestByte $serverStream) -ne 21) { throw 'COMMIT_GATE_REQUEST_NOT_FORWARDED' }
    $serverStream.WriteByte(22)
    [void]$gate.ReplyWithheld.WaitAsync([timespan]::FromSeconds(5)).GetAwaiter().GetResult()
    $gate.Abort()
    [void]$gate.Completion.WaitAsync([timespan]::FromSeconds(5)).GetAwaiter().GetResult()
    if ((Read-TestByte $clientStream) -ne -1) { throw 'COMMIT_GATE_RESPONSE_LEAK' }
    if ((Read-TestByte $serverStream) -ne -1) { throw 'COMMIT_GATE_UPSTREAM_STILL_OPEN' }
} finally {
    if ($null -ne $client) { $client.Dispose() }
    if ($null -ne $server) { $server.Dispose() }
    if ($null -ne $gate) { $gate.Dispose() }
    $upstream.Stop()
}
'COMMIT_REPLY_GATE_CONTRACT_PASS'
