# Explicit isolated Linux consumer only; legacy shared Windows reader remains byte-identical.
# Gemeinsame V2-Verbrauchergrenze. Labcode wird ausdruecklich vom Caller
# ausgewaehlt, niemals aus einem Export oder einer Schemaangabe abgeleitet.
function Get-LabContractByteHash {
    param([byte[]]$Bytes)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Get-LabQualifiedClientHost {
    if($IsWindows){return 'windows'}
    if($IsLinux){return 'linux'}
    return 'unsupported'
}

function Get-LabQualifiedContextValue {
    param([object]$Context,[string]$Name)
    if($Context -is [Collections.IDictionary]) {
        if($Context.Contains($Name)){return ,($Context[$Name])}
        return $null
    }
    $property=$Context.PSObject.Properties[$Name]
    if($null -eq $property){return $null}
    if($property -isnot [Management.Automation.PSNoteProperty]){throw 'LAB_QUALIFIED_CONTEXT_REQUIRED'}
    return ,($property.Value)
}

function Get-LabQualifiedReaderArguments {
    param([object]$TlsContext,[string]$HostPlatform,[string]$ClientStack='SYSTEM_DATA_SQLCLIENT')
    if($null -eq $TlsContext){throw 'LAB_QUALIFIED_CONTEXT_REQUIRED'}
    $arguments=@{}
    foreach($name in @('ModuleFile','StateRoot','RunId','InstanceId')){
        $value=Get-LabQualifiedContextValue $TlsContext $name
        if($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)){throw 'LAB_QUALIFIED_CONTEXT_REQUIRED'}
        if($name -cne 'ModuleFile'){$arguments[$name]=$value}
    }
    if($ClientStack -cnotin @('SYSTEM_DATA_SQLCLIENT','ODBC_SQLCMD') -or $HostPlatform -cnotin @('windows','linux')){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
    $session=Get-LabQualifiedContextValue $TlsContext 'LinuxSessionRef'
    if($HostPlatform -ceq 'linux'){
        $client=Get-LabQualifiedContextValue $TlsContext 'LinuxClientRef'
        $digest=Get-LabQualifiedContextValue $TlsContext 'LinuxClientContextDigest'
        if($session -isnot [string] -or $session -cnotmatch '\A[0-9a-f]{64}\z' -or
            $client -isnot [string] -or $client -cnotmatch '\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z' -or
            $client -ceq '00000000-0000-0000-0000-000000000000' -or
            $digest -isnot [string] -or $digest -cnotmatch '\A[0-9a-f]{64}\z'){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
        $arguments.LinuxSessionRef=$session
        $arguments.LinuxClientStack=$ClientStack
    }elseif($null -ne $session){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
    return $arguments
}

function Get-LabQualifiedLinuxReaderFailureCode {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)
    $safeCodes=@(
        'TLS_LINUX_VERIFIER_EXCHANGE_REJECTED','TLS_LINUX_VERIFIER_REPLY_REJECTED',
        'TLS_LINUX_VERIFIER_REPLY_FRAME_REJECTED','TLS_LINUX_VERIFIER_REPLY_SCHEMA_REJECTED',
        'TLS_LINUX_VERIFIER_REPLY_BINDING_REJECTED','TLS_LINUX_VERIFIER_REPLY_TIME_REJECTED',
        'TLS_LINUX_VERIFIER_REPLY_WINDOW_REJECTED','TLS_LINUX_VERIFIER_REPLY_DEADLINE_EXCEEDED',
        'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_CREATE','TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_START',
        'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_LAYOUT','TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_TRUST_WRITE',
        'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_OBSERVATION','TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_NAMESPACE_CHECK',
        'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_QUALIFICATION',
        'TLS_LINUX_EXPORT_DOCUMENT_INVALID',
        'TLS_LINUX_EXPORT_PAYLOAD_INVALID','TLS_LINUX_EXPORT_BINDING_INVALID',
        'TLS_LINUX_PEER_REJECTED'
    )
    $exception=$ErrorRecord.Exception
    while($null-ne$exception){
        $message=[string]$exception.Message
        if($safeCodes-ccontains$message){return $message}
        $exception=$exception.InnerException
    }
    return 'LAB_QUALIFIED_EXPORT_REJECTED'
}

function Get-LabLinuxSqlClientTimeoutFailureCode {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord,[ValidateSet('OPEN','QUERY')][string]$Stage)
    $code='TLS_SQLCLIENT_'+$Stage+'_TIMEOUT'
    $exception=$ErrorRecord.Exception
    while($null-ne$exception){
        if($exception -is [TimeoutException]){return $code}
        if($exception.GetType().FullName -ceq 'System.Data.SqlClient.SqlException'){
            $numberProperty=$exception.GetType().GetProperty('Number',[Reflection.BindingFlags]'Instance,Public')
            if($numberProperty){
                try{if([int]$numberProperty.GetValue($exception)-eq-2){return $code}}catch{}
            }
        }
        $exception=$exception.InnerException
    }
    return $null
}

function Get-LabLinuxSqlClientFailureCode {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord,[ValidateSet('CONSTRUCT','OPEN','QUERY','CLEANUP')][string]$Stage)
    if($Stage -in @('OPEN','QUERY')){
        $timeout=Get-LabLinuxSqlClientTimeoutFailureCode $ErrorRecord $Stage
        if($timeout){return $timeout}
    }
    $exception=$ErrorRecord.Exception;$category='UNCLASSIFIED'
    while($null-ne$exception){
        if($exception.Message-ceq'LAB_LINUX_SQLCLIENT_RESULT'){return 'LAB_LINUX_SQLCLIENT_RESULT'}
        $type=$exception.GetType().FullName
        if($type-ceq'System.PlatformNotSupportedException'){return ('TLS_SQLCLIENT_'+$Stage+'_PLATFORM_UNSUPPORTED')}
        if($type-cin@('System.TypeLoadException','System.IO.FileNotFoundException','System.IO.FileLoadException')){return ('TLS_SQLCLIENT_'+$Stage+'_ASSEMBLY_UNAVAILABLE')}
        if($type-ceq'System.Security.Authentication.AuthenticationException'){return ('TLS_SQLCLIENT_'+$Stage+'_AUTHENTICATION')}
        if($type-ceq'System.Net.Sockets.SocketException'){return ('TLS_SQLCLIENT_'+$Stage+'_NETWORK')}
        if($Stage-ceq'CONSTRUCT' -and ($exception -is [ArgumentException] -or $exception -is [FormatException])){return 'TLS_SQLCLIENT_CONSTRUCT_INVALID_ARGUMENT'}
        if($type-ceq'System.Data.SqlClient.SqlException'){
            $numberProperty=$exception.GetType().GetProperty('Number',[Reflection.BindingFlags]'Instance,Public')
            if($numberProperty){try{if([int]$numberProperty.GetValue($exception)-eq-2){return ('TLS_SQLCLIENT_'+$Stage+'_TIMEOUT')}}catch{}}
            $category='SQL'
        }
        if($type-ceq'System.TimeoutException'){return ('TLS_SQLCLIENT_'+$Stage+'_TIMEOUT')}
        $exception=$exception.InnerException
    }
    return ('TLS_SQLCLIENT_'+$Stage+'_'+$category)
}

function Invoke-LabLinuxSqlClientQualification {
    param([Parameter(Mandatory)][object]$Builder,[Parameter(Mandatory)][object]$Snapshot,[Parameter(Mandatory)][string]$ExpectedSqlBuild,[Parameter(Mandatory)][scriptblock]$ConnectionFactory)
    $failureCode=$null;$connection=$null;$command=$null;$reader=$null;$connectionString=$null
    try{
        $connectionString=$Builder.ConnectionString
        try{$connection=& $ConnectionFactory $connectionString}catch{$failureCode=Get-LabLinuxSqlClientFailureCode $_ CONSTRUCT}
        finally{$connectionString=$null}
        if(-not$failureCode){
            try{Assert-LabQualifiedConnectWindow $Snapshot}catch{$failureCode='LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'}
            if(-not$failureCode){try{$connection.Open()}catch{$failureCode=Get-LabLinuxSqlClientFailureCode $_ OPEN}}
        }
        if(-not$failureCode){
            try{
                $command=$connection.CreateCommand();$command.CommandTimeout=10
                $command.CommandText="SET NOCOUNT ON; SELECT CONVERT(varchar(32),SERVERPROPERTY('ProductVersion')),encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID"
                $reader=$command.ExecuteReader()
                if(-not$reader.Read()-or$reader.GetString(0)-cne$ExpectedSqlBuild-or$reader.GetString(1)-cne'TRUE'-or$reader.Read()){$failureCode='LAB_LINUX_SQLCLIENT_RESULT'}
            }catch{$failureCode=Get-LabLinuxSqlClientFailureCode $_ QUERY}
            finally{
                if($reader){try{$reader.Dispose()}catch{if(-not$failureCode){$failureCode=Get-LabLinuxSqlClientFailureCode $_ CLEANUP}}}
                if($command){try{$command.Dispose()}catch{if(-not$failureCode){$failureCode=Get-LabLinuxSqlClientFailureCode $_ CLEANUP}}}
            }
        }
    }finally{if($connection){try{$connection.Dispose()}catch{if(-not$failureCode){$failureCode=Get-LabLinuxSqlClientFailureCode $_ CLEANUP}}}}
    return $failureCode
}

function Read-LabQualifiedSnapshot {
    param([byte[]]$Bytes,[object]$TlsContext,[string]$ClientStack='SYSTEM_DATA_SQLCLIENT')
    $platform=Get-LabQualifiedClientHost
    if($platform-cne'linux'){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
    $arguments=Get-LabQualifiedReaderArguments $TlsContext $platform $ClientStack
    if($PSVersionTable.PSVersion -lt [version]'7.5'){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
    $moduleFile=Get-LabQualifiedContextValue $TlsContext 'ModuleFile'
    if($null -eq $Bytes -or $Bytes.Length -lt 1 -or $Bytes.Length -gt 65536){throw 'LAB_QUALIFIED_BYTES_INVALID'}
    try {
        if(-not [IO.Path]::IsPathRooted($moduleFile) -or -not (Test-Path -LiteralPath $moduleFile -PathType Leaf)){throw 'LAB_MODULE_REQUIRED'}
        $module=Import-Module -Name $moduleFile -PassThru -ErrorAction Stop
        $reader=$module.ExportedCommands['Read-SqlServerLabQualifiedTestEnvironment']
        if($null -eq $reader){throw 'LAB_MODULE_READER_REQUIRED'}
        $snapshot=& $reader -ExportBytes $Bytes @arguments
        if($platform -ceq 'linux'){
            $q=$snapshot.Qualification
            foreach($name in @('ClientPlatform','ClientRef','ClientContextDigest')){
                if($q.$name -isnot [string]){throw 'LAB_SNAPSHOT_INVALID'}
            }
            if($q.ClientPlatform -cne 'linux' -or
                $q.ClientRef -cne (Get-LabQualifiedContextValue $TlsContext 'LinuxClientRef') -or
                $q.ClientContextDigest -cne (Get-LabQualifiedContextValue $TlsContext 'LinuxClientContextDigest')){throw 'LAB_SNAPSHOT_INVALID'}
        }
        if($snapshot.ContractVersion -cne 'SqlServerLab.QualifiedTestEnvironmentSnapshot/0.1' -or
            $snapshot.ExportSha256 -cne (Get-LabContractByteHash $Bytes) -or $snapshot.ExportSha256 -cne (Get-LabContractByteHash $snapshot.ExportBytes) -or $snapshot.Contract.contractVersion -cne 'SqlServerLab.TestEnvironment/2.0' -or
            $snapshot.Contract.environments.Count -ne 1){throw 'LAB_SNAPSHOT_INVALID'}
        return $snapshot
    }catch {throw (Get-LabQualifiedLinuxReaderFailureCode $_)}
}

function Assert-LabQualifiedConnectWindow {
    param([object]$Snapshot)
    $platform=$Snapshot.Qualification.PSObject.Properties['ClientPlatform']
    if($platform){
        if($platform.Value -isnot [string] -or $platform.Value -cnotin @('windows','linux')){throw 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'}
        if($platform.Value -ceq 'linux'){
            $property=$Snapshot.PSObject.Properties['LinuxConnectWindow']
            if($null -eq $property -or $property.Value -isnot [pscustomobject]){throw 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'}
            $window=$property.Value
            if($window.ContractVersion -isnot [string] -or $window.ContractVersion -cne 'SqlServerLab.LinuxConnectWindow/0.1' -or
                ($window.RemainingAtApprovalMilliseconds -isnot [int] -and $window.RemainingAtApprovalMilliseconds -isnot [long]) -or
                $window.RemainingAtApprovalMilliseconds -lt 35000 -or $window.RemainingAtApprovalMilliseconds -gt 900000 -or
                $window.Clock -isnot [Diagnostics.Stopwatch] -or -not $window.Clock.IsRunning -or
                $window.RemainingAtApprovalMilliseconds-[Math]::Ceiling($window.Clock.Elapsed.TotalMilliseconds) -lt 30000){throw 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'}
            return
        }
    }
    # Eine Pruefung verlaengert die signierte Frist nicht. Der Consumer verlangt
    # vor dem Start einer Verbindung noch 30 Sekunden fuer den 15-s-Login.
    $end=[DateTimeOffset]::Parse($Snapshot.Qualification.ExpiresAt,[Globalization.CultureInfo]::InvariantCulture)
    if(($end-[DateTimeOffset]::UtcNow).TotalSeconds -lt 30){throw 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'}
}
