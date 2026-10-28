[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedRunsetSha256,
    [Parameter(Mandatory)][ValidateRange(0,1)][int]$CaseIndex,
    [switch]$AuditOnly,
    [switch]$ValidateOnly,
    [switch]$ReadOnlyPreflight
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'SSIS_TSQL_POWERSHELL_7_REQUIRED'}
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$script:clock=[Diagnostics.Stopwatch]::StartNew()
$script:releaseTimeoutState=[pscustomobject]@{clock=$script:clock;cleanup=$false}
$timeoutState=$script:releaseTimeoutState
$timeoutProvider={
    $limit=if($timeoutState.cleanup){360000}else{300000}
    $remaining=$limit-$timeoutState.clock.ElapsedMilliseconds
    if($remaining -lt 1000){throw 'RELEASE_DEADLINE'}
    [int][Math]::Min(45,[Math]::Floor($remaining/1000))
}.GetNewClosure()
Set-Item -LiteralPath Function:\Get-StandaloneReleaseTimeout -Value $timeoutProvider
$timeoutAstErrors=$null
$timeoutAst=[Management.Automation.Language.Parser]::ParseFile($PSCommandPath,[ref]$null,[ref]$timeoutAstErrors)
if($timeoutAstErrors.Count -or @($timeoutAst.FindAll({param($node)$node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Get-ReleaseTimeout'},$true)).Count){throw 'SSIS_TSQL_TIMEOUT_ADAPTER_MISSING'}
$script:connections=[Collections.Generic.List[object]]::new()
$script:control=$null;$script:ledger=$null;$script:journal=$null;$script:evidenceRoot=$null;$script:configurationBefore=@();$script:configurationAfter=@();$script:clrAssemblySnapshot=@();$failure=$null;$stage='PREPARE'

function Save-PrivatePrepareFailure($ErrorRecord) {
    if(-not $script:evidenceRoot){return}
    try{
        $runtime=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))
        $resolved=[IO.Path]::GetFullPath($script:evidenceRoot)
        if(-not $resolved.StartsWith($runtime+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
           -not (Test-Path -LiteralPath $resolved -PathType Container) -or
           ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){return}
        $path=Join-Path $resolved ('prepare-case-'+$CaseIndex+'.private.json')
        if(Test-Path -LiteralPath $path){return}
        $leaf=$ErrorRecord.Exception
        $payload=[ordered]@{
            schema='toolbelt-ssis-installer-prepare-failure/v1'
            stage=$script:stage
            exception_type=$leaf.GetType().FullName
            hresult=('{0:X8}' -f $leaf.HResult)
            sql_number=if($leaf -is [Data.SqlClient.SqlException]){$leaf.Number}else{$null}
            message=$leaf.Message
        }
        [IO.File]::WriteAllText($path,($payload|ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
    }catch{}
}

function Get-StandaloneInstallerTimeout {
    $remaining=300000-$script:clock.ElapsedMilliseconds
    if($remaining -lt 1000){throw 'SSIS_TSQL_INSTALLER_CASE_DEADLINE'}
    return [int][Math]::Min(120,[Math]::Floor($remaining/1000))
}

function Import-StandaloneFunctions([string]$Path,[string[]]$Names,[hashtable]$Replace=@{}) {
    $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors)
    if($errors.Count){throw 'SSIS_TSQL_HELPER_PARSE'}
    foreach($name in $Names){
        $nodes=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
        if($nodes.Count -ne 1){throw 'SSIS_TSQL_HELPER_AMBIGUOUS'}
        $text=$nodes[0].Extent.Text
        foreach($key in $Replace.Keys){$text=$text.Replace($key,$Replace[$key])}
        if($Replace.ContainsKey('Get-ReleaseTimeout') -and $text -match '\bGet-ReleaseTimeout\b'){throw 'SSIS_TSQL_TIMEOUT_ADAPTER_MISSING'}
        [scriptblock]::Create($text)
    }
}
foreach($block in Import-StandaloneFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
    'Assert-ReleasePin','Assert-ReleasePrivatePath','Invoke-ReleaseSql',
    'Open-ReleaseConnection','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity') @{
        'Get-ReleaseTimeout'='Get-StandaloneReleaseTimeout'
    }){. $block}
foreach($block in Import-StandaloneFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @(
    'Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
        'Get-CsvTrust'='Get-StandaloneTrust';'Assert-CsvTrustCleanupScope'='Assert-StandaloneTrustCleanupScope';
        'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'
    }){. $block}
function Get-SsisNativeTimeout([int]$Maximum=45){[int][Math]::Min($Maximum,(Get-StandaloneReleaseTimeout))}
foreach($block in Import-StandaloneFunctions (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1') @(
    'Query','NonQuery','ReconfigureProtected')){. $block}

function Assert-RunsetIntegrity {
    $runsetKeys=@($script:runset.PSObject.Properties.Name|Sort-Object)
    if(($runsetKeys -join '|') -cne 'cases|contractSha256|native|package|pins|promptSha256|schemaSha256|schemaVersion' -or
       $script:runset.schemaVersion -cne '1.0' -or $script:runset.cases.Count -ne 2 -or
       $script:runset.native.caseInvocations -ne 2 -or $script:runset.native.auditInvocations -ne 2 -or
       $script:runset.native.maximumAttempts -ne 4){
        throw 'SSIS_TSQL_RUNSET_INVALID'
    }
    foreach($index in 0..1){
        $case=$script:runset.cases[$index]
        $version=[string]$case.version
        $caseKeys=@($case.PSObject.Properties.Name|Sort-Object)
        if(($caseKeys -join '|') -cne 'cl|patch|platform|version' -or $case.platform -cne 'windows' -or
           $case.patch -cne 'base' -or $version -cnotin @('2019','2025') -or
           $case.cl -ne @{2019=150;2025=170}[[int]$version]){throw 'SSIS_TSQL_RUNSET_CASE_SCOPE'}
    }
    if($script:runset.pins.Count -ne 20){throw 'SSIS_TSQL_RUNSET_PIN_COUNT'}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pin in $script:runset.pins){
        $pinKeys=@($pin.PSObject.Properties.Name|Sort-Object)
        if(($pinKeys -join '|') -cne 'path|sha256' -or [string]$pin.sha256 -cnotmatch '^[A-F0-9]{64}$' -or -not $seen.Add([string]$pin.path)){
            throw 'SSIS_TSQL_RUNSET_PIN_SHAPE'
        }
        Assert-ReleasePin ([string]$pin.path) ([string]$pin.sha256)
    }
    if((Get-FileHash -LiteralPath $script:runsetPath -Algorithm SHA256).Hash -cne $script:runsetSha256){throw 'SSIS_TSQL_RUNSET_DRIFT'}
    $report=Get-Content -LiteralPath $script:reportPath -Raw|ConvertFrom-Json
    if($report.publication_authorized -isnot [bool] -or $report.publication_authorized -or
       $report.source_package.path -cne 'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip' -or
       $report.source_package.sha256 -cne 'A256929FF32DAEE4087DC61C70BB8D4DFFEBB55772878BE53C658088F4E33049' -or
       $report.source_package.qualification -cne 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.InstallPackage.20261025.json' -or
       $report.source_package.qualification_sha256 -cne '6FBF48508A1F13BB9F629353BBCE8908DC729C9AD2E7779B3C689DBFB62A692F' -or
       $report.output.path -cne 'Releases/1.0.0/SSIS-INSTALL-TSQL.sql'){
        throw 'SSIS_TSQL_PROVENANCE_INVALID'
    }
    if((Get-FileHash -LiteralPath $script:packagePath -Algorithm SHA256).Hash -cne $report.source_package.sha256){throw 'SSIS_TSQL_PACKAGE_DRIFT'}
    $qualificationPath=Join-Path $repo ([string]$report.source_package.qualification)
    if((Get-FileHash -LiteralPath $qualificationPath -Algorithm SHA256).Hash -cne $report.source_package.qualification_sha256){throw 'SSIS_TSQL_QUALIFICATION_DRIFT'}
    $qualification=Get-Content -LiteralPath $qualificationPath -Raw|ConvertFrom-Json
    if($qualification.result -cne 'PASS' -or $qualification.package_sha256 -cne 'a256929ff32daee4087dc61c70bb8d4dffebb55772878be53c658088f4e33049'){
        throw 'SSIS_TSQL_QUALIFICATION_RESULT'
    }
    $sidecar=(Get-Content -LiteralPath ($script:packagePath+'.sha256') -Raw).Trim()
    if($sidecar -cne ($report.source_package.sha256+'  '+[IO.Path]::GetFileName($script:packagePath))){throw 'SSIS_TSQL_PACKAGE_SIDECAR'}
    $script:report=$report
    $fileInfo=Get-Item -LiteralPath $script:installerPath -Force
    if($fileInfo.PSIsContainer -or ($fileInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
       $fileInfo.Length -ne [long]$report.output.bytes -or $fileInfo.Length -gt 20MB){throw 'SSIS_TSQL_INSTALLER_FILE_BOUNDS'}
    $stream=[IO.File]::Open($script:installerPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try{
        if($stream.Length -ne [long]$report.output.bytes -or $stream.Length -gt 20MB){throw 'SSIS_TSQL_INSTALLER_STREAM_BOUNDS'}
        $bytes=[byte[]]::new([int]$stream.Length);$offset=0
        while($offset -lt $bytes.Length){$read=$stream.Read($bytes,$offset,$bytes.Length-$offset);if($read -le 0){throw 'SSIS_TSQL_INSTALLER_TRUNCATED'};$offset+=$read}
        if($stream.ReadByte() -ne -1 -or $stream.Length -ne $bytes.Length){throw 'SSIS_TSQL_INSTALLER_CHANGED_DURING_READ'}
    }finally{$stream.Dispose()}
    $installerHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
    if($installerHash -cne $report.output.sha256){throw 'SSIS_TSQL_INSTALLER_PROVENANCE_HASH'}
    $script:installerSnapshotSha256=$installerHash
    $script:installerTextSnapshot=[Text.UTF8Encoding]::new($false,$true).GetString($bytes)
    $localHeader="DECLARE @DeploymentMode nvarchar(16)=N'local';"
    $centralHeader="DECLARE @DeploymentMode nvarchar(16)=N'central';"
    if($script:installerTextSnapshot.IndexOf($localHeader,[StringComparison]::Ordinal) -lt 0 -or
       $script:installerTextSnapshot.IndexOf($localHeader,[StringComparison]::Ordinal) -ne $script:installerTextSnapshot.LastIndexOf($localHeader,[StringComparison]::Ordinal)){
        throw 'SSIS_TSQL_INSTALLER_HEADER_BINDING'
    }
    $script:installerTexts=@{
        local=$script:installerTextSnapshot
        central=$script:installerTextSnapshot.Replace($localHeader,$centralHeader)
    }
    if($script:installerTexts.central.IndexOf($localHeader,[StringComparison]::Ordinal) -ge 0 -or
       $script:installerTexts.central.IndexOf($centralHeader,[StringComparison]::Ordinal) -lt 0){throw 'SSIS_TSQL_CENTRAL_OVERRIDE_BINDING'}
    $script:installerCommandHashes=@{
        local=$installerHash
        central=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($script:installerTexts.central)))
    }
}

function Assert-StandaloneTrust([Data.SqlClient.SqlConnection]$Connection,[switch]$Prepare) {
    $entries=@()
    foreach($key in @('Parser','ScriptDom','Ssis')){
        $hash=[Convert]::FromHexString([string]$script:report.dll_sha512.$key)
        $existing=Get-StandaloneTrust $Connection $hash
        $entry=[ordered]@{hash=$script:report.dll_sha512.$key;preexisting=($null -ne $existing);fingerprint=$null;description=$null;state='PREEXISTING'}
        if($existing){$entry.fingerprint=[string]$existing.Fingerprint}
        $script:ledger.trust+=@($entry);Save-ReleaseJournal
        if(-not $existing){
            if(-not $Prepare){throw 'SSIS_TSQL_TRUST_MISSING'}
            Assert-StandaloneTrustCleanupScope $Connection $hash
            $entry.state='ADDING';$entry.description='Toolbelt standalone SSIS T-SQL test '+$script:ledger.owner+' '+$key;Save-ReleaseJournal
            Invoke-ReleaseSql $Connection 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; IF @H IS NULL OR DATALENGTH(@H)<>64 THROW 51591,N''Invalid exact trust input.'',1; IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@H) EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
            $actual=Get-StandaloneTrust $Connection $hash
            if($null -eq $actual -or $actual.description -cne $entry.description){throw 'SSIS_TSQL_TRUST_OWNERSHIP_UNKNOWN'}
            $entry.preexisting=$false;$entry.fingerprint=[string]$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
        }
        $entries+=@($entry)
    }
    return ,$entries
}

function Invoke-InstallerText([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[int]$CommandTimeoutSeconds=0) {
    $command=$Connection.CreateCommand()
    $timeout=if($CommandTimeoutSeconds -gt 0){$CommandTimeoutSeconds}else{Get-StandaloneReleaseTimeout}
    $timer=[Diagnostics.Stopwatch]::StartNew();$completed=$false
    try{
        $command.CommandTimeout=$timeout
        $command.CommandText=$Text
        $reader=$command.ExecuteReader()
        $sets=[Collections.Generic.List[object]]::new()
        try{
            do{
                if($reader.FieldCount -gt 0){
                    $columns=[Collections.Generic.List[string]]::new()
                    for($i=0;$i -lt $reader.FieldCount;$i++){$columns.Add($reader.GetName($i))}
                    $rows=[Collections.Generic.List[object]]::new()
                    while($reader.Read()){
                        $row=[ordered]@{}
                        for($i=0;$i -lt $reader.FieldCount;$i++){$row[$reader.GetName($i)]=$reader.GetValue($i)}
                        $rows.Add([pscustomobject]$row)
                    }
                    $sets.Add([pscustomobject]@{Columns=$columns.ToArray();Rows=$rows.ToArray()})
                }
            }while($reader.NextResult())
        }finally{$reader.Dispose()}
        $completed=$true
        return ,$sets.ToArray()
    }finally{
        $timer.Stop()
        if($script:ledger -and -not $AuditOnly){
            if(-not $script:ledger.Contains('installer_command_runs')){$script:ledger['installer_command_runs']=@()}
            $commandHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text)))
            $script:ledger.installer_command_runs+=@([ordered]@{stage=$script:stage;command_sha256=$commandHash;timeout_seconds=$timeout;elapsed_milliseconds=$timer.ElapsedMilliseconds;completed=$completed})
            Save-ReleaseJournal
        }
        $command.Dispose()
    }
}

function Get-SqlError($ErrorRecord) {
    $leaf=$ErrorRecord.Exception;$deepest=$leaf
    while($leaf){
        if($leaf -is [Data.SqlClient.SqlException]){return $leaf}
        $deepest=$leaf;$leaf=$leaf.InnerException
    }
    return $deepest
}

function Get-PrivateExceptionChain($ErrorRecord) {
    $result=[Collections.Generic.List[object]]::new();$current=$ErrorRecord.Exception
    while($current -and $result.Count -lt 8){
        $message=[string]$current.Message
        if($script:target){foreach($secret in @([string]$script:target.host,[string]$script:target.username,[string]$script:target.password)){if($secret){$message=$message.Replace($secret,'<redacted>')}}}
        $message=[regex]::Replace($message,'(?i)(Data Source|Server|Initial Catalog|User ID|UID|Password|Pwd)\s*=\s*[^;\r\n]+','$1=<redacted>')
        if($message.Length -gt 800){$message=$message.Substring(0,800)}
        $sqlNumber=if($current -is [Data.SqlClient.SqlException]){$current.Number}else{$null}
        $result.Add([ordered]@{type=$current.GetType().FullName;hresult=('{0:X8}' -f $current.HResult);sql_number=$sqlNumber;message=$message})
        $current=$current.InnerException
    }
    return ,$result.ToArray()
}

function Get-PrivateSqlErrors($ErrorRecord) {
    $current=$ErrorRecord.Exception
    while($current -and $current -isnot [Data.SqlClient.SqlException]){$current=$current.InnerException}
    if($current -isnot [Data.SqlClient.SqlException]){return @()}
    $result=[Collections.Generic.List[object]]::new()
    foreach($item in $current.Errors){
        if($result.Count -ge 32){break}
        $message=[string]$item.Message
        if($script:target){foreach($secret in @([string]$script:target.host,[string]$script:target.username,[string]$script:target.password)){if($secret){$message=$message.Replace($secret,'<redacted>')}}}
        $message=[regex]::Replace($message,'(?i)(Data Source|Server|Initial Catalog|User ID|UID|Password|Pwd)\s*=\s*[^;\r\n]+','$1=<redacted>')
        if($message.Length -gt 800){$message=$message.Substring(0,800)}
        $result.Add([ordered]@{number=[int]$item.Number;state=[int]$item.State;class=[int]$item.Class;procedure=[string]$item.Procedure;line=[int]$item.LineNumber;message=$message})
    }
    return ,$result.ToArray()
}

function Assert-InstallerRejected([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[string]$Code) {
    $caught=$null;$caughtRecord=$null
    try{[void](Invoke-InstallerText $Connection $Text)}catch{$caughtRecord=$_;$caught=Get-SqlError $_}
    if($caught -isnot [Data.SqlClient.SqlException] -or $caught.Number -ne 50000 -or
       -not $caught.Message.StartsWith($Code+':',[StringComparison]::Ordinal)){
        if($script:ledger -and $caughtRecord){
            $script:ledger['privateExpectedRejection']=[ordered]@{
                expected_code=$Code
                exception_chain=Get-PrivateExceptionChain $caughtRecord
                sql_errors=Get-PrivateSqlErrors $caughtRecord
            }
            Save-ReleaseJournal
        }
        throw 'SSIS_TSQL_EXPECTED_REJECTION_MISSING'
    }
}

function Test-CallerGuards([Data.SqlClient.SqlConnection]$Connection,[string]$Text) {
    $script:stage='CALLER_TRANSACTION_GUARD'
    Invoke-ReleaseSql $Connection 'SET XACT_ABORT ON; CREATE TABLE #SsisInstallerSentinel(Value int NOT NULL); BEGIN TRANSACTION; INSERT #SsisInstallerSentinel VALUES(73);'
    Assert-InstallerRejected $Connection $Text 'TBX_SSIS_INSTALL_SESSION'
    $state=@(Invoke-ReleaseSql $Connection 'SELECT @@TRANCOUNT AS T,XACT_STATE() AS S,(SELECT COUNT(*) FROM #SsisInstallerSentinel WHERE Value=73) AS N;' -Rows)
    if($state.Count -ne 1 -or $state[0].T -ne 1 -or $state[0].S -ne 1 -or $state[0].N -ne 1){throw 'SSIS_TSQL_CALLER_TRANSACTION_CHANGED'}
    Invoke-ReleaseSql $Connection 'ROLLBACK TRANSACTION; DROP TABLE #SsisInstallerSentinel; SET XACT_ABORT OFF;'

    $script:stage='CALLER_TEMP_GUARD'
    Invoke-ReleaseSql $Connection 'CREATE TABLE #tbx_ResultTableReleaseObjects(Value int NOT NULL); INSERT #tbx_ResultTableReleaseObjects VALUES(91);'
    Assert-InstallerRejected $Connection $Text 'TBX_SSIS_INSTALL_TEMP_SCOPE'
    $temp=@(Invoke-ReleaseSql $Connection 'SELECT OBJECT_ID(N''tempdb..#tbx_ResultTableReleaseObjects'') AS ObjectId,(SELECT COUNT(*) FROM #tbx_ResultTableReleaseObjects WHERE Value=91) AS N;' -Rows)
    if($temp.Count -ne 1 -or $temp[0].ObjectId -is [DBNull] -or $temp[0].N -ne 1){throw 'SSIS_TSQL_CALLER_TEMP_CHANGED'}
    Invoke-ReleaseSql $Connection 'DROP TABLE #tbx_ResultTableReleaseObjects;'
}

function Get-StandaloneInstalledState([Data.SqlClient.SqlConnection]$Connection,[string]$Mode) {
    $expectedVersions=@{
        'toolbelt.core.result-table'='1.0.0'
        'toolbelt.tsql.script-parser'='2.0.1'
        'toolbelt.tsql.ssis-debug'='1.0.0'
    }
    $rows=@(Invoke-ReleaseSql $Connection "SELECT name,CONVERT(nvarchar(128),value) value FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND major_id=0 AND minor_id=0 AND name LIKE N'Toolbelt.Module.%.Version' ORDER BY name;" -Rows)
    if($rows.Count -ne 3){throw 'SSIS_TSQL_MODULE_MARKER_COUNT'}
    foreach($module in $expectedVersions.Keys){
        $name='Toolbelt.Module.'+$module+'.Version'
        $found=@($rows|Where-Object {$_.name -ceq $name -and $_.value -ceq $expectedVersions[$module]})
        if($found.Count -ne 1){throw 'SSIS_TSQL_MODULE_MARKER_VALUE'}
    }
    foreach($module in @('toolbelt.core.result-table','toolbelt.tsql.script-parser')){
        $name='Toolbelt.Module.'+$module+'.DeploymentMode'
        $found=@(Invoke-ReleaseSql $Connection 'SELECT CONVERT(nvarchar(16),value) value FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@Name;' @{'@Name'=$name} -Rows)
        if($found.Count -ne 1 -or $found[0].value -cne $Mode){throw 'SSIS_TSQL_DEPLOYMENT_MODE_MARKER'}
    }
    $assemblies=@(Invoke-ReleaseSql $Connection "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash FROM sys.assemblies a WITH (NOLOCK) JOIN sys.assembly_files f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;" -Rows)
    $expectedAssemblies=@(
        [pscustomobject]@{name='Toolbelt_Tsql_ScriptParser';hash=[string]$script:report.dll_sha512.Parser},
        [pscustomobject]@{name='Microsoft.SqlServer.TransactSql.ScriptDom';hash=[string]$script:report.dll_sha512.ScriptDom},
        [pscustomobject]@{name='Toolbelt_Tsql_SsisDebug';hash=[string]$script:report.dll_sha512.Ssis}
    )
    if($assemblies.Count -ne $expectedAssemblies.Count){throw 'SSIS_TSQL_ASSEMBLY_COUNT'}
    foreach($expected in $expectedAssemblies){
        $found=@($assemblies|Where-Object {$_.name -ceq $expected.name -and $_.Hash -ceq $expected.hash})
        if($found.Count -ne 1){throw 'SSIS_TSQL_ASSEMBLY_HASH'}
    }
    return (@{versions=$rows;assemblies=$assemblies;mode=$Mode}|ConvertTo-Json -Depth 4 -Compress)
}

function Assert-StandaloneHelp([Data.SqlClient.SqlConnection]$Connection) {
    $command=$Connection.CreateCommand()
    try{
        $command.CommandText='EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;'
        $command.CommandTimeout=Get-StandaloneReleaseTimeout
        $reader=$command.ExecuteReader()
        try{
            if($reader.FieldCount -ne 12 -or -not $reader.Read()){throw 'SSIS_TSQL_HELP_SHAPE'}
            if($reader.NextResult()){throw 'SSIS_TSQL_HELP_EXTRA_RESULT'}
        }finally{$reader.Dispose()}
    }finally{$command.Dispose()}
}

function Get-StandaloneClrAssemblyInventory([Data.SqlClient.SqlConnection]$Connection) {
    $databases=Query $Connection 'SELECT name,state_desc,HAS_DBACCESS(name) AS HasAccess FROM sys.databases WITH (NOLOCK) WHERE database_id<>2 ORDER BY database_id;'
    if($databases.Rows.Count -lt 3 -or @($databases.Rows|Where-Object {$_.state_desc -cne 'ONLINE' -or $_.HasAccess -ne 1}).Count -gt 0){
        throw 'SSIS_TSQL_CLR_CONSUMER_SCOPE_INCOMPLETE'
    }
    $inventory=[Collections.Generic.List[object]]::new()
    try{
        foreach($database in $databases.Rows){
            $Connection.ChangeDatabase([string]$database.name)
            $assemblies=Query $Connection "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) AS Sha512 FROM sys.assemblies AS a WITH (NOLOCK) JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;"
            foreach($assembly in $assemblies.Rows){
                $inventory.Add([pscustomobject][ordered]@{database=[string]$database.name;name=[string]$assembly.name;sha512=[string]$assembly.Sha512})
            }
        }
    }finally{if($Connection.State -eq 'Open' -and $Connection.Database -cne 'master'){$Connection.ChangeDatabase('master')}}
    return ,@($inventory|Sort-Object database,name)
}

function Get-StandaloneInventoryHash($Inventory) {
    $json=ConvertTo-Json -InputObject @($Inventory) -Depth 5 -Compress
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))
}

function Enable-StandaloneClrForTest([Data.SqlClient.SqlConnection]$Connection) {
    $script:stage='CONFIGURATION_LEASE'
    $lease=Query $Connection "DECLARE @r int; EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.lab.clr.configuration',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0; SELECT @r AS R;"
    if($lease.Rows.Count -ne 1 -or [int]$lease.Rows[0].R -lt 0){throw 'SSIS_TSQL_CONFIGURATION_LEASE_BUSY'}
    $script:ledger.configurationLockHeld=$true;Save-ReleaseJournal
    $permissions=Query $Connection "SELECT IS_SRVROLEMEMBER(N'sysadmin') AS IsAdmin,(SELECT CONVERT(int,value) FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security') AS StrictConfigured,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security') AS StrictRunning;"
    if($permissions.Rows.Count -ne 1 -or $permissions.Rows[0].IsAdmin -ne 1 -or
       $permissions.Rows[0].StrictConfigured -ne 1 -or $permissions.Rows[0].StrictRunning -ne 1){throw 'SSIS_TSQL_PROTECTED_CONFIGURATION_UNSAFE'}
    $script:clrAssemblySnapshot=Get-StandaloneClrAssemblyInventory $Connection
    $all=Query $Connection 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running,is_dynamic AS Dynamic FROM sys.configurations WITH (NOLOCK);'
    $script:configurationBefore=@($all.Rows|Where-Object {$_.Configured -ne $_.Running -or $_.name -in @('clr enabled','show advanced options')}|ForEach-Object {
        [pscustomobject]@{name=[string]$_.name;configured=[int]$_.Configured;running=[int]$_.Running;dynamic=[bool]$_.Dynamic}
    })
    if(@($script:configurationBefore|Where-Object {$_.name -eq 'clr enabled'}).Count -ne 1 -or
       @($script:configurationBefore|Where-Object {$_.name -eq 'show advanced options'}).Count -ne 1){throw 'SSIS_TSQL_CONFIGURATION_SNAPSHOT_INCOMPLETE'}
    $script:ledger.configurationBefore=$script:configurationBefore
    $script:ledger.configurationAfter=@()
    $script:ledger.clrAssemblyInventory=$script:clrAssemblySnapshot
    $script:ledger.clrAssemblyInventorySha256=Get-StandaloneInventoryHash $script:clrAssemblySnapshot
    $script:ledger.configurationChanged=$true
    $script:ledger.configurationRestored=$false
    Save-ReleaseJournal
    NonQuery $Connection "EXEC sys.sp_configure N'clr enabled',1;"
    ReconfigureProtected $Connection
    $after=Query $Connection 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
    $script:configurationAfter=@(foreach($old in $script:configurationBefore){
        $row=@($after.Rows|Where-Object {$_.name -eq $old.name})
        if($row.Count -ne 1){throw 'SSIS_TSQL_CONFIGURATION_AFTER_INCOMPLETE'}
        [pscustomobject]@{name=$old.name;configured=[int]$row[0].Configured;running=[int]$row[0].Running}
    })
    $script:ledger.configurationAfter=$script:configurationAfter;Save-ReleaseJournal
    if(@($after.Rows|Where-Object {$_.name -eq 'clr enabled' -and $_.Running -eq 1}).Count -ne 1){throw 'SSIS_TSQL_CLR_ACTIVATION_FAILED'}
}

function Restore-StandaloneConfiguration([Data.SqlClient.SqlConnection]$Connection) {
    if(-not $script:ledger.configurationLockHeld){return}
    if($script:ledger.configurationChanged){
        $currentInventory=Get-StandaloneClrAssemblyInventory $Connection
        if((Get-StandaloneInventoryHash $currentInventory) -cne $script:ledger.clrAssemblyInventorySha256){throw 'SSIS_TSQL_CLR_CONSUMER_INVENTORY_DRIFT'}
        if($script:configurationAfter.Count -eq 0 -or $script:configurationAfter.Count -ne $script:configurationBefore.Count){throw 'SSIS_TSQL_CONFIGURATION_AFTER_UNCONFIRMED'}
        $current=Query $Connection 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
        foreach($expected in $script:configurationAfter){
            $row=@($current.Rows|Where-Object {$_.name -eq $expected.name})
            if($row.Count -ne 1 -or $row[0].Configured -ne $expected.configured -or $row[0].Running -ne $expected.running){throw 'SSIS_TSQL_CONFIGURATION_DRIFT'}
        }
        $beforeNames=@($script:configurationBefore|ForEach-Object name)
        if(@($current.Rows|Where-Object {$_.Configured -ne $_.Running -and $_.name -notin $beforeNames}).Count -gt 0){throw 'SSIS_TSQL_FOREIGN_PENDING_CONFIGURATION'}
        NonQuery $Connection "EXEC sys.sp_configure N'show advanced options',1;";ReconfigureProtected $Connection
        foreach($old in $script:configurationBefore|Where-Object {$_.name -ne 'show advanced options'}){
            NonQuery $Connection ("EXEC sys.sp_configure @configname=N'"+$old.name.Replace("'","''")+"',@configvalue="+$old.running+';')
        }
        ReconfigureProtected $Connection
        $advanced=@($script:configurationBefore|Where-Object {$_.name -eq 'show advanced options'})
        if($advanced.Count -ne 1){throw 'SSIS_TSQL_ADVANCED_CONFIGURATION_SNAPSHOT'}
        NonQuery $Connection ("EXEC sys.sp_configure N'show advanced options',"+$advanced[0].running+';');ReconfigureProtected $Connection
        foreach($old in $script:configurationBefore|Where-Object {$_.configured -ne $_.running}){
            NonQuery $Connection ("EXEC sys.sp_configure @configname=N'"+$old.name.Replace("'","''")+"',@configvalue="+$old.configured+';')
        }
        $restored=Query $Connection 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
        foreach($old in $script:configurationBefore){
            $row=@($restored.Rows|Where-Object {$_.name -eq $old.name})
            if($row.Count -ne 1 -or $row[0].Configured -ne $old.configured -or $row[0].Running -ne $old.running){throw 'SSIS_TSQL_CONFIGURATION_RESTORE_VERIFICATION'}
        }
        $script:ledger.configurationRestored=$true;Save-ReleaseJournal
    }
    $release=Query $Connection "DECLARE @r int; EXEC @r=sys.sp_releaseapplock @Resource=N'toolbelt.lab.clr.configuration',@LockOwner=N'Session'; SELECT @r AS R;"
    if($release.Rows.Count -ne 1 -or [int]$release.Rows[0].R -lt 0){throw 'SSIS_TSQL_CONFIGURATION_LEASE_RELEASE'}
    $script:ledger.configurationLockHeld=$false;Save-ReleaseJournal
}

function New-OwnedDatabase([string]$Suffix,[int]$Compatibility) {
    $name='Toolbelt_Release_'+$script:ledger.owner+'_'+$Suffix
    $entry=[ordered]@{name=$name;id=$null;created=$null;state='CREATING'}
    $script:ledger.databases+=@($entry);Save-ReleaseJournal
    Invoke-ReleaseSql $script:control "IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Standalone database collision.',1; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
    $identity=@(Invoke-ReleaseSql $script:control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WITH (NOLOCK) WHERE name=@Name;' @{'@Name'=$name} -Rows)
    if($identity.Count -ne 1){throw 'SSIS_TSQL_DATABASE_IDENTITY'}
    $entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
    $connection=Open-ReleaseConnection $name
    Invoke-ReleaseSql $connection "DECLARE @Owner nvarchar(32)=@Value; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@Owner;" @{'@Value'=$script:ledger.owner}
    $entry.state='OWNED';Save-ReleaseJournal;$connection.Dispose()
    Invoke-ReleaseSql $script:control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$Compatibility;"
    return $name
}

function Invoke-InstallAndVerify([string]$Database,[string]$Mode,[string]$InstallerText) {
    Assert-ReleaseInputs
    $connection=Open-ReleaseConnection $Database
    try{
        $script:stage='CALLER_GUARDS_'+$Mode
        Test-CallerGuards $connection $InstallerText
        $script:stage='INVALID_MODE_'+$Mode
        $modeText=$InstallerText.Replace("DECLARE @DeploymentMode nvarchar(16)=N'$Mode';", "DECLARE @DeploymentMode nvarchar(16)=N'invalid';")
        if($modeText -ceq $InstallerText -or $modeText.Contains("DECLARE @DeploymentMode nvarchar(16)=N'$Mode';")){throw 'SSIS_TSQL_MODE_OVERRIDE_INVALID'}
        Assert-InstallerRejected $connection $modeText 'TBX_SSIS_INSTALL_MODE'

        $script:stage='INSTALL_'+$Mode
        Assert-ReleaseInputs
        $sets=@(Invoke-InstallerText $connection $InstallerText (Get-StandaloneInstallerTimeout))
        if($sets.Count -ne 1 -or $sets[0].Rows.Count -ne 1 -or $sets[0].Columns.Count -ne 3 -or
           $sets[0].Rows[0].InstallerStatus -cne 'SSIS_TSQL_INSTALL_COMPLETED' -or
           $sets[0].Rows[0].TargetDatabase -cne $Database){throw 'SSIS_TSQL_INSTALL_STATUS'}
        $first=Get-StandaloneInstalledState $connection $Mode

        $script:stage='REPEAT_'+$Mode
        Assert-ReleaseInputs
        $repeatSets=@(Invoke-InstallerText $connection $InstallerText (Get-StandaloneInstallerTimeout))
        if($repeatSets.Count -ne 1 -or $repeatSets[0].Rows.Count -ne 1 -or
           $repeatSets[0].Rows[0].InstallerStatus -cne 'SSIS_TSQL_INSTALL_COMPLETED' -or
           (Get-StandaloneInstalledState $connection $Mode) -cne $first){throw 'SSIS_TSQL_REPEAT_DRIFT'}

        $script:stage='API_AND_HELP_'+$Mode
        & (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ApiCases.ps1') -Connection $connection | Out-Null
        Assert-StandaloneHelp $connection
    }finally{$connection.Dispose()}
}

try{
    $script:runsetPath=Assert-ReleasePrivatePath $RunsetPath
    $script:runset=Get-Content -LiteralPath $script:runsetPath -Raw|ConvertFrom-Json
    $script:runsetSha256=$ExpectedRunsetSha256
    $script:case=$script:runset.cases[$CaseIndex]
    $script:evidenceRoot=Split-Path -Parent $script:runsetPath
    $script:evidenceRoot=Assert-ReleasePrivatePath $script:evidenceRoot
    $script:journal=Assert-ReleasePrivatePath (Join-Path $script:evidenceRoot ('case-'+$CaseIndex+'.json'))
    $script:reportPath=Join-Path $repo 'Releases/1.0.0/ssis-standalone-installer.json'
    $script:installerPath=Join-Path $repo 'Releases/1.0.0/SSIS-INSTALL-TSQL.sql'
    $script:packagePath=Join-Path $repo ([string]$script:runset.package)
    Assert-RunsetIntegrity
    $script:stage='LAB_CONTRACT'
    . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
    foreach($block in Import-StandaloneFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
        'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
    $lab=Resolve-LabContract -TestPurpose Functional
    $prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
    if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $script:runset.contractSha256 -or
       (Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash -cne $script:runset.schemaSha256 -or
       (Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash -cne $script:runset.promptSha256){throw 'SSIS_TSQL_LAB_INPUT_DRIFT'}
    $expectedPins=@(
        $PSCommandPath,(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
        (Join-Path $PSScriptRoot 'Prepare-StandaloneTsqlInstallerRunset.ps1'),
        (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),(Join-Path $repo 'Tests/CI/run-lab-local.ps1'),
        (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
        (Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'),
        (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ApiCases.ps1'),
        (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1'),
        (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Contracts/Api.json'),
        (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx'),
        $script:installerPath,$script:reportPath,$script:packagePath,($script:packagePath+'.sha256'),
        (Join-Path $repo ([string]$script:report.source_package.qualification)),
        $lab.Path,$lab.SchemaPath,$prompt,(Get-Command pwsh -ErrorAction Stop).Source
    )|ForEach-Object {[IO.Path]::GetFullPath($_)}
    $expectedPinSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($path in $expectedPins){[void]$expectedPinSet.Add($path)}
    $actualPinSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pin in $script:runset.pins){[void]$actualPinSet.Add([IO.Path]::GetFullPath([string]$pin.path))}
    if($expectedPins.Count -ne 20 -or $expectedPinSet.Count -ne 20 -or $actualPinSet.Count -ne 20 -or
       @($expectedPinSet|Where-Object {-not $actualPinSet.Contains($_)}).Count -ne 0){throw 'SSIS_TSQL_RUNSET_INPUT_SET'}
    $script:stage='TARGET_RESOLUTION'
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $script:case)
    if($targets.Count -ne 1){throw 'SSIS_TSQL_TARGET_AMBIGUOUS'}
    $script:target=$targets[0]
    $targetIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$script:target.key)))
    if($ValidateOnly){$timeoutProbe=Get-StandaloneReleaseTimeout;if($timeoutProbe -lt 1 -or $timeoutProbe -gt 45){throw 'SSIS_TSQL_TIMEOUT_ADAPTER_INVALID'};'PASS SSIS_TSQL_VALIDATE_ONLY';exit 0}
    $script:stage='SQL_CONNECT_PREFLIGHT'
    $script:control=Open-ReleaseConnection 'master'
    if($ReadOnlyPreflight){
        $script:stage='READ_ONLY_PREFLIGHT'
        $probe=@(Invoke-ReleaseSql $script:control "SELECT @@VERSION Version,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info WITH (NOLOCK)) Platform,IS_SRVROLEMEMBER(N'sysadmin') IsAdmin,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WITH (NOLOCK) WHERE name='clr enabled') ClrReady,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WITH (NOLOCK) WHERE name='clr strict security') StrictReady,(SELECT CONVERT(int,value) FROM sys.configurations WITH (NOLOCK) WHERE name='clr enabled') ClrConfigured,(SELECT CONVERT(int,value) FROM sys.configurations WITH (NOLOCK) WHERE name='clr strict security') StrictConfigured,(SELECT name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Running,CONVERT(bit,is_dynamic) IsDynamic FROM sys.configurations WITH (NOLOCK) WHERE value<>value_in_use ORDER BY name FOR JSON PATH) PendingConfiguration;" -Rows)
        $expectedMajor=@{2019=15;2025=17}[[int]$script:case.version]
        $criteria=[ordered]@{
            exactly_one_row=($probe.Count -eq 1)
            selected_sql_major=($probe.Count -eq 1 -and $probe[0].Major -eq $expectedMajor)
            windows_platform=($probe.Count -eq 1 -and $probe[0].Platform -ieq 'Windows')
            existing_sysadmin_role=($probe.Count -eq 1 -and $probe[0].IsAdmin -eq 1)
            clr_enabled=($probe.Count -eq 1 -and $probe[0].ClrReady -eq 1)
            strict_security_enabled=($probe.Count -eq 1 -and $probe[0].StrictReady -eq 1 -and $probe[0].StrictConfigured -eq 1)
        }
        $pending=@()
        if($probe.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace([string]$probe[0].PendingConfiguration)){
            $pending=@(([string]$probe[0].PendingConfiguration)|ConvertFrom-Json|ForEach-Object {
                [ordered]@{name=[string]$_.name;configured=[int]$_.Configured;running=[int]$_.Running;dynamic=[bool]$_.IsDynamic}
            })
        }
        $probePath=Join-Path $script:evidenceRoot ('read-only-preflight-case-'+$CaseIndex+'.private.json')
        if(Test-Path -LiteralPath $probePath){throw 'SSIS_TSQL_PREFLIGHT_CAPTURE_EXISTS'}
        $probeRecord=[ordered]@{schema='toolbelt-ssis-read-only-preflight/v1';case=$CaseIndex;criteria=$criteria;pending_configuration=$pending;all_pass=(@($criteria.Values|Where-Object {-not $_}).Count -eq 0)}
        [IO.File]::WriteAllText($probePath,($probeRecord|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
        if($probeRecord.all_pass){'PASS SSIS_TSQL_READ_ONLY_PREFLIGHT';exit 0}else{'FAIL SSIS_TSQL_READ_ONLY_PREFLIGHT';exit 2}
    }
    if($AuditOnly){
        $script:ledger=Get-Content -LiteralPath $script:journal -Raw|ConvertFrom-Json
        if($script:ledger.targetIdentity -cne $targetIdentity -or $script:ledger.state -cnotin @('COMPLETE','FAILED_CLEANED')){throw 'SSIS_TSQL_AUDIT_STATE'}
        foreach($entry in $script:ledger.databases){
            $rows=@(Invoke-ReleaseSql $script:control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
            if($entry.state -cne 'DROPPED' -or $rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'SSIS_TSQL_AUDIT_DATABASE_PRESENT'}
        }
        foreach($entry in $script:ledger.trust){
            $actual=Get-StandaloneTrust $script:control ([Convert]::FromHexString($entry.hash))
            if(($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or
               (-not $entry.preexisting -and $null -ne $actual)){throw 'SSIS_TSQL_AUDIT_TRUST_DRIFT'}
        }
        if($script:ledger.configurationLockHeld){throw 'SSIS_TSQL_AUDIT_CONFIGURATION_LOCK_REMAINS'}
        if($script:ledger.configurationChanged){
            if($script:ledger.configurationRestored -isnot [bool] -or -not $script:ledger.configurationRestored){throw 'SSIS_TSQL_AUDIT_CONFIGURATION_NOT_RESTORED'}
            $current=Query $script:control 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
            foreach($old in $script:ledger.configurationBefore){
                $row=@($current.Rows|Where-Object {$_.name -eq $old.name})
                if($row.Count -ne 1 -or $row[0].Configured -ne $old.configured -or $row[0].Running -ne $old.running){throw 'SSIS_TSQL_AUDIT_CONFIGURATION_DRIFT'}
            }
            $inventory=Get-StandaloneClrAssemblyInventory $script:control
            if((Get-StandaloneInventoryHash $inventory) -cne $script:ledger.clrAssemblyInventorySha256){throw 'SSIS_TSQL_AUDIT_CLR_CONSUMER_DRIFT'}
        }
        Assert-ReleaseInputs
        'PASS SSIS_TSQL_INDEPENDENT_CLEANUP_AND_PINS';exit 0
    }
    if(Test-Path -LiteralPath $script:journal){throw 'SSIS_TSQL_CASE_ALREADY_ATTEMPTED'}
    $pre=@(Invoke-ReleaseSql $script:control "SELECT @@VERSION Version,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info WITH (NOLOCK)) Platform,IS_SRVROLEMEMBER(N'sysadmin') IsAdmin,(SELECT value_in_use FROM sys.configurations WITH (NOLOCK) WHERE name='clr enabled') ClrReady,(SELECT value_in_use FROM sys.configurations WITH (NOLOCK) WHERE name='clr strict security') StrictReady;" -Rows)
    if($pre.Count -ne 1 -or $pre[0].IsAdmin -ne 1 -or $pre[0].Major -ne @{2019=15;2025=17}[[int]$script:case.version] -or
       $pre[0].Platform -ine 'Windows' -or $pre[0].StrictReady -ne 1){throw 'SSIS_TSQL_TARGET_PREFLIGHT'}
    $script:ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');targetIdentity=$targetIdentity;state='PREPARED';databases=@();trust=@();completedModes=@();configurationBefore=@();configurationAfter=@();configurationChanged=$false;configurationRestored=$null;configurationLockHeld=$false;failure=$null}
    Save-ReleaseJournal
    if($pre[0].ClrReady -ne 1){Enable-StandaloneClrForTest $script:control}
    $stage='EXACT_TRUST'
    [void](Assert-StandaloneTrust $script:control -Prepare)
    $localDb=New-OwnedDatabase 'l' ([int]$script:case.cl)
    $centralDb=New-OwnedDatabase 'c' ([int]$script:case.cl)
    $script:ledger.installerSha256=$script:installerSnapshotSha256
    $script:ledger.commandSha256=$script:installerCommandHashes
    $script:ledger.centralHeaderOverride=[ordered]@{from="DECLARE @DeploymentMode nvarchar(16)=N'local';";to="DECLARE @DeploymentMode nvarchar(16)=N'central';";count=1}
    Save-ReleaseJournal
    Invoke-InstallAndVerify $localDb 'local' $script:installerTexts.local
    Invoke-InstallAndVerify $centralDb 'central' $script:installerTexts.central
    $script:ledger.completedModes=@('local','central');$script:ledger.state='INSTALLS_COMPLETE';Save-ReleaseJournal
    Assert-ReleaseInputs
}catch{
    $leaf=Get-SqlError $_
    $number=if($leaf -is [Data.SqlClient.SqlException]){$leaf.Number}else{0}
    $reason=if($leaf.Message -cmatch '^SSIS_TSQL_[A-Z0-9_]+$'){$leaf.Message}else{'SSIS_TSQL_UNCLASSIFIED'}
    $failure=[ordered]@{stage=$script:stage;sqlNumber=$number;reason=$reason}
    if(-not $script:ledger){Save-PrivatePrepareFailure $_}
    if($script:ledger -and -not $AuditOnly){
        $diagnostic=[string]$leaf.Message
        if($script:target){foreach($secret in @([string]$script:target.host,[string]$script:target.username,[string]$script:target.password)){if($secret){$diagnostic=$diagnostic.Replace($secret,'<redacted>')}}}
        $diagnostic=[regex]::Replace($diagnostic,'(?i)(Data Source|Server|Initial Catalog|User ID|UID|Password|Pwd)\s*=\s*[^;\r\n]+','$1=<redacted>')
        if($diagnostic.Length -gt 1200){$diagnostic=$diagnostic.Substring(0,1200)}
        $script:ledger.failure=$failure;$script:ledger['privateDiagnostic']=$diagnostic;$script:ledger['privateExceptionChain']=Get-PrivateExceptionChain $_;$script:ledger['privateSqlErrors']=Get-PrivateSqlErrors $_;Save-ReleaseJournal
    }
}finally{
    foreach($connection in $script:connections){if([object]::ReferenceEquals($connection,$script:control)){continue};try{$connection.Dispose()}catch{}}
    if($script:ledger -and -not $AuditOnly){
        $script:releaseTimeoutState.cleanup=$true
        try{
            if($script:ledger.configurationChanged -and (-not $script:control -or $script:control.State -ne 'Open')){throw 'SSIS_TSQL_CONFIGURATION_SESSION_LOST'}
            if(-not $script:control -or $script:control.State -ne 'Open'){$script:control=Open-ReleaseConnection 'master'}
            foreach($entry in $script:ledger.databases){
                if($entry.state -in @('OWNED','CREATED')){Assert-ReleaseOwnIdentity $script:control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
            }
            if(@($script:ledger.databases|Where-Object {$_.state -cne 'DROPPED'}).Count){throw 'SSIS_TSQL_DATABASE_CLEANUP_IDENTITY_UNKNOWN'}
            foreach($entry in $script:ledger.trust){
                $hash=[Convert]::FromHexString($entry.hash);$actual=Get-StandaloneTrust $script:control $hash
                if($entry.preexisting){if($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint){throw 'SSIS_TSQL_PREEXISTING_TRUST_DRIFT'};continue}
                if($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description){throw 'SSIS_TSQL_TRUST_CLEANUP_IDENTITY'}
                Assert-StandaloneTrustCleanupScope $script:control $hash
                Invoke-ReleaseSql $script:control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
                if($null -ne (Get-StandaloneTrust $script:control $hash)){throw 'SSIS_TSQL_TRUST_NOT_REMOVED'}
                $entry.state='REMOVED';Save-ReleaseJournal
            }
            if($script:ledger.configurationLockHeld){Restore-StandaloneConfiguration $script:control}
            $script:ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
        }catch{$script:ledger.state='CLEANUP_BLOCKED';$script:ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=[ordered]@{stage='CLEANUP';sqlNumber=0;reason='SSIS_TSQL_CLEANUP_BLOCKED'}}
    }
    if($script:control){$script:control.Dispose()}
}
if($failure){Write-Output ('FAIL '+($failure|ConvertTo-Json -Compress));exit 1}
'PASS SSIS_TSQL_STANDALONE_INSTALLER local+central, repeat, API/help, caller/session guards, owned cleanup'
