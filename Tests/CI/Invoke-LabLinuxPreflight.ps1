# Dedicated read-only Linux consumer. Feature/deployment adapters retain their
# own gates; this command creates no SQL objects and never changes TLS policy.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][byte[]]$ExportBytes,
    [Parameter(Mandatory)][object]$TlsContext
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not$IsLinux){throw 'LAB_LINUX_PEER_REQUIRED'}
. (Join-Path $PSScriptRoot 'LabLinuxQualifiedContract.ps1')
$copy=[byte[]]$ExportBytes.Clone();$process=$null;$started=$false;$info=$null
try{
    $snapshot=Read-LabQualifiedSnapshot $copy $TlsContext SYSTEM_DATA_SQLCLIENT
    $entry=$snapshot.Contract.environments[0];$q=$snapshot.Qualification
    if($entry.host-cne'localhost'-or$entry.port-ne1433-or$entry.database-cne'master'-or$entry.username-cne'sa'){throw 'LAB_LINUX_ENDPOINT_INVALID'}
    $assembly=[Data.SqlClient.SqlConnection].Assembly.Location
    if($assembly-cne'/opt/tls-client/pwsh/System.Data.SqlClient.dll'-or
        (Get-FileHash -LiteralPath $assembly).Hash.ToLowerInvariant()-cne$q.SqlClientSha256){throw 'LAB_LINUX_SQLCLIENT_CHANGED'}
    $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($entry.connectionString)
    if(-not$builder.Encrypt-or$builder.TrustServerCertificate-or$builder.DataSource-cne'tcp:localhost,1433'-or
        $builder.UserID-cne'sa'-or$builder.Password-cne$entry.password){throw 'LAB_LINUX_CONNECTION_INVALID'}
    $builder.Pooling=$false;$builder.ConnectRetryCount=0;$builder.ConnectTimeout=10
    $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$builder.Clear()
    try{
        Assert-LabQualifiedConnectWindow $snapshot
        $connection.Open()
        $command=$connection.CreateCommand();$command.CommandTimeout=10
        $command.CommandText="SET NOCOUNT ON; SELECT CONVERT(varchar(32),SERVERPROPERTY('ProductVersion')),encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID"
        try{
            $reader=$command.ExecuteReader()
            try{if(-not$reader.Read()-or$reader.GetString(0)-cne$q.SqlBuild-or$reader.GetString(1)-cne'TRUE'-or$reader.Read()){throw 'LAB_LINUX_SQLCLIENT_RESULT'}}finally{$reader.Dispose()}
        }finally{$command.Dispose()}
    }finally{$connection.Dispose()}
    $snapshot=Read-LabQualifiedSnapshot $copy $TlsContext ODBC_SQLCMD
    $q=$snapshot.Qualification
    $sqlcmd='/opt/mssql-tools18/bin/sqlcmd'
    if((Get-FileHash -LiteralPath $sqlcmd).Hash.ToLowerInvariant()-cne$q.SqlcmdSha256){throw 'LAB_LINUX_SQLCMD_CHANGED'}
    $info=[Diagnostics.ProcessStartInfo]::new($sqlcmd);$info.UseShellExecute=$false
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    foreach($name in @($info.Environment.Keys)){if($name.StartsWith('SQLCMD',[StringComparison]::OrdinalIgnoreCase)){$null=$info.Environment.Remove($name)}}
    $info.Environment['SQLCMDPASSWORD']=$entry.password
    foreach($arg in @('-S','tcp:localhost,1433','-U','sa','-N','-b','-l','10','-h','-1','-W','-s','|','-Q',"SET NOCOUNT ON; WAITFOR DELAY '00:00:03'; SELECT CONVERT(varchar(32),SERVERPROPERTY('ProductVersion')),encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID;")){$info.ArgumentList.Add($arg)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$info
    Assert-LabQualifiedConnectWindow $snapshot
    $started=$process.Start();$null=$info.Environment.Remove('SQLCMDPASSWORD')
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$clock=[Diagnostics.Stopwatch]::StartNew();$driver=$null
    while(-not$process.WaitForExit(50)){
        if($clock.Elapsed.TotalSeconds-ge25){throw 'LAB_LINUX_SQLCMD_TIMEOUT'}
        if(-not$driver){
            $paths=@(Get-Content -LiteralPath ('/proc/'+$process.Id+'/maps')|ForEach-Object{if($_-match'(/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18[^\s]+)$'){$Matches[1]}}|Sort-Object -Unique)
            if($paths.Count-eq1){$driver=$paths[0]}elseif($paths.Count-gt1){throw 'LAB_LINUX_ODBC_AMBIGUOUS'}
        }
    }
    if($process.ExitCode-ne0-or$stdout.GetAwaiter().GetResult().Trim()-cne($q.SqlBuild+'|TRUE')-or$stderr.GetAwaiter().GetResult().Trim()-or-not$driver-or
        (Get-FileHash -LiteralPath $driver).Hash.ToLowerInvariant()-cne$q.LoadedOdbcSha256-or
        (Get-Item -LiteralPath $driver).Length-ne$q.LoadedOdbcBytes-or
        (Get-FileHash -LiteralPath $sqlcmd).Hash.ToLowerInvariant()-cne$q.SqlcmdSha256){throw 'LAB_LINUX_ODBC_RESULT'}
    [pscustomobject]@{ContractVersion='Toolbelt.LinuxLabPreflight/0.1';Status='PASS';ClientChecks=2;SqlBuild=$q.SqlBuild;SqlClient='PASS';Odbc='PASS';Encrypt=$true;TrustServerCertificate=$false}
}finally{
    if($info){$null=$info.Environment.Remove('SQLCMDPASSWORD')}
    if($started-and-not$process.HasExited){$process.Kill($true);if(-not$process.WaitForExit(5000)){throw 'LAB_LINUX_CHILD_TERMINATION_UNCONFIRMED'}}
    if($process){$process.Dispose()}
    [Array]::Clear($copy,0,$copy.Length)
}
