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
    }catch {throw 'LAB_QUALIFIED_EXPORT_REJECTED'}
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
