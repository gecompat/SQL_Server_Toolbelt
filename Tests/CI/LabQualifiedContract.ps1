# Gemeinsame V2-Verbrauchergrenze. Labcode wird ausdruecklich vom Caller
# ausgewaehlt, niemals aus einem Export oder einer Schemaangabe abgeleitet.
function Get-LabContractByteHash {
    param([byte[]]$Bytes)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Read-LabQualifiedSnapshot {
    param([byte[]]$Bytes,[object]$TlsContext)
    if($null -eq $TlsContext){throw 'LAB_QUALIFIED_CONTEXT_REQUIRED'}
    foreach($name in @('ModuleFile','StateRoot','RunId','InstanceId')){
        if($TlsContext.$name -isnot [string] -or [string]::IsNullOrWhiteSpace($TlsContext.$name)){throw 'LAB_QUALIFIED_CONTEXT_REQUIRED'}
    }
    if(-not $IsWindows -or $PSVersionTable.PSVersion -lt [version]'7.5'){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
    if($null -eq $Bytes -or $Bytes.Length -lt 1 -or $Bytes.Length -gt 65536){throw 'LAB_QUALIFIED_BYTES_INVALID'}
    try {
        if(-not [IO.Path]::IsPathRooted($TlsContext.ModuleFile) -or -not (Test-Path -LiteralPath $TlsContext.ModuleFile -PathType Leaf)){throw 'LAB_MODULE_REQUIRED'}
        $module=Import-Module -Name $TlsContext.ModuleFile -PassThru -ErrorAction Stop
        $reader=$module.ExportedCommands['Read-SqlServerLabQualifiedTestEnvironment']
        if($null -eq $reader){throw 'LAB_MODULE_READER_REQUIRED'}
        $snapshot=& $reader -ExportBytes $Bytes -StateRoot $TlsContext.StateRoot -RunId $TlsContext.RunId -InstanceId $TlsContext.InstanceId
        if($snapshot.ContractVersion -cne 'SqlServerLab.QualifiedTestEnvironmentSnapshot/0.1' -or
            $snapshot.ExportSha256 -cne (Get-LabContractByteHash $Bytes) -or $snapshot.ExportSha256 -cne (Get-LabContractByteHash $snapshot.ExportBytes) -or $snapshot.Contract.contractVersion -cne 'SqlServerLab.TestEnvironment/2.0' -or
            $snapshot.Contract.environments.Count -ne 1){throw 'LAB_SNAPSHOT_INVALID'}
        return $snapshot
    }catch {throw 'LAB_QUALIFIED_EXPORT_REJECTED'}
}

function Assert-LabQualifiedConnectWindow {
    param([object]$Snapshot)
    # Eine Pruefung verlaengert die signierte Frist nicht. Der Consumer verlangt
    # vor dem Start einer Verbindung noch 30 Sekunden fuer den 15-s-Login.
    $end=[DateTimeOffset]::Parse($Snapshot.Qualification.ExpiresAt,[Globalization.CultureInfo]::InvariantCulture)
    if(($end-[DateTimeOffset]::UtcNow).TotalSeconds -lt 30){throw 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'}
}

function Assert-LabQualifiedPrivateStream {
    param([IO.FileStream]$Stream)
    if(-not $IsWindows){throw 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED'}
    $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $acl=[IO.FileSystemAclExtensions]::GetAccessControl($Stream)
    $rules=@($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    if(-not $acl.AreAccessRulesProtected -or $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -cne $sid -or $rules.Count -ne 2){throw 'LAB_QUALIFIED_FILE_ACL_INVALID'}
    foreach($rule in $rules){
        if($rule.IsInherited -or $rule.AccessControlType -ne 'Allow' -or $rule.FileSystemRights -ne 'FullControl' -or
            $rule.IdentityReference.Value -notin @($sid,'S-1-5-18') -or -not $seen.Add($rule.IdentityReference.Value)){throw 'LAB_QUALIFIED_FILE_ACL_INVALID'}
    }
}

function Read-LabContractStreamBytes {
    param([IO.FileStream]$Stream,[int]$MaximumBytes)
    if($Stream.Length -lt 1 -or $Stream.Length -gt $MaximumBytes){throw 'LAB_CONTRACT_SIZE_INVALID'}
    $Stream.Position=0;$bytes=[byte[]]::new([int]$Stream.Length);$offset=0
    while($offset -lt $bytes.Length){$count=$Stream.Read($bytes,$offset,$bytes.Length-$offset);if($count -eq 0){throw 'LAB_CONTRACT_READ_FAILED'};$offset+=$count}
    if($Stream.ReadByte() -ne -1){throw 'LAB_CONTRACT_READ_CHANGED'}
    return ,$bytes
}

function Get-LabQualifiedPrivateSecurity {
    param([switch]$Directory)
    $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl=if($Directory){[Security.AccessControl.DirectorySecurity]::new()}else{[Security.AccessControl.FileSecurity]::new()}
    $acl.SetOwner($sid);$acl.SetAccessRuleProtection($true,$false)
    foreach($identity in @($sid,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'))){
        $rule=if($Directory){[Security.AccessControl.FileSystemAccessRule]::new($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow')}else{[Security.AccessControl.FileSystemAccessRule]::new($identity,'FullControl','Allow')}
        $null=$acl.AddAccessRule($rule)
    }
    return $acl
}

function Open-LabQualifiedConsumerContext {
    param([object]$Snapshot,[object]$TlsContext,[string]$SqlcmdPath)
    $current=Read-LabQualifiedSnapshot $Snapshot.ExportBytes $TlsContext
    if((Get-FileHash -LiteralPath $SqlcmdPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $current.Qualification.SqlcmdSha256){throw 'LAB_QUALIFIED_SQLCMD_CHANGED'}
    $directory=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-tls-context-'+[guid]::NewGuid().ToString('N'))
    if(Test-Path -LiteralPath $directory){throw 'LAB_CONTEXT_ALREADY_EXISTS'}
    [IO.FileSystemAclExtensions]::Create([IO.DirectoryInfo]::new($directory),(Get-LabQualifiedPrivateSecurity -Directory))
    $path=Join-Path $directory 'context.json'
    $body=[ordered]@{ContractVersion='Toolbelt.QualifiedLabContext/0.1';ModuleFile=$TlsContext.ModuleFile;StateRoot=$TlsContext.StateRoot;RunId=$TlsContext.RunId;InstanceId=$TlsContext.InstanceId;
        ExportBase64=[Convert]::ToBase64String($current.ExportBytes);ExportSha256=$current.ExportSha256;EnvironmentKey=$current.Contract.environments[0].key;SqlcmdPath=$SqlcmdPath}
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($body|ConvertTo-Json -Depth 5 -Compress))
    $writer=$null;$holder=$null
    try {
        $writer=[IO.FileSystemAclExtensions]::Create([IO.FileInfo]::new($path),[IO.FileMode]::CreateNew,[Security.AccessControl.FileSystemRights]::FullControl,[IO.FileShare]::None,4096,[IO.FileOptions]::None,(Get-LabQualifiedPrivateSecurity))
        $writer.Write($bytes,0,$bytes.Length);$writer.Flush($true);$writer.Dispose();$writer=$null
        $holder=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        Assert-LabQualifiedPrivateStream $holder
        if((Get-LabContractByteHash (Read-LabContractStreamBytes $holder 131072)) -cne (Get-LabContractByteHash $bytes)){throw 'LAB_CONTEXT_COPY_CHANGED'}
        return [pscustomobject]@{Path=$path;Sha256=(Get-LabContractByteHash $bytes);Stream=$holder;Directory=$directory}
    }catch {if($holder){$holder.Dispose()};throw 'LAB_CONTEXT_CREATION_FAILED_RETAINED'}
    finally {if($writer){$writer.Dispose()}}
}

function Read-LabQualifiedConsumerContext {
    param([string]$Path,[string]$ExpectedSha256)
    if($ExpectedSha256 -cnotmatch '\A[a-f0-9]{64}\z'){throw 'LAB_CONTEXT_HASH_REQUIRED'}
    $stream=$null
    try {
        $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        Assert-LabQualifiedPrivateStream $stream
        $bytes=Read-LabContractStreamBytes $stream 131072
        if((Get-LabContractByteHash $bytes) -cne $ExpectedSha256){throw 'LAB_CONTEXT_CHANGED'}
        $context=[Text.UTF8Encoding]::new($false,$true).GetString($bytes)|ConvertFrom-Json -DateKind String
        if($context.ContractVersion -cne 'Toolbelt.QualifiedLabContext/0.1'){throw 'LAB_CONTEXT_INVALID'}
        $export=[Convert]::FromBase64String($context.ExportBase64)
        if((Get-LabContractByteHash $export) -cne $context.ExportSha256){throw 'LAB_CONTEXT_EXPORT_CHANGED'}
        $snapshot=Read-LabQualifiedSnapshot $export $context
        if($snapshot.Contract.environments[0].key -cne $context.EnvironmentKey -or
            (Get-FileHash -LiteralPath $context.SqlcmdPath).Hash.ToLowerInvariant() -cne $snapshot.Qualification.SqlcmdSha256){throw 'LAB_CONTEXT_TARGET_OR_CLIENT_CHANGED'}
        return $snapshot
    }finally{if($stream){$stream.Dispose()}}
}

function Close-LabQualifiedConsumerContext {
    param([object]$Context)
    if($null -eq $Context){return}
    if($Context.Stream){$Context.Stream.Dispose()}
    $directory=[IO.Path]::GetFullPath($Context.Directory);$path=[IO.Path]::GetFullPath($Context.Path)
    if([IO.Path]::GetDirectoryName($directory) -cne [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') -or
        [IO.Path]::GetFileName($directory) -cnotmatch '^toolbelt-tls-context-[a-f0-9]{32}$' -or $path -cne (Join-Path $directory 'context.json') -or
        (Get-Item -LiteralPath $directory -Force).Attributes -band [IO.FileAttributes]::ReparsePoint -or
        (Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint -or
        (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -cne $Context.Sha256){throw 'LAB_CONTEXT_CLEANUP_UNVERIFIED_RETAINED'}
    Remove-Item -LiteralPath $path -Force
    Remove-Item -LiteralPath $directory -Force
}
