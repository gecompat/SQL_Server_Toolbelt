[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedRunsetSHA256,
      [switch]$ValidateOnly,
      [switch]$AuditOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock = [Diagnostics.Stopwatch]::StartNew()
$cleanup = $false
$stage = 'PREPARE'
$connections = [Collections.Generic.List[object]]::new()
$ledger = $null
$failure = $null
$control = $null
$db = $null

$errors = $null
$apiAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if ($errors.Count) { throw 'JSON_APPLOCK_HELPER_PARSE' }
$importNodes = @($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if ($importNodes.Count -ne 1) { throw 'JSON_APPLOCK_HELPER_DISCOVERY' }
. ([scriptblock]::Create($importNodes[0].Extent.Text))
foreach ($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
        'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
        'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')) { . $block }
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
foreach ($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
        'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')) { . $block }

function Assert-Runset {
    $script:RunsetPath = Assert-ReleasePrivatePath $script:RunsetPath
    if ((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()) {
        throw 'JSON_APPLOCK_RUNSET_PIN_DRIFT'
    }
    $script:runset = Get-Content -LiteralPath $script:RunsetPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($script:runset.schema_version -cne 'json-schema-applock-probe/v1' -or
        $script:runset.target.platform -cne 'windows' -or $script:runset.target.version -cne '2025' -or
        $script:runset.target.patch -cne 'CU8' -or $script:runset.target.compatibility_level -ne 170 -or
        $script:runset.target.test_purpose -cne 'Functional' -or $script:runset.artifacts.Count -ne 2 -or
        $script:runset.scope.expected_error -ne 55637 -or $script:runset.scope.expected_state -ne 1 -or
        @($script:runset.scope.lock_resources).Count -ne 2 -or
        @($script:runset.scope.lock_resources | Sort-Object -Unique).Count -ne 2) { throw 'JSON_APPLOCK_RUNSET_INVALID' }
    if (($script:runset.scope.lock_resources -join '|') -cne 'toolbelt.deploy.json.shared-core|toolbelt.deploy.toolbelt.json.schema') {
        throw 'JSON_APPLOCK_RESOURCE_SCOPE_INVALID'
    }
    $artifactModules = @($script:runset.artifacts.module_id | Sort-Object -CaseSensitive)
    if (($artifactModules -join '|') -cne 'toolbelt.json.core|toolbelt.json.schema') { throw 'JSON_APPLOCK_ARTIFACT_SCOPE' }
    if (@($script:runset.pins | Where-Object { $_.path -ceq $script:PSCommandPath }).Count -ne 1 -or
        @($script:runset.pins | Where-Object { $_.path -ceq (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1') }).Count -ne 1 -or
        @($script:runset.pins | Where-Object { $_.path -ceq (Join-Path $script:repo 'Tests/Release/ClrCaller.Environment.ps1') }).Count -ne 1 -or
        @($script:runset.pins | Where-Object { $_.path -ceq (Join-Path $script:repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') }).Count -ne 1 -or
        @($script:runset.pins | Where-Object { $_.path -ceq (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') }).Count -ne 1 -or
        @($script:runset.pins | Where-Object { $_.path -ceq (Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1') }).Count -ne 1) {
        throw 'JSON_APPLOCK_REQUIRED_PIN_MISSING'
    }
    Assert-ReleaseInputs
    foreach ($artifact in $script:runset.artifacts) {
        if ($artifact.module_id -cnotin @('toolbelt.json.core','toolbelt.json.schema') -or
            $artifact.sha256 -cnotmatch '^[a-f0-9]{64}$' -or $artifact.sha512 -cnotmatch '^[a-f0-9]{128}$' -or
            (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $artifact.sha256 -or
            (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA512).Hash.ToLowerInvariant() -cne $artifact.sha512) {
            throw 'JSON_APPLOCK_ARTIFACT_DRIFT'
        }
    }
    foreach ($export in @($script:runset.baseline,$script:runset.schema_deploy,$script:runset.schema_uninstall)) {
        if (-not $export.path -or (Get-FileHash -LiteralPath $export.path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $export.sha256) {
            throw 'JSON_APPLOCK_EXPORT_DRIFT'
        }
    }
    if ($script:runset.baseline.modules.Count -ne 2 -or $script:runset.baseline.modules[0] -cne 'toolbelt.core.result-table' -or
        $script:runset.baseline.modules[1] -cne 'toolbelt.json.core' -or $script:runset.schema_deploy.module -cne 'toolbelt.json.schema' -or
        $script:runset.schema_uninstall.module -cne 'toolbelt.json.schema') {
        throw 'JSON_APPLOCK_INSTALL_CLOSURE_INVALID'
    }
}

function Get-LabSelectorTarget {
    $lab = Resolve-LabContract -TestPurpose Functional
    if ((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $script:runset.lab.contract_sha256 -or
        (Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $script:runset.lab.schema_sha256) {
        throw 'JSON_APPLOCK_LAB_INPUT_DRIFT'
    }
    if ($script:runset.lab.prompt_path) {
        if ((Get-FileHash -LiteralPath $script:runset.lab.prompt_path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $script:runset.lab.prompt_sha256) {
            throw 'JSON_APPLOCK_PROMPT_DRIFT'
        }
    }
    $selector = [pscustomobject]@{ Platform='windows';Version='2025';Patch='CU8' }
    $targets = @(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $selector)
    if ($targets.Count -ne 1 -or -not (Test-LabTargetReady -Contract $lab.Contract -Entry $targets[0])) {
        throw 'JSON_APPLOCK_EXACT_READY_TARGET_REQUIRED'
    }
    $script:target = $targets[0]
    if ($script:target.encrypt -isnot [bool] -or $script:target.encrypt -ne $true -or
        $script:target.trustServerCertificate -isnot [bool]) { throw 'JSON_APPLOCK_FUNCTIONAL_TRANSPORT_INVALID' }
}

function Save-Journal {
    $temporary = $script:journal + '.writing'
    [IO.File]::WriteAllText($temporary,($script:ledger | ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    [IO.File]::Move($temporary,$script:journal,$true)
}
function Assert-RunsetStable {
    if ((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()) {
        throw 'JSON_APPLOCK_RUNSET_PIN_DRIFT'
    }
}
function Assert-AuditJournalCases($Prior) {
    $expectedResources = @('toolbelt.deploy.json.shared-core','toolbelt.deploy.toolbelt.json.schema')
    $results = @($Prior.results)
    $validState = $Prior.state -ceq 'COMPLETE' -or $Prior.state -ceq 'FAILED_CLEANED'
    $countValid = if ($Prior.state -ceq 'COMPLETE') { $results.Count -eq 2 } else { $results.Count -le 2 }
    if (-not $validState -or -not $countValid -or $Prior.owner -cnotmatch '^[a-f0-9]{32}$' -or
        $Prior.target.platform -cne 'windows' -or $Prior.target.version -cne '2025' -or $Prior.target.patch -cne 'CU8' -or
        $Prior.target.compatibility_level -ne 170) { throw 'JSON_APPLOCK_AUDIT_JOURNAL_INVALID' }
    for ($index=0; $index -lt $results.Count; $index++) {
        $result = $results[$index]
        if ([string]$result.resource -cne $expectedResources[$index] -or
            $result.blocked -isnot [bool] -or $result.positive_control -isnot [bool] -or $result.snapshot_unchanged -isnot [bool] -or
            -not $result.blocked -or -not $result.positive_control -or -not $result.snapshot_unchanged) {
            throw 'JSON_APPLOCK_AUDIT_JOURNAL_INVALID'
        }
    }
}
function Open-ReleaseConnection([string]$Database) {
    Assert-RunsetStable
    Assert-ReleaseInputs
    $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $script:target -TestPurpose Functional))
    $builder['Initial Catalog'] = $Database
    $builder['Pooling'] = $false
    $builder['Enlist'] = $false
    $builder['ConnectRetryCount'] = 0
    $builder['Connect Timeout'] = [Math]::Min(15,(Get-ReleaseTimeout))
    $connection = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
    try { $connection.Open(); $script:connections.Add($connection); return $connection }
    catch { $connection.Dispose(); throw }
    finally { $builder.Clear() }
}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows) {
    Assert-RunsetStable
    Assert-ReleaseInputs
    Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows
}
function Invoke-ReleaseBatches($Connection,[string]$Text) {
    $Text=[regex]::Replace($Text,'(?im)^\s*:ON\s+ERROR\s+EXIT\s*$','')
    if ($Text -match '(?m)^\s*:' -or $Text.Contains('$(')) { throw 'RELEASE_UNRESOLVED_SQLCMD' }
    foreach ($batch in [regex]::Split($Text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) { Sql $Connection $batch }
    }
}
function Read-Scalar($Connection,[string]$Text) {
    $rows = @(Sql $Connection $Text -Rows)
    if ($rows.Count -ne 1) { throw 'JSON_APPLOCK_QUERY_SHAPE' }
    $properties = @($rows[0].PSObject.Properties)
    if ($properties.Count -ne 1) { throw 'JSON_APPLOCK_QUERY_SHAPE' }
    return $properties[0].Value
}
function Get-ModuleState($Connection) {
    $query = @'
SELECT
 (SELECT name,schema_id,principal_id FROM sys.schemas WHERE name IN(N'toolbelt_core',N'toolbelt_json') ORDER BY name FOR JSON PATH) Schemas,
 (SELECT a.name,a.principal_id,a.permission_set_desc,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) BinaryHash,
   CAST(a.is_visible AS int) IsVisible FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
   WHERE a.is_user_defined=1 ORDER BY a.name FOR JSON PATH) Assemblies,
 (SELECT o.object_id,o.principal_id,s.name SchemaName,o.name,o.type,sm.definition,am.assembly_id,am.assembly_class,am.assembly_method
   FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules sm ON sm.object_id=o.object_id
   LEFT JOIN sys.assembly_modules am ON am.object_id=o.object_id WHERE s.name IN(N'toolbelt_core',N'toolbelt_json')
   ORDER BY o.object_id FOR JSON PATH) Objects,
 (SELECT ep.class,ep.major_id,ep.minor_id,ep.name,CONVERT(nvarchar(4000),ep.value) Value FROM sys.extended_properties ep
   WHERE ep.name LIKE N'Toolbelt.%' ORDER BY ep.class,ep.major_id,ep.minor_id,ep.name FOR JSON PATH) Properties,
 (SELECT dp.class,dp.major_id,dp.minor_id,dp.grantee_principal_id,dp.grantor_principal_id,dp.type,dp.permission_name,dp.state
   FROM sys.database_permissions dp
   ORDER BY dp.class,dp.major_id,dp.minor_id,dp.grantee_principal_id,dp.permission_name FOR JSON PATH) Permissions,
 (SELECT principal_id,name,type,type_desc,default_schema_name,authentication_type_desc,CONVERT(varchar(258),sid,2) Sid
   FROM sys.database_principals ORDER BY principal_id FOR JSON PATH) Principals,
 (SELECT role_principal_id,member_principal_id FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id FOR JSON PATH) RoleMemberships;
'@
    $rows = @(Sql $Connection $query -Rows)
    if ($rows.Count -ne 1) { throw 'JSON_APPLOCK_SNAPSHOT_SHAPE' }
    return ($rows[0] | ConvertTo-Json -Depth 4 -Compress)
}
function Assert-SchemaAbsent($Connection) {
    if ([int](Read-Scalar $Connection "SELECT CASE WHEN SCHEMA_ID(N'toolbelt_json') IS NULL THEN 0 ELSE 1 END AS ScalarValue;") -ne 0) {
        throw 'JSON_APPLOCK_SCHEMA_NOT_ABSENT'
    }
    $rows = @(Sql $Connection "SELECT COUNT(*) Count FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema';" -Rows)
    if ($rows.Count -ne 1 -or [int]$rows[0].Count -ne 0) { throw 'JSON_APPLOCK_SCHEMA_ASSEMBLY_NOT_ABSENT' }
}
function Assert-CoreOnly($Connection) {
    $rows = @(Sql $Connection "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
    if ($rows.Count -ne 1 -or $rows[0].name -cne 'Toolbelt_JsonCore' -or
        $rows[0].Hash.ToLowerInvariant() -cne (@($script:runset.artifacts|Where-Object module_id -ceq 'toolbelt.json.core')[0].sha512) -or
        $rows[0].Permission -cne 'SAFE_ACCESS') { throw 'JSON_APPLOCK_BASELINE_CORE_INVALID' }
    $marker = @(Sql $Connection "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.core.Version';" -Rows)
    if ($marker.Count -ne 1 -or $marker[0].Value -cne '1.0.0') { throw 'JSON_APPLOCK_BASELINE_MARKER_INVALID' }
}
function Assert-HolderLock($Connection,[int]$ExpectedSpid) {
    $rows = @(Sql $Connection @'
SELECT @@SPID Spid,@@TRANCOUNT TranCount,XACT_STATE() XactState,
 (SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_session_id=@@SPID AND resource_type=N'APPLICATION'
  AND request_mode=N'X' AND request_status=N'GRANT' AND resource_database_id=DB_ID()) GrantedExclusiveAppLocks;
'@ -Rows)
    if ($rows.Count -ne 1 -or [int]$rows[0].Spid -ne $ExpectedSpid -or [int]$rows[0].TranCount -ne 1 -or
        [int]$rows[0].XactState -ne 1 -or [int]$rows[0].GrantedExclusiveAppLocks -ne 1) {
        throw 'JSON_APPLOCK_HOLDER_NOT_GRANTED'
    }
}
function New-ContenderStateDiagnostic($Rows,$ConnectionState,[int]$ExpectedSpid,$BlockError,$QueryError) {
    $rows = @($Rows)
    $row = if ($rows.Count -eq 1) { $rows[0] } else { $null }
    $isSqlBlock = $BlockError -is [Data.SqlClient.SqlException]
    $isSqlQuery = $QueryError -is [Data.SqlClient.SqlException]
    return [ordered]@{
        row_count=$rows.Count
        session_same=([bool]($null -ne $row -and [int]$row.Spid -eq $ExpectedSpid))
        expected_spid=$ExpectedSpid
        observed_spid=$(if ($row) { [int]$row.Spid } else { $null })
        trancount=$(if ($row) { [int]$row.TranCount } else { $null })
        xact_state=$(if ($row) { [int]$row.XactState } else { $null })
        connection_state=[string]$ConnectionState
        block_error_number=$(if ($isSqlBlock) { [int]$BlockError.Number } else { $null })
        block_error_state=$(if ($isSqlBlock) { [int]$BlockError.State } else { $null })
        block_error_message=$(if ($BlockError) { [string]$BlockError.Message } else { $null })
        state_query_error_type=$(if ($QueryError) { [string]$QueryError.GetType().FullName } else { $null })
        state_query_error_number=$(if ($isSqlQuery) { [int]$QueryError.Number } else { $null })
        state_query_error_state=$(if ($isSqlQuery) { [int]$QueryError.State } else { $null })
        state_query_error_message=$(if ($QueryError) { [string]$QueryError.Message } else { $null })
    }
}
function Acquire-HolderLock($Connection,[string]$Resource) {
    Sql $Connection 'BEGIN TRANSACTION;'
    $rows = @(Sql $Connection @'
DECLARE @r int;
EXEC @r=sys.sp_getapplock @Resource=@Resource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
SELECT @r LockResult,@@SPID Spid;
'@ @{ '@Resource'=$Resource } -Rows)
    if ($rows.Count -ne 1 -or [int]$rows[0].LockResult -lt 0) {
        Sql $Connection 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;'
        throw 'JSON_APPLOCK_HOLDER_ACQUIRE_FAILED'
    }
    $spid = [int]$rows[0].Spid
    Assert-HolderLock $Connection $spid
    return $spid
}
function Assert-ExpectedBlock($Connection,[string]$ExpectedText,[string]$BeforeSnapshot,[int]$ExpectedSpid) {
    $caught = $null
    try { Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.schema_deploy.path,[Text.Encoding]::UTF8)) }
    catch {
        $caught = $_.Exception
        while ($caught.InnerException) { $caught = $caught.InnerException }
    }
    if ($null -eq $caught -or $caught -isnot [Data.SqlClient.SqlException] -or
        $caught.Number -ne 55637 -or $caught.State -ne 1 -or
        -not $caught.Message.Contains($ExpectedText,[StringComparison]::Ordinal)) { throw 'JSON_APPLOCK_EXPECTED_CONTENDER_ERROR_MISMATCH' }
    $rows=@();$queryError=$null
    try { $rows=@(Sql $Connection 'SELECT @@SPID Spid,@@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows) }
    catch { $queryError=$_.Exception }
    $diagnostic=New-ContenderStateDiagnostic $rows $Connection.State $ExpectedSpid $caught $queryError
    $stateMatches=$null -eq $queryError -and $Connection.State -eq [Data.ConnectionState]::Open -and
        $diagnostic.row_count -eq 1 -and $diagnostic.session_same -and
        $diagnostic.trancount -eq 0 -and $diagnostic.xact_state -eq 0
    if (-not $stateMatches) {
        $script:ledger.diagnostics += @($diagnostic)
        Save-Journal
        throw 'JSON_APPLOCK_CONTENDER_TRANSACTION_REMAINS'
    }
    $locks = @(Sql $Connection 'SELECT COUNT(*) Count FROM sys.dm_tran_locks WHERE request_session_id=@@SPID AND resource_type=N''APPLICATION'';' -Rows)
    if ($locks.Count -ne 1 -or [int]$locks[0].Count -ne 0) { throw 'JSON_APPLOCK_CONTENDER_LOCK_REMAINS' }
    if ((Get-ModuleState $Connection) -cne $BeforeSnapshot) { throw 'JSON_APPLOCK_FAILED_DEPLOY_MUTATED_STATE' }
}
function Invoke-PositiveControl($Connection) {
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.schema_deploy.path,[Text.Encoding]::UTF8))
    $schemaId = [int](Read-Scalar $Connection "SELECT COALESCE(SCHEMA_ID(N'toolbelt_json'),0) AS ScalarValue;")
    $rows = @(Sql $Connection "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonSchema';" -Rows)
    $expected = @($script:runset.artifacts|Where-Object module_id -ceq 'toolbelt.json.schema')[0]
    if ($schemaId -le 0 -or $rows.Count -ne 1 -or $rows[0].Hash.ToLowerInvariant() -cne $expected.sha512 -or $rows[0].Permission -cne 'SAFE_ACCESS') {
        throw 'JSON_APPLOCK_POSITIVE_CONTROL_FAILED'
    }
    $version = @(Sql $Connection "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.Version';" -Rows)
    if ($version.Count -ne 1 -or $version[0].Value -cne '1.0.1') { throw 'JSON_APPLOCK_POSITIVE_CONTROL_METADATA' }
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.schema_uninstall.path,[Text.Encoding]::UTF8))
    Assert-SchemaAbsent $Connection
    Assert-CoreOnly $Connection
}

try {
    Assert-Runset
    Get-LabSelectorTarget
    if ($ValidateOnly) {
        Assert-RunsetStable
        Write-Output 'PASS JSON_SCHEMA_APPLOCK runset and exact READY selector validated; no SQL executed'
        return
    }
    $script:journal = Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $script:RunsetPath) 'case.json')
    if ($AuditOnly) {
        $prior = Get-Content -LiteralPath $script:journal -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert-AuditJournalCases $prior
        Assert-ReleaseInputs
        $control = Open-ReleaseConnection 'master'
        foreach ($database in $prior.databases) {
            if ($database.name -cne ('Toolbelt_Release_'+$prior.owner+'_l') -or $database.state -cne 'DROPPED') { throw 'JSON_APPLOCK_AUDIT_DATABASE_OWNER' }
            $found = @(Sql $control 'SELECT DB_ID(@Name) Id;' @{ '@Name'=$database.name } -Rows)
            if ($found.Count -ne 1 -or $null -ne $found[0].Id -and $found[0].Id -isnot [DBNull]) { throw 'JSON_APPLOCK_AUDIT_DATABASE_PRESENT' }
        }
        foreach ($trust in $prior.trust) {
            $actual = Get-ClrCallerTrust $control ([Convert]::FromHexString($trust.hash))
            if (($trust.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $trust.fingerprint)) -or
                (-not $trust.preexisting -and $null -ne $actual)) { throw 'JSON_APPLOCK_AUDIT_TRUST_DRIFT' }
        }
        Assert-ClrCallerConfiguration $control $prior.configuration
        Assert-ReleaseInputs
    } else {
        if (Test-Path -LiteralPath $script:journal) { throw 'JSON_APPLOCK_ALREADY_ATTEMPTED' }
        $script:ledger = [ordered]@{ owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();
            target=[ordered]@{platform='windows';version='2025';patch='CU8';compatibility_level=170};
            configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};results=@();diagnostics=@();failure=$null }
        Save-Journal
        $control = Open-ReleaseConnection 'master'
        $actual = @(Sql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
        if ($actual.Count -ne 1 -or [int]$actual[0].Major -ne 17 -or $actual[0].Platform -ine 'windows' -or [int]$actual[0].Admin -ne 1) {
            throw 'JSON_APPLOCK_ACTUAL_TARGET_MISMATCH'
        }
        $stage='CONFIGURATION';Assert-RunsetStable;Assert-ReleaseInputs;Start-ClrCallerConfiguration $control
        $stage='TRUST'
        foreach ($artifact in $script:runset.artifacts) {
            $hash = [Convert]::FromHexString($artifact.sha512)
            $before = Get-ClrCallerTrust $control $hash
            $entry = [ordered]@{hash=$artifact.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
            if ($before) { $entry.fingerprint=$before.Fingerprint }
            $script:ledger.trust += @($entry);Save-Journal
            if (-not $before) {
                Assert-ClrCallerTrustCleanupScope $control $hash
                $entry.state='ADDING';$entry.description='Contoso JSON AppLock test '+$script:ledger.owner+' '+$artifact.sql_name;Save-Journal
                Assert-RunsetStable;Assert-ReleaseInputs
                Sql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{ '@Hash'=$hash;'@Description'=$entry.description }
                $after=Get-ClrCallerTrust $control $hash
                if ($null -eq $after -or $after.description -cne $entry.description) { throw 'JSON_APPLOCK_TRUST_OWNERSHIP_UNKNOWN' }
                $entry.fingerprint=$after.Fingerprint;$entry.state='OWNED';Save-Journal
            }
        }
        $name='Toolbelt_Release_'+$script:ledger.owner+'_l'
        $entry=[ordered]@{name=$name;suffix='l';id=$null;created=$null;state='CREATING'}
        $script:ledger.databases += @($entry);Save-Journal
        Sql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Synthetic collision.',1; CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;"
        $identity=@(Sql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{ '@Name'=$name } -Rows)
        if ($identity.Count -ne 1) { throw 'JSON_APPLOCK_DATABASE_IDENTITY' }
        $entry.id=[int]$identity[0].Id;$entry.created=[string]$identity[0].Created;$entry.state='CREATED';Save-Journal
        $db=Open-ReleaseConnection $name
        Sql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{ '@Owner'=$script:ledger.owner }
        $entry.state='OWNED';Save-Journal
        Sql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=170;"
        $stage='INSTALL_BASELINE'
        Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.baseline.path,[Text.Encoding]::UTF8))
        Assert-CoreOnly $db
        Assert-SchemaAbsent $db
        foreach ($scenario in @(
                [ordered]@{resource='toolbelt.deploy.json.shared-core';message='JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.'},
                [ordered]@{resource='toolbelt.deploy.toolbelt.json.schema';message='JSON Schema lifecycle: Modul-AppLock nicht verfügbar.'})) {
            $stage='SCENARIO_'+$script:ledger.results.Count
            Assert-SchemaAbsent $db
            $snapshot=Get-ModuleState $db
            $holder=Open-ReleaseConnection $name
            $holderSpid=Acquire-HolderLock $holder $scenario.resource
            $contender=Open-ReleaseConnection $name
            $contenderSpid=[int](Read-Scalar $contender 'SELECT @@SPID AS ScalarValue;')
            Assert-ExpectedBlock $contender $scenario.message $snapshot $contenderSpid
            Assert-HolderLock $holder $holderSpid
            $releaseRows=@(Sql $holder 'ROLLBACK TRANSACTION; SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
            if ($releaseRows.Count -ne 1 -or [int]$releaseRows[0].TranCount -ne 0 -or [int]$releaseRows[0].XactState -ne 0) { throw 'JSON_APPLOCK_HOLDER_RELEASE_FAILED' }
            $remainingHolderLocks=@(Sql $holder 'SELECT COUNT(*) Count FROM sys.dm_tran_locks WHERE request_session_id=@@SPID AND resource_type=N''APPLICATION'';' -Rows)
            if ($remainingHolderLocks.Count -ne 1 -or [int]$remainingHolderLocks[0].Count -ne 0) { throw 'JSON_APPLOCK_HOLDER_LOCK_REMAINS' }
            $holder.Dispose();$contender.Dispose()
            $stage='POSITIVE_'+$script:ledger.results.Count
            Invoke-PositiveControl $db
            $script:ledger.results += @([ordered]@{resource=$scenario.resource;blocked=$true;positive_control=$true;snapshot_unchanged=$true})
            Save-Journal
        }
        $script:ledger.state='COMPLETE';Save-Journal
        Assert-ReleaseInputs
    }
} catch {
    $failure=$_.Exception
    if ($ValidateOnly) { throw }
    if ($ledger -and -not $AuditOnly) { $ledger.failure=[ordered]@{stage=$stage;privateDiagnostic=$failure.Message};Save-Journal }
} finally {
    foreach ($connection in $connections) { try { $connection.Dispose() } catch {} }
    [Data.SqlClient.SqlConnection]::ClearAllPools()
    if ($ledger -and -not $AuditOnly) {
        $cleanup=$true
        try {
            $control=Open-ReleaseConnection 'master'
            foreach ($database in $ledger.databases) { Assert-RunsetStable;Assert-ReleaseInputs;Assert-ReleaseOwnIdentity $control $database;$database.state='DROPPED';Save-Journal }
            foreach ($trust in $ledger.trust) {
                $hash=[Convert]::FromHexString($trust.hash);$actual=Get-ClrCallerTrust $control $hash
                if ($trust.preexisting) {
                    if ($null -eq $actual -or $actual.Fingerprint -cne $trust.fingerprint) { throw 'JSON_APPLOCK_PREEXISTING_TRUST_DRIFT' }
                    continue
                }
                if ($trust.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $trust.fingerprint -or $actual.description -cne $trust.description) {
                    throw 'JSON_APPLOCK_TRUST_CLEANUP_IDENTITY'
                }
                Assert-ClrCallerTrustCleanupScope $control $hash
                Assert-RunsetStable;Assert-ReleaseInputs
                Sql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{ '@Hash'=$hash }
                if ($null -ne (Get-ClrCallerTrust $control $hash)) { throw 'JSON_APPLOCK_TRUST_NOT_REMOVED' }
                $trust.state='REMOVED';Save-Journal
            }
            Assert-RunsetStable;Assert-ReleaseInputs;Restore-ClrCallerConfiguration $control
            $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-Journal
        } catch { $ledger.state='CLEANUP_BLOCKED';$ledger.privateCleanupDiagnostic=$_.Exception.Message;Save-Journal;$failure=$_.Exception }
        finally { if ($control) { $control.Dispose() } }
    }
}
if ($failure) { Write-Output 'FAIL JSON_SCHEMA_APPLOCK; inspect private journal; reconcile before retry'; exit 1 }
if ($AuditOnly) { Write-Output 'PASS JSON_SCHEMA_APPLOCK independent input/absence audit' }
else { Write-Output 'PASS JSON_SCHEMA_APPLOCK two lock conflicts and post-release positive controls; independent audit required' }
