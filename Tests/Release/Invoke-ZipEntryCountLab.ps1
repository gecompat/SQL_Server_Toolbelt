# Enger Grenztest für die bestehende ZIP-Metadaten-API.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,
    [switch]$AuditOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$script:clock = [Diagnostics.Stopwatch]::StartNew()
$script:cleanup = $false
$script:connections = [Collections.Generic.List[object]]::new()
$script:ledger = $null
$script:journal = $null
$script:runset = $null
$failure = $null
$stage = 'PREPARE'
$control = $null

# Importiert ausschließlich die bestehenden begrenzten Pin-, SQL- und
# Ownership-Helfer; kein Helper wird in diesem Skript angepasst.
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'), [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'ZIP_ENTRY_COUNT_IMPORT_HELPER_PARSE' }
$importNodes = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Import-ClrFunctions'
}, $true))
if ($importNodes.Count -ne 1) { throw 'ZIP_ENTRY_COUNT_IMPORT_HELPER_AMBIGUOUS' }
. ([scriptblock]::Create($importNodes[0].Extent.Text))
. (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1')
foreach ($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
    'Assert-ReleasePin', 'Assert-ReleasePrivatePath', 'Get-ReleaseTimeout', 'Invoke-ReleaseSql',
    'Open-ReleaseConnection', 'Invoke-ReleaseBatches', 'Save-ReleaseJournal',
    'Assert-ReleaseInputs', 'Assert-ReleaseOwnIdentity')) { . $block }
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')

function Assert-ZipEntryCountInputs {
    $hostPath = [IO.Path]::GetFullPath((Join-Path $PSHOME 'pwsh.exe'))
    if ($PSVersionTable.PSVersion.Major -lt 7 -or
        $hostPath -cne $script:runset.tools.powershell.path -or
        $PSVersionTable.PSVersion.ToString() -cne $script:runset.tools.powershell.version -or
        (Get-FileHash -LiteralPath $hostPath -Algorithm SHA256).Hash -cne $script:runset.tools.powershell.sha256) {
        throw 'ZIP_ENTRY_COUNT_PWSH_TOOL_DRIFT'
    }
    Assert-ReleaseInputs
    [void](Assert-ZipEntryCountDeploymentDiscovery (Join-Path $repo 'Modules') ([string[]]$script:runset.deployment_discovery))
    foreach ($path in @($script:runset.fixture, $script:runset.zip_10000.path,
                        $script:runset.zip_10001.path, $script:runset.exports.local,
                        $script:runset.exports.central)) {
        [void](Assert-ReleasePrivatePath ([string]$path))
    }
}

function Invoke-ZipEntryCountQuery($Connection, [byte[]]$Archive, [int]$MaxEntries) {
    $command = $Connection.CreateCommand()
    $command.CommandText = [IO.File]::ReadAllText($script:runset.fixture, [Text.Encoding]::UTF8)
    $command.CommandTimeout = Get-ReleaseTimeout
    $null = $command.Parameters.Add('@ZipArchive', [Data.SqlDbType]::VarBinary, -1)
    $command.Parameters['@ZipArchive'].Value = $Archive
    $null = $command.Parameters.Add('@MaxEntries', [Data.SqlDbType]::Int)
    $command.Parameters['@MaxEntries'].Value = $MaxEntries
    try { return [pscustomobject]@{ Command=$command; Reader=$command.ExecuteReader() } }
    catch { $command.Dispose(); throw }
}

function Assert-ZipEntryCountPositive($Connection, [byte[]]$Archive) {
    $invocation = Invoke-ZipEntryCountQuery $Connection $Archive 10000
    $reader = $invocation.Reader
    $expectedNames = @('EntryOrdinal', 'EntryName', 'IsDirectory', 'CompressedBytes', 'UncompressedBytes',
        'CompressionMethod', 'Crc32', 'IsEncrypted', 'IsExtractionSupported', 'DuplicateCount',
        'IsPathSafe', 'PathStatus', 'LastModifiedAt')
    $expectedTypes = @('int', 'nvarchar', 'bit', 'bigint', 'bigint', 'int', 'int', 'bit', 'bit', 'int',
        'bit', 'varchar', 'datetime2')
    $seen = [bool[]]::new(10000)
    $rows = 0
    $resultSets = 0
    try {
        do {
            $resultSets++
            if ($reader.FieldCount -ne $expectedNames.Count) { throw 'ZIP_ENTRY_COUNT_RESULT_SHAPE' }
            for ($column = 0; $column -lt $expectedNames.Count; $column++) {
                if ($reader.GetName($column) -cne $expectedNames[$column] -or
                    $reader.GetDataTypeName($column) -cne $expectedTypes[$column]) {
                    throw 'ZIP_ENTRY_COUNT_RESULT_SHAPE'
                }
            }
            while ($reader.Read()) {
                $ordinal = [int]$reader.GetValue(0)
                if ($ordinal -lt 1 -or $ordinal -gt 10000 -or $seen[$ordinal - 1]) {
                    throw 'ZIP_ENTRY_COUNT_ORDINAL'
                }
                $seen[$ordinal - 1] = $true
                $name = 'e' + ($ordinal - 1).ToString('D5', [Globalization.CultureInfo]::InvariantCulture) + '.txt'
                if ([string]$reader.GetValue(1) -cne $name -or
                    [bool]$reader.GetValue(2) -or [long]$reader.GetValue(3) -ne 0 -or
                    [long]$reader.GetValue(4) -ne 0 -or [int]$reader.GetValue(5) -ne 0 -or
                    [int]$reader.GetValue(6) -ne 0 -or [bool]$reader.GetValue(7) -or
                    -not [bool]$reader.GetValue(8) -or [int]$reader.GetValue(9) -ne 1 -or
                    -not [bool]$reader.GetValue(10) -or [string]$reader.GetValue(11) -cne 'safe' -or
                    $reader.IsDBNull(12) -or
                    ([datetime]$reader.GetValue(12)).ToString('yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture) -cne '2020-02-03 04:05:06') {
                    throw 'ZIP_ENTRY_COUNT_FIXED_ROW_ORACLE'
                }
                $rows++
                [void](Get-ReleaseTimeout)
            }
        } while ($reader.NextResult())
    } finally { $reader.Dispose(); $invocation.Command.Dispose() }
    if ($resultSets -ne 1 -or $rows -ne 10000 -or @($seen | Where-Object { -not $_ }).Count) {
        throw 'ZIP_ENTRY_COUNT_POSITIVE_COUNT'
    }
}

function Assert-ZipEntryCountFailureWithoutRows($Connection, [byte[]]$Archive, [int]$MaxEntries, [int]$ExpectedNumber) {
    $reader = $null
    $command = $Connection.CreateCommand()
    $command.CommandText = [IO.File]::ReadAllText($script:runset.fixture, [Text.Encoding]::UTF8)
    $command.CommandTimeout = Get-ReleaseTimeout
    $null = $command.Parameters.Add('@ZipArchive', [Data.SqlDbType]::VarBinary, -1)
    $command.Parameters['@ZipArchive'].Value = $Archive
    $null = $command.Parameters.Add('@MaxEntries', [Data.SqlDbType]::Int)
    $command.Parameters['@MaxEntries'].Value = $MaxEntries
    $rowCount = 0
    $caught = $null
    try {
        $reader = $command.ExecuteReader()
        do {
            while ($reader.Read()) {
                $rowCount++
                throw 'ZIP_ENTRY_COUNT_ERROR_RETURNED_ROW'
            }
        } while ($reader.NextResult())
    } catch {
        if ($_.Exception.Message -ceq 'ZIP_ENTRY_COUNT_ERROR_RETURNED_ROW') { throw }
        $caught = $_.Exception.GetBaseException()
    } finally {
        if ($reader) { $reader.Dispose() }
        $command.Dispose()
    }
    if ($rowCount -ne 0 -or $caught -isnot [Data.SqlClient.SqlException] -or $caught.Number -ne $ExpectedNumber) {
        throw 'ZIP_ENTRY_COUNT_ERROR_ATOMICITY_OR_NUMBER'
    }
}

try {
    $RunsetPath = Assert-ReleasePrivatePath $RunsetPath
    $script:runset = Get-Content -LiteralPath $RunsetPath -Raw | ConvertFrom-Json
    if ($script:runset.schema_version -cne 'zip-entry-count-caller/v1' -or
        $script:runset.cases.Count -ne 12 -or $script:runset.artifacts.Count -ne 1 -or
        $script:runset.artifacts[0].module_id -cne 'toolbelt.archive.zip-memory') {
        throw 'ZIP_ENTRY_COUNT_RUNSET_INVALID'
    }
    $expectedMatrix = @(foreach ($platform in @('linux', 'windows')) {
        foreach ($version in @('2019', '2022', '2025')) {
            $levels = switch ($version) { '2019' { @(150) } '2022' { @(150,160) } '2025' { @(150,160,170) } }
            foreach ($level in $levels) { "$platform/$version/$level" }
        }
    })
    $actualMatrix = @($script:runset.cases | ForEach-Object { "$($_.Platform)/$($_.Version)/$($_.CL)" })
    if ($actualMatrix.Count -ne 12 -or @($actualMatrix | Sort-Object -Unique).Count -ne 12 -or
        (($actualMatrix | Sort-Object) -join '|') -cne (($expectedMatrix | Sort-Object) -join '|')) {
        throw 'ZIP_ENTRY_COUNT_MATRIX_INVALID'
    }
    $case = $script:runset.cases[$CaseIndex]
    $expectedPatch = if ($case.Platform -ceq 'linux') { 'latest' } else { @{'2019'='cu32';'2022'='cu26';'2025'='cu8'}[[string]$case.Version] }
    if ($case.Patch -cne $expectedPatch -or
        $case.CL -notin @{ '2019'=@(150); '2022'=@(150,160); '2025'=@(150,160,170) }[[string]$case.Version]) {
        throw 'ZIP_ENTRY_COUNT_TARGET_INVALID'
    }
    $script:journal = Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-' + $CaseIndex + '.json'))
    Assert-ZipEntryCountInputs

    $required = @($PSCommandPath, $script:runset.fixture, $script:runset.zip_10000.path,
        $script:runset.zip_10001.path, $script:runset.exports.local, $script:runset.exports.central,
        (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),
        (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
        (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),
        (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
        (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),
        (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),
        (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1'))
    foreach ($path in $required) {
        if (@($script:runset.pins | Where-Object path -CEQ $path).Count -ne 1) { throw 'ZIP_ENTRY_COUNT_REQUIRED_PIN_MISSING' }
    }

    . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
    $labErrors = $null
    $labAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/CI/run-lab-local.ps1'), [ref]$null, [ref]$labErrors)
    if ($labErrors.Count) { throw 'ZIP_ENTRY_COUNT_LAB_HELPER_PARSE' }
    foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')) {
        $nodes = @($labAst.FindAll({ param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
        }, $true))
        if ($nodes.Count -ne 1) { throw 'ZIP_ENTRY_COUNT_LAB_HELPER_AMBIGUOUS' }
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    $contract = Resolve-LabContract -TestPurpose Functional
    if ((Get-FileHash -LiteralPath $contract.Path -Algorithm SHA256).Hash -cne $script:runset.contract_sha256) {
        throw 'ZIP_ENTRY_COUNT_LAB_CONTRACT_DRIFT'
    }
    $targets = @(Get-LabTargetsForSelector -Contract $contract.Contract -Selector $case)
    if ($targets.Count -ne 1) { throw 'ZIP_ENTRY_COUNT_EXACT_TARGET_REQUIRED' }
    $script:target = $targets[0]

    if ($AuditOnly) {
        $prior = Get-Content -LiteralPath $script:journal -Raw | ConvertFrom-Json
        if ($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$') {
            throw 'ZIP_ENTRY_COUNT_AUDIT_STATE'
        }
        if ($prior.case.index -ne $CaseIndex -or $prior.case.platform -cne $case.Platform -or
            $prior.case.version -cne $case.Version -or $prior.case.cl -ne $case.CL -or $prior.case.patch -cne $case.Patch) {
            throw 'ZIP_ENTRY_COUNT_AUDIT_CASE_DRIFT'
        }
        if ($prior.state -ceq 'COMPLETE' -and (($prior.completedModes -join '|') -cne 'local|central')) {
            throw 'ZIP_ENTRY_COUNT_AUDIT_COMPLETION_DRIFT'
        }
        $control = Open-ReleaseConnection 'master'
        foreach ($entry in $prior.databases) {
            if ($entry.name -cne ('Toolbelt_Release_' + $prior.owner + '_' + $entry.suffix) -or $entry.state -cne 'DROPPED') {
                throw 'ZIP_ENTRY_COUNT_AUDIT_IDENTITY'
            }
            $rows = @(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
            if ($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]) { throw 'ZIP_ENTRY_COUNT_DATABASE_REMAINS' }
        }
        foreach ($entry in $prior.trust) {
            $actual = Get-ClrCallerTrust $control ([Convert]::FromHexString($entry.hash))
            if (($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or
                (-not $entry.preexisting -and $null -ne $actual)) { throw 'ZIP_ENTRY_COUNT_AUDIT_TRUST_DRIFT' }
        }
        Assert-ClrCallerConfiguration $control $prior.configuration
        Assert-ZipEntryCountInputs
    } else {
        if (Test-Path -LiteralPath $script:journal) { throw 'ZIP_ENTRY_COUNT_CASE_ALREADY_ATTEMPTED' }
        $script:ledger = [ordered]@{
            owner=[guid]::NewGuid().ToString('N'); state='RUNNING'; databases=@(); trust=@();
            case=[ordered]@{index=$CaseIndex;platform=$case.Platform;version=$case.Version;cl=$case.CL;patch=$case.Patch};
            completedModes=@(); configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()}; failure=$null
        }
        Save-ReleaseJournal
        $control = Open-ReleaseConnection 'master'
        $actual = @(Invoke-ReleaseSql $control "SELECT @@VERSION VersionText,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
        if ($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
            $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1 -or
            [string]::IsNullOrWhiteSpace([string]$actual[0].VersionText)) { throw 'ZIP_ENTRY_COUNT_ACTUAL_TARGET_MISMATCH' }
        $inventory = @(Invoke-ReleaseSql $control 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
        if ($inventory.Count -lt 4 -or @($inventory | Where-Object state_desc -CNE 'ONLINE').Count) {
            throw 'ZIP_ENTRY_COUNT_DATABASE_INVENTORY_UNSAFE'
        }
        foreach ($artifact in $script:runset.artifacts) {
            $artifactPath = Assert-ReleasePrivatePath ([string]$artifact.path)
            if ((Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash -cne $artifact.sha256 -or
                (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA512).Hash -cne $artifact.sha512) {
                throw 'ZIP_ENTRY_COUNT_PACKAGE_DLL_DRIFT'
            }
        }
        $stage = 'CONFIGURATION'
        Start-ClrCallerConfiguration $control
        foreach ($artifact in $script:runset.artifacts) {
            $hash = [Convert]::FromHexString($artifact.sha512)
            $before = Get-ClrCallerTrust $control $hash
            $entry = [ordered]@{hash=$artifact.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
            if ($before) { $entry.fingerprint = $before.Fingerprint }
            $script:ledger.trust += @($entry); Save-ReleaseJournal
            if (-not $before) {
                Assert-ClrCallerTrustCleanupScope $control $hash
                $entry.state = 'ADDING'; $entry.description = 'Contoso ZIP entry-count ' + $script:ledger.owner; Save-ReleaseJournal
                Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
                $added = Get-ClrCallerTrust $control $hash
                if ($null -eq $added -or $added.description -cne $entry.description) { throw 'ZIP_ENTRY_COUNT_TRUST_OWNERSHIP_UNKNOWN' }
                $entry.fingerprint = $added.Fingerprint; $entry.state = 'OWNED'; Save-ReleaseJournal
            }
        }
        foreach ($mode in @('local','central')) {
            $stage = 'CREATE_' + $mode
            $suffix = if ($mode -ceq 'local') { 'l' } else { 'c' }
            $name = 'Toolbelt_Release_' + $script:ledger.owner + '_' + $suffix
            $entry = [ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'}
            $script:ledger.databases += @($entry); Save-ReleaseJournal
            Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
            $identity = @(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
            if ($identity.Count -ne 1) { throw 'ZIP_ENTRY_COUNT_DATABASE_IDENTITY' }
            $entry.id = $identity[0].Id; $entry.created = $identity[0].Created; $entry.state = 'CREATED'; Save-ReleaseJournal
            $db = Open-ReleaseConnection $name
            Invoke-ReleaseSql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{'@Owner'=$script:ledger.owner}
            $entry.state = 'OWNED'; Save-ReleaseJournal
            Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
            $stage = 'INSTALL_' + $mode
            Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.exports.$mode, [Text.Encoding]::UTF8))
            $versions = @(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
            if ($versions.Count -ne 2 -or @($versions | Where-Object { $_.name -ceq 'Toolbelt.Module.toolbelt.archive.zip-memory.Version' -and $_.Value -ceq '1.4.0' }).Count -ne 1 -or
                @($versions | Where-Object { $_.name -ceq 'Toolbelt.Module.toolbelt.core.result-table.Version' -and $_.Value -ceq '1.0.0' }).Count -ne 1) {
                throw 'ZIP_ENTRY_COUNT_MODULE_CLOSURE_DRIFT'
            }
            $assemblies = @(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
            if ($assemblies.Count -ne 1 -or @($assemblies | Where-Object { $_.name -ceq $script:runset.artifacts[0].sql_name -and $_.Hash -ceq $script:runset.artifacts[0].sha512 -and $_.Permission -ceq 'SAFE_ACCESS' }).Count -ne 1) {
                throw 'ZIP_ENTRY_COUNT_INSTALLED_ASSEMBLY_DRIFT'
            }
            $definitions = "SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash,a.assembly_id,a.assembly_class,a.assembly_method FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules a ON a.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;"
            $beforeDefinitions = @(Invoke-ReleaseSql $db $definitions -Rows) | ConvertTo-Json -Depth 4 -Compress
            $zip10k = [IO.File]::ReadAllBytes($script:runset.zip_10000.path)
            $zip10kPlusOne = [IO.File]::ReadAllBytes($script:runset.zip_10001.path)
            if (([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($zip10k))).ToLowerInvariant() -cne $script:runset.zip_10000.sha256 -or
                ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($zip10kPlusOne))).ToLowerInvariant() -cne $script:runset.zip_10001.sha256) {
                throw 'ZIP_ENTRY_COUNT_FIXTURE_DRIFT'
            }
            $db.Dispose(); $stage = 'CONTRACT_' + $mode; $db = Open-ReleaseConnection $name
            Assert-ZipEntryCountPositive $db $zip10k
            Assert-ZipEntryCountFailureWithoutRows $db $zip10kPlusOne 10000 51325
            Assert-ZipEntryCountFailureWithoutRows $db $zip10k 10001 51320
            $afterDefinitions = @(Invoke-ReleaseSql $db $definitions -Rows) | ConvertTo-Json -Depth 4 -Compress
            if ($beforeDefinitions -cne $afterDefinitions) { throw 'ZIP_ENTRY_COUNT_PRODUCT_OBJECT_DRIFT' }
            $db.Dispose(); $script:ledger.completedModes += @($mode); Save-ReleaseJournal
        }
        Assert-ZipEntryCountInputs
    }
} catch {
    $failure = $_.Exception
    if ($script:ledger -and -not $AuditOnly) {
        $script:ledger.failure = @{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace}
        Save-ReleaseJournal
    }
} finally {
    foreach ($connection in $script:connections) { try { $connection.Dispose() } catch {} }
    [Data.SqlClient.SqlConnection]::ClearAllPools()
    if ($script:ledger -and -not $AuditOnly) {
        $script:cleanup = $true
        try {
            $control = Open-ReleaseConnection 'master'
            foreach ($entry in $script:ledger.databases) {
                Assert-ReleaseOwnIdentity $control $entry
                $entry.state = 'DROPPED'; Save-ReleaseJournal
            }
            foreach ($entry in $script:ledger.trust) {
                $hash = [Convert]::FromHexString($entry.hash)
                $actual = Get-ClrCallerTrust $control $hash
                if ($entry.preexisting) {
                    if ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint) { throw 'ZIP_ENTRY_COUNT_PREEXISTING_TRUST_DRIFT' }
                    continue
                }
                if ($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description) {
                    throw 'ZIP_ENTRY_COUNT_TRUST_CLEANUP_IDENTITY'
                }
                Assert-ClrCallerTrustCleanupScope $control $hash
                Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
                if ($null -ne (Get-ClrCallerTrust $control $hash)) { throw 'ZIP_ENTRY_COUNT_TRUST_NOT_REMOVED' }
                $entry.state = 'REMOVED'; Save-ReleaseJournal
            }
            Restore-ClrCallerConfiguration $control
            $script:ledger.state = if ($failure) { 'FAILED_CLEANED' } else { 'COMPLETE' }; Save-ReleaseJournal
        } catch {
            $script:ledger.state = 'CLEANUP_BLOCKED'; $script:ledger.privateCleanupDiagnostic = $_.Exception.Message
            Save-ReleaseJournal; $failure = $_.Exception
        } finally { if ($control) { $control.Dispose() } }
    }
}

if ($failure) { Write-Output 'FAIL ZIP_ENTRY_COUNT; inspect private journal; do not replay without reconciliation'; exit 1 }
if ($AuditOnly) { 'PASS ZIP_ENTRY_COUNT independent database/trust/configuration audit' }
else { 'PASS ZIP_ENTRY_COUNT 10000/10001 local/direct-central; separate audit required' }
