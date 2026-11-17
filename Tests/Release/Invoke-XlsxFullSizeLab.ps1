# Gemeinsamer Paket-/Ownershipkern für originale Größen-, Zell- und Clientfälle.
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
$cellApi = $false

# Importiert ausschließlich die bestehenden begrenzten Pin-, SQL- und
# Ownership-Helfer; kein Helper wird in diesem Skript angepasst.
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'), [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'XLSX_FULL_SIZE_IMPORT_HELPER_PARSE' }
$importNodes = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Import-ClrFunctions'
}, $true))
if ($importNodes.Count -ne 1) { throw 'XLSX_FULL_SIZE_IMPORT_HELPER_AMBIGUOUS' }
. ([scriptblock]::Create($importNodes[0].Extent.Text))
. (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1')
foreach ($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
    'Assert-ReleasePin', 'Assert-ReleasePrivatePath', 'Get-ReleaseTimeout', 'Invoke-ReleaseSql',
    'Open-ReleaseConnection', 'Invoke-ReleaseBatches', 'Save-ReleaseJournal',
    'Assert-ReleaseInputs', 'Assert-ReleaseOwnIdentity')) { . $block }
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
. (Join-Path $PSScriptRoot 'Xlsx.OwnedDatabase.ps1')

function Assert-XlsxFullSizeInputs {
    $hostPath = [IO.Path]::GetFullPath((Join-Path $PSHOME 'pwsh.exe'))
    if ($PSVersionTable.PSVersion.Major -lt 7 -or
        $hostPath -cne $script:runset.tools.powershell.path -or
        $PSVersionTable.PSVersion.ToString() -cne $script:runset.tools.powershell.version -or
        (Get-FileHash -LiteralPath $hostPath -Algorithm SHA256).Hash -cne $script:runset.tools.powershell.sha256) {
        throw 'XLSX_FULL_SIZE_PWSH_TOOL_DRIFT'
    }
    Assert-ReleaseInputs
    [void](Assert-ZipEntryCountDeploymentDiscovery (Join-Path $repo 'Modules') ([string[]]$script:runset.deployment_discovery))
    foreach ($path in @($script:runset.fixture) + @($script:runset.workbooks.path) +
                        @($script:runset.exports.local.PSObject.Properties.Value) +
                        @($script:runset.exports.central.PSObject.Properties.Value)) {
        [void](Assert-ReleasePrivatePath ([string]$path))
    }
}

function Invoke-XlsxFullSizeQuery($Connection, [byte[]]$Workbook) {
    $command = $Connection.CreateCommand()
    $command.CommandText = [IO.File]::ReadAllText($script:runset.fixture, [Text.Encoding]::UTF8)
    $command.CommandTimeout = Get-ReleaseTimeout
    $null = $command.Parameters.Add('@XlsxBinary', [Data.SqlDbType]::VarBinary, -1)
    $command.Parameters['@XlsxBinary'].Value = $Workbook
    try { return [pscustomobject]@{ Command=$command; Reader=$command.ExecuteReader() } }
    catch { $command.Dispose(); throw }
}

function Assert-XlsxFullSizePositive($Connection, [byte[]]$Workbook) {
    $invocation = Invoke-XlsxFullSizeQuery $Connection $Workbook
    $reader = $invocation.Reader
    $expectedNames = @('RowOrdinal','ColumnOrdinal','StoredType','ValuePresent','RawValue','TextValue',
        'FormulaPresent','FormulaText','FormulaKind','SharedFormulaIndex','CachePresent','CacheValue')
    $expectedTypes = @('int','int','nvarchar','bit','nvarchar','nvarchar','bit','nvarchar','nvarchar','int','bit','nvarchar')
    $rows = 0; $resultSets = 0
    try {
        do {
            $resultSets++
            if ($reader.FieldCount -ne 12) { throw 'XLSX_FULL_SIZE_RESULT_SHAPE' }
            for ($column=0; $column -lt 12; $column++) {
                if ($reader.GetName($column) -cne $expectedNames[$column] -or $reader.GetDataTypeName($column) -cne $expectedTypes[$column]) { throw 'XLSX_FULL_SIZE_RESULT_SHAPE' }
            }
            while ($reader.Read()) {
                if ([int]$reader.GetValue(0) -ne 1 -or [int]$reader.GetValue(1) -ne 1 -or
                    [string]$reader.GetValue(2) -cne 'n' -or -not [bool]$reader.GetValue(3) -or
                    $reader.IsDBNull(4) -or [string]$reader.GetValue(4) -cne '42' -or -not $reader.IsDBNull(5) -or
                    [bool]$reader.GetValue(6) -or -not $reader.IsDBNull(7) -or -not $reader.IsDBNull(8) -or
                    -not $reader.IsDBNull(9) -or [bool]$reader.GetValue(10) -or -not $reader.IsDBNull(11)) { throw 'XLSX_FULL_SIZE_FIXED_ROW_ORACLE' }
                $rows++; [void](Get-ReleaseTimeout)
            }
        } while ($reader.NextResult())
    } finally { $reader.Dispose(); $invocation.Command.Dispose() }
    if ($resultSets -ne 1 -or $rows -ne 1) { throw 'XLSX_FULL_SIZE_POSITIVE_COUNT' }
}

function Assert-XlsxFullSizeFailureWithoutRows($Connection, [byte[]]$Workbook, [string]$ExpectedError) {
    $reader = $null; $command = $Connection.CreateCommand(); $command.CommandText = [IO.File]::ReadAllText($script:runset.fixture, [Text.Encoding]::UTF8)
    $command.CommandTimeout = Get-ReleaseTimeout
    $null = $command.Parameters.Add('@XlsxBinary',[Data.SqlDbType]::VarBinary,-1); $command.Parameters['@XlsxBinary'].Value = $Workbook
    $rowCount=0; $caught=$null
    try { $reader=$command.ExecuteReader(); do { while($reader.Read()) { $rowCount++; throw 'XLSX_FULL_SIZE_ERROR_RETURNED_ROW' } } while($reader.NextResult()) }
    catch { if($_.Exception.Message -ceq 'XLSX_FULL_SIZE_ERROR_RETURNED_ROW'){throw}; $caught=$_.Exception.GetBaseException() }
    finally { if($reader){$reader.Dispose()}; $command.Dispose() }
    if($rowCount -ne 0 -or $caught -isnot [Data.SqlClient.SqlException] -or $caught.Number -ne 51520 -or
       $caught.Message -cne $ExpectedError) { throw 'XLSX_FULL_SIZE_FAILURE_ATOMICITY_OR_ORACLE' }
}

function Assert-XlsxFullSizeNeutral($Connection) {
    # Das bereits qualifizierte skalare Sitzungsorakel bleibt von Metadatenreads
    # getrennt: deren eigener AutoCommit kann XACT_STATE()=1 bei TranCount=0 zeigen.
    $session=@(Invoke-ReleaseSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
    if($session.Count -ne 1 -or $session[0].TranCount -ne 0 -or $session[0].XactState -ne 0){
        $script:ledger['sessionDiagnostic']=$session;Save-ReleaseJournal
        throw 'XLSX_FULL_SIZE_SESSION_NOT_NEUTRAL'
    }
}

try {
    $RunsetPath = Assert-ReleasePrivatePath $RunsetPath
    $script:runset = Get-Content -LiteralPath $RunsetPath -Raw | ConvertFrom-Json
    if ($script:runset.PSObject.Properties['qualification_scope']) {
        if ($script:runset.qualification_scope -cnotin @('cell-api-rest','cell-display-rest','cell-client-rest','genuine10-rest','genuine10-central-rest','genuine11-rest','lifecycle-negative-rest','future-collision-rest','type-future-collision-rest','caller-catalog-rest','marker-collision-rest','composition-consumer-rest')) { throw 'XLSX_CELL_SCOPE_INVALID' }
        $cellApi = $true
        . (Join-Path $PSScriptRoot 'Xlsx.CellApi.Workload.ps1')
        Assert-XlsxCellApiWorkload $script:runset $CaseIndex $repo
    }
    $expectedWorkbooks = if ($cellApi) { if($script:runset.qualification_scope -cin @('lifecycle-negative-rest','future-collision-rest','type-future-collision-rest','caller-catalog-rest','marker-collision-rest','composition-consumer-rest')){1}elseif($script:runset.qualification_scope -cin @('cell-display-rest','cell-client-rest','genuine10-rest','genuine10-central-rest','genuine11-rest')){2}else{4} } else { 8 }
    if ($script:runset.schema_version -cne 'xlsx-full-size-package/v1' -or
        $script:runset.cases.Count -ne 12 -or $script:runset.workbooks.Count -ne $expectedWorkbooks -or $script:runset.artifacts.Count -ne 2 -or
        @($script:runset.artifacts.module_id | Sort-Object -Unique).Count -ne 2 -or
        @($script:runset.artifacts | Where-Object { $_.module_id -notin @('toolbelt.archive.zip-memory','toolbelt.file.xlsx-memory') }).Count) {
        throw 'XLSX_FULL_SIZE_RUNSET_INVALID'
    }
    $expectedMatrix = @(foreach ($platform in @('linux', 'windows')) {
        foreach ($version in @('2019', '2022', '2025')) {
            $levels = switch ($version) { '2019' { @(150) } '2022' { @(150,160) } '2025' { @(150,160,170) } }
            foreach ($level in $levels) { "$platform/$version/$level" }
        }
    })
    $actualMatrix = @($script:runset.cases | ForEach-Object { "$($_.Platform)/$($_.Version)/$($_.CL)" })
    if ($actualMatrix.Count -ne 12 -or @($actualMatrix | Sort-Object -Unique).Count -ne 12 -or
        ($actualMatrix -join '|') -cne ($expectedMatrix -join '|')) {
        throw 'XLSX_FULL_SIZE_MATRIX_INVALID'
    }
    $case = $script:runset.cases[$CaseIndex]
    $modes = @(if($cellApi -and $script:runset.qualification_scope -ceq 'genuine10-central-rest'){'central'}elseif($cellApi -and $script:runset.qualification_scope -cin @('genuine10-rest','genuine10-central-rest') -and $CaseIndex -eq 0){'local'}elseif($cellApi -and $script:runset.qualification_scope -cin @('cell-display-rest','cell-client-rest') -and $CaseIndex -eq 11){'central'}else{'local';'central'})
    if($cellApi -and $script:runset.qualification_scope -cin @('genuine10-rest','genuine10-central-rest','genuine11-rest','future-collision-rest','type-future-collision-rest')){
        if($script:runset.qualification_scope -cin @('genuine11-rest','future-collision-rest')){
            . (Join-Path $PSScriptRoot 'Xlsx.Genuine11.Workload.ps1')
            Assert-XlsxGenuine11Inputs $script:runset $repo
        }else{
            . (Join-Path $PSScriptRoot 'Xlsx.Genuine10.Workload.ps1')
            Assert-XlsxGenuine10Inputs $script:runset $repo
        }
    }
    if($cellApi -and $script:runset.qualification_scope -ceq 'lifecycle-negative-rest'){
        . (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1')
        Assert-XlsxLifecycleNegativeInputs $script:runset $repo
    }
    if($cellApi -and $script:runset.qualification_scope -ceq 'future-collision-rest'){
        . (Join-Path $PSScriptRoot 'Xlsx.FutureCollision.Workload.ps1')
        Assert-XlsxFutureCollisionInputs $script:runset $repo
    }
    if($cellApi -and $script:runset.qualification_scope -ceq 'type-future-collision-rest'){
        . (Join-Path $PSScriptRoot 'Xlsx.TypeFutureCollision.Workload.ps1')
        Assert-XlsxTypeFutureCollisionInputs $script:runset $repo
    }
    if($cellApi -and $script:runset.qualification_scope -ceq 'caller-catalog-rest'){
        . (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1')
        Assert-XlsxCallerCatalogInputs $script:runset $repo
    }
    if($cellApi -and $script:runset.qualification_scope -ceq 'marker-collision-rest'){
        . (Join-Path $PSScriptRoot 'Xlsx.MarkerCollision.Workload.ps1')
        Assert-XlsxMarkerCollisionInputs $script:runset $repo
    }
    if($cellApi -and $script:runset.qualification_scope -ceq 'composition-consumer-rest'){
        . (Join-Path $PSScriptRoot 'Xlsx.CompositionConsumer.Workload.ps1')
        Assert-XlsxCompositionConsumerInputs $script:runset $repo
    }
    $caseWorkbooks = @($script:runset.workbooks | Where-Object {
        -not ($cellApi -and $script:runset.qualification_scope -ceq 'cell-client-rest' -and $CaseIndex -ge 9 -and $_.name -ceq 'Types.Metadata.ps1')
    })
    $expectedPatch = if ($case.Platform -ceq 'linux') { 'latest' } else { @{'2019'='cu32';'2022'='cu26';'2025'='cu8'}[[string]$case.Version] }
    if ($case.Patch -cne $expectedPatch -or
        $case.CL -notin @{ '2019'=@(150); '2022'=@(150,160); '2025'=@(150,160,170) }[[string]$case.Version]) {
        throw 'XLSX_FULL_SIZE_TARGET_INVALID'
    }
    $script:journal = Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-' + $CaseIndex + '.json'))
    Assert-XlsxFullSizeInputs

    $required = @($PSCommandPath, $script:runset.fixture,
        (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),
        (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
        (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),
        (Join-Path $PSScriptRoot 'Xlsx.OwnedDatabase.ps1'),
        (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
        (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),
        (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),
        (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1')) + @($script:runset.workbooks.path) + @($script:runset.exports.local.PSObject.Properties.Value) + @($script:runset.exports.central.PSObject.Properties.Value)
    foreach ($path in $required) {
        if (@($script:runset.pins | Where-Object path -CEQ $path).Count -ne 1) { throw 'XLSX_FULL_SIZE_REQUIRED_PIN_MISSING' }
    }

    . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
    $labErrors = $null
    $labAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/CI/run-lab-local.ps1'), [ref]$null, [ref]$labErrors)
    if ($labErrors.Count) { throw 'XLSX_FULL_SIZE_LAB_HELPER_PARSE' }
    foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')) {
        $nodes = @($labAst.FindAll({ param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
        }, $true))
        if ($nodes.Count -ne 1) { throw 'XLSX_FULL_SIZE_LAB_HELPER_AMBIGUOUS' }
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    $contract = Resolve-LabContract -TestPurpose Functional
    if ((Get-FileHash -LiteralPath $contract.Path -Algorithm SHA256).Hash -cne $script:runset.contract_sha256) {
        throw 'XLSX_FULL_SIZE_LAB_CONTRACT_DRIFT'
    }
    $targets = @(Get-LabTargetsForSelector -Contract $contract.Contract -Selector $case)
    if ($targets.Count -ne 1) { throw 'XLSX_FULL_SIZE_EXACT_TARGET_REQUIRED' }
    $script:target = $targets[0]

    if ($AuditOnly) {
        $prior = Get-Content -LiteralPath $script:journal -Raw | ConvertFrom-Json
        if ($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$') {
            throw 'XLSX_FULL_SIZE_AUDIT_STATE'
        }
        if ($prior.case.index -ne $CaseIndex -or $prior.case.platform -cne $case.Platform -or
            $prior.case.version -cne $case.Version -or $prior.case.cl -ne $case.CL -or $prior.case.patch -cne $case.Patch) {
            throw 'XLSX_FULL_SIZE_AUDIT_CASE_DRIFT'
        }
        if ($cellApi -and $prior.qualificationScope -cne $script:runset.qualification_scope){throw 'XLSX_CELL_AUDIT_SCOPE'}
        if ($prior.state -ceq 'COMPLETE' -and (($prior.completedModes -join '|') -cne ($modes -join '|'))) {
            throw 'XLSX_FULL_SIZE_AUDIT_COMPLETION_DRIFT'
        }
        if($prior.state -ceq 'COMPLETE'){
            $expectedResults=@(foreach($mode in $modes){foreach($book in $caseWorkbooks){$mode+'/'+$book.name+'/'+$book.expected_error}})
            $actualResults=@($prior.results|ForEach-Object{if($_.status -cne 'PASS'){throw 'XLSX_FULL_SIZE_AUDIT_RESULT_STATUS'};$_.mode+'/'+$_.name+'/'+$_.expected_error})
            if($actualResults.Count -ne ($modes.Count*$caseWorkbooks.Count) -or (($actualResults|Sort-Object)-join '|') -cne (($expectedResults|Sort-Object)-join '|')){throw 'XLSX_FULL_SIZE_AUDIT_RESULT_SET'}
            $expectedLifecycle=@(foreach($mode in $modes){foreach($action in @('InstallAndRepeat','Uninstall','UninstallAbsent')){$mode+'/'+$action}})
            $actualLifecycle=@($prior.lifecycle|ForEach-Object{if($_.status -cne 'PASS'){throw 'XLSX_FULL_SIZE_AUDIT_LIFECYCLE_STATUS'};$_.mode+'/'+$_.action})
            if($actualLifecycle.Count -ne (3*$modes.Count) -or (($actualLifecycle|Sort-Object)-join '|') -cne (($expectedLifecycle|Sort-Object)-join '|')){throw 'XLSX_FULL_SIZE_AUDIT_LIFECYCLE_SET'}
        }
        if($cellApi -and $script:runset.qualification_scope -cin @('genuine10-rest','genuine10-central-rest','genuine11-rest','future-collision-rest','type-future-collision-rest') -and $prior.state -ceq 'COMPLETE'){
            if(($prior.genuine.mode -join '|') -cne ($modes -join '|') -or @($prior.genuine|Where-Object status -CNE $(if($script:runset.qualification_scope -cin @('genuine11-rest','future-collision-rest')){'PASS_GENUINE_1_1'}else{'PASS_GENUINE_1_0'})).Count){throw 'XLSX_GENUINE10_AUDIT_BASELINE'}
        }
        if($cellApi -and $script:runset.qualification_scope -ceq 'lifecycle-negative-rest' -and $prior.state -ceq 'COMPLETE'){
            if(($prior.lifecycleNegatives.mode -join '|') -cne ($modes -join '|') -or
               @($prior.lifecycleNegatives|Where-Object {$_.status -cne 'PASS' -or $_.rollback -ne 4 -or $_.locks -ne 2 -or $_.visibility -ne 16}).Count){throw 'XLSX_LIFECYCLE_AUDIT_NEGATIVE_GROUPS'}
        }
        if($cellApi -and $script:runset.qualification_scope -ceq 'future-collision-rest' -and $prior.state -ceq 'COMPLETE'){
            if(($prior.futureCollisions.mode -join '|') -cne ($modes -join '|') -or
               @($prior.futureCollisions|Where-Object {$_.status -cne 'PASS' -or $_.legacyWitnesses -ne 5 -or ($_.completedFaults -join '|') -cne 'FuturePublic|ImitatedFuturePublic|FutureInternal|ImitatedFutureInternal'}).Count){throw 'XLSX_FUTURE_AUDIT_ORIGINAL_CASES'}
        }
        if($cellApi -and $script:runset.qualification_scope -ceq 'composition-consumer-rest' -and $prior.state -ceq 'COMPLETE'){
            Assert-XlsxCompositionConsumerJournal $prior
        }
        if($cellApi -and $script:runset.qualification_scope -ceq 'marker-collision-rest' -and $prior.state -ceq 'COMPLETE'){
            if(($prior.markerCollisions.mode -join '|') -cne ($modes -join '|') -or
               @($prior.markerCollisions|Where-Object {$_.status -cne 'PASS' -or $_.deployRejections -ne 5 -or $_.uninstallRejections -ne 1 -or ($_.completedFaults -join '|') -cne 'VersionUnknown|VersionPadded|ModePadded|MarkerPadded|MarkerMissing|Dependency'}).Count){throw 'XLSX_MARKER_COLLISION_AUDIT_SCOPE'}
        }
        if($cellApi -and $script:runset.qualification_scope -ceq 'caller-catalog-rest' -and $prior.state -ceq 'COMPLETE'){
            if(($prior.callerCatalog.mode -join '|') -cne ($modes -join '|') -or
               @($prior.callerCatalog|Where-Object {$_.status -cne 'PASS' -or $_.callerRejections -ne 8 -or $_.nullability -ne 1 -or ($_.profiles -join '|') -cne 'OFF/intact|OFF/doomed|ON/intact|ON/doomed'}).Count){throw 'XLSX_CALLER_CATALOG_AUDIT_SCOPE'}
        }
        if($cellApi -and $script:runset.qualification_scope -ceq 'type-future-collision-rest' -and $prior.state -ceq 'COMPLETE'){
            if(($prior.typeFutureCollisions.mode -join '|') -cne ($modes -join '|') -or
               @($prior.typeFutureCollisions|Where-Object {$_.status -cne 'PASS' -or $_.legacyWitnesses -ne 5 -or ($_.completedFaults -join '|') -cne 'FuturePublic|ImitatedFuturePublic|FutureInternal|ImitatedFutureInternal'}).Count){throw 'XLSX_TYPE_FUTURE_AUDIT_ORIGINAL_CASES'}
        }
        $control = Open-ReleaseConnection 'master'
        foreach ($entry in $prior.databases) {
            if ($entry.name -cne ('Toolbelt_Release_' + $prior.owner + '_' + $entry.suffix) -or $entry.state -cne 'DROPPED') {
                throw 'XLSX_FULL_SIZE_AUDIT_IDENTITY'
            }
            $rows = @(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
            if ($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]) { throw 'XLSX_FULL_SIZE_DATABASE_REMAINS' }
        }
        foreach ($entry in $prior.trust) {
            $actual = Get-ClrCallerTrust $control ([Convert]::FromHexString($entry.hash))
            if (($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or
                (-not $entry.preexisting -and $null -ne $actual)) { throw 'XLSX_FULL_SIZE_AUDIT_TRUST_DRIFT' }
        }
        Assert-ClrCallerConfiguration $control $prior.configuration
        Assert-XlsxFullSizeInputs
    } else {
        if (Test-Path -LiteralPath $script:journal) { throw 'XLSX_FULL_SIZE_CASE_ALREADY_ATTEMPTED' }
        $script:ledger = [ordered]@{
            owner=[guid]::NewGuid().ToString('N'); state='RUNNING'; databases=@(); trust=@();
            qualificationScope=$(if($cellApi){$script:runset.qualification_scope}else{'full-size'}); genuine=@(); lifecycleNegatives=@(); futureCollisions=@(); typeFutureCollisions=@(); callerCatalog=@(); markerCollisions=@(); compositions=@();
            case=[ordered]@{index=$CaseIndex;platform=$case.Platform;version=$case.Version;cl=$case.CL;patch=$case.Patch};
            completedModes=@(); results=@(); lifecycle=@(); configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()}; failure=$null
        }
        Save-ReleaseJournal
        $control = Open-ReleaseConnection 'master'
        $actual = @(Invoke-ReleaseSql $control "SELECT @@VERSION VersionText,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductUpdateLevel')) Patch,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
        if ($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
            $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1 -or
            [string]::IsNullOrWhiteSpace([string]$actual[0].VersionText)) { throw 'XLSX_FULL_SIZE_ACTUAL_TARGET_MISMATCH' }
        if($case.Platform -ceq 'windows' -and [string]$actual[0].Patch -ine [string]$case.Patch){throw 'XLSX_FULL_SIZE_ACTUAL_PATCH_MISMATCH'}
        $inventory = @(Invoke-ReleaseSql $control 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
        if ($inventory.Count -lt 4 -or @($inventory | Where-Object state_desc -CNE 'ONLINE').Count) {
            throw 'XLSX_FULL_SIZE_DATABASE_INVENTORY_UNSAFE'
        }
        $trustArtifacts=@($script:runset.artifacts)
        if($cellApi -and $script:runset.qualification_scope -cin @('genuine10-rest','genuine10-central-rest','genuine11-rest','future-collision-rest','type-future-collision-rest')){$trustArtifacts+=@($script:runset.legacy.artifact)}
        foreach ($artifact in $trustArtifacts) {
            $artifactPath = Assert-ReleasePrivatePath ([string]$artifact.path)
            if ((Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash -cne $artifact.sha256 -or
                (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA512).Hash -cne $artifact.sha512) {
                throw 'XLSX_FULL_SIZE_PACKAGE_DLL_DRIFT'
            }
        }
        $stage = 'CONFIGURATION'
        Start-ClrCallerConfiguration $control
        foreach ($artifact in $trustArtifacts) {
            $hash = [Convert]::FromHexString($artifact.sha512)
            $before = Get-ClrCallerTrust $control $hash
            $entry = [ordered]@{hash=$artifact.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
            if ($before) { $entry.fingerprint = $before.Fingerprint }
            $script:ledger.trust += @($entry); Save-ReleaseJournal
            if (-not $before) {
                Assert-ClrCallerTrustCleanupScope $control $hash
                $entry.state = 'ADDING'; $entry.description = 'Contoso XLSX full-size package ' + $script:ledger.owner; Save-ReleaseJournal
                Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
                $added = Get-ClrCallerTrust $control $hash
                if ($null -eq $added -or $added.description -cne $entry.description) { throw 'XLSX_FULL_SIZE_TRUST_OWNERSHIP_UNKNOWN' }
                $entry.fingerprint = $added.Fingerprint; $entry.state = 'OWNED'; Save-ReleaseJournal
            }
        }
        foreach ($mode in $modes) {
            $stage = 'CREATE_' + $mode
            $suffix = if ($mode -ceq 'local') { 'l' } else { 'c' }
            $db = New-XlsxFullSizeOwnedDatabase $control $suffix 'Latin1_General_100_CI_AS_SC' $case.CL
            $name = $db.Database
            if($cellApi -and $script:runset.qualification_scope -cin @('genuine10-rest','genuine10-central-rest','genuine11-rest','future-collision-rest','type-future-collision-rest')){
                $stage=$(if($script:runset.qualification_scope -cin @('genuine11-rest','future-collision-rest')){'GENUINE11_'}else{'GENUINE10_'})+$mode
                if($script:runset.qualification_scope -cin @('genuine11-rest','future-collision-rest')){Invoke-XlsxGenuine11Setup $db $mode}else{Invoke-XlsxGenuine10Setup $db $mode}
                $db.Dispose();$db=Open-ReleaseConnection $name
                if($script:runset.qualification_scope -ceq 'future-collision-rest'){$stage='FUTURE_COLLISION_'+$mode;$db=Invoke-XlsxFutureCollision $db $mode}
                if($script:runset.qualification_scope -ceq 'type-future-collision-rest'){$stage='TYPE_FUTURE_COLLISION_'+$mode;$db=Invoke-XlsxTypeFutureCollision $db $mode}
            }
            $stage = 'INSTALL_' + $mode
            Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.exports.$mode.Install, [Text.Encoding]::UTF8))
            $versions = @(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
            if ($versions.Count -ne 3 -or @($versions | Where-Object { $_.name -ceq 'Toolbelt.Module.toolbelt.archive.zip-memory.Version' -and $_.Value -ceq '1.4.0' }).Count -ne 1 -or
                @($versions | Where-Object { $_.name -ceq 'Toolbelt.Module.toolbelt.file.xlsx-memory.Version' -and $_.Value -ceq '1.2.0' }).Count -ne 1 -or
                @($versions | Where-Object { $_.name -ceq 'Toolbelt.Module.toolbelt.core.result-table.Version' -and $_.Value -ceq '1.0.0' }).Count -ne 1) {
                throw 'XLSX_FULL_SIZE_MODULE_CLOSURE_DRIFT'
            }
            $assemblies = @(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
            if ($assemblies.Count -ne 2) { throw 'XLSX_FULL_SIZE_INSTALLED_ASSEMBLY_COUNT' }
            foreach ($artifact in $script:runset.artifacts) {
                if (@($assemblies | Where-Object { $_.name -ceq $artifact.sql_name -and $_.Hash -ceq $artifact.sha512 -and $_.Permission -ceq 'SAFE_ACCESS' }).Count -ne 1) {
                throw 'XLSX_FULL_SIZE_INSTALLED_ASSEMBLY_DRIFT'
                }
            }
            $stage = 'REPEAT_' + $mode
            Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.exports.$mode.Repeat, [Text.Encoding]::UTF8))
            $repeated=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
            if($repeated.Count -ne 2){throw 'XLSX_FULL_SIZE_REPEAT_ASSEMBLY_COUNT'}
            foreach($artifact in $script:runset.artifacts){
                if(@($repeated|Where-Object {$_.name -ceq $artifact.sql_name -and $_.Hash -ceq $artifact.sha512 -and $_.Permission -ceq 'SAFE_ACCESS'}).Count -ne 1){throw 'XLSX_FULL_SIZE_REPEAT_ASSEMBLY_DRIFT'}
            }
            Assert-XlsxFullSizeNeutral $db
            $compatibility=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
            if($compatibility.Count -ne 1 -or $compatibility[0].CL -ne $case.CL){throw 'XLSX_FULL_SIZE_COMPATIBILITY_STATE'}
            $script:ledger.lifecycle += @(@{mode=$mode;action='InstallAndRepeat';status='PASS'}); Save-ReleaseJournal
            $definitions = "SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash,a.assembly_id,a.assembly_class,a.assembly_method FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules a ON a.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;"
            $beforeDefinitions = @(Invoke-ReleaseSql $db $definitions -Rows) | ConvertTo-Json -Depth 4 -Compress
            $db.Dispose(); $stage = 'CONTRACT_' + $mode; $db = Open-ReleaseConnection $name
            foreach ($workbook in $caseWorkbooks) {
                $bytes=[IO.File]::ReadAllBytes($workbook.path)
                if ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant() -cne $workbook.sha256) { throw 'XLSX_FULL_SIZE_FIXTURE_DRIFT' }
                if ($cellApi) {
                    if($script:runset.qualification_scope -cin @('cell-client-rest','genuine10-rest','genuine10-central-rest','genuine11-rest')){
                        $providers=New-XlsxClientBudgetProviders $script:clock (Get-ReleaseTimeout)
                        & $workbook.path -Connection $db -CommandTimeoutProvider $providers.Timeout -ReadBudgetProvider $providers.Read
                    }else{
                        Invoke-ReleaseBatches $db ([Text.Encoding]::UTF8.GetString($bytes))
                    }
                    Assert-XlsxFullSizeNeutral $db
                }
                elseif ($workbook.expected_error -ceq 'NONE') { Assert-XlsxFullSizePositive $db $bytes }
                else { Assert-XlsxFullSizeFailureWithoutRows $db $bytes $workbook.expected_error }
                $script:ledger.results += @(@{mode=$mode;name=$workbook.name;status='PASS';expected_error=$workbook.expected_error}); Save-ReleaseJournal
            }
            if($cellApi -and $script:runset.qualification_scope -ceq 'lifecycle-negative-rest'){Invoke-XlsxLifecycleNegative $db $mode}
            if($cellApi -and $script:runset.qualification_scope -ceq 'caller-catalog-rest'){Invoke-XlsxCallerCatalog $db $mode}
            if($cellApi -and $script:runset.qualification_scope -ceq 'marker-collision-rest'){Invoke-XlsxMarkerCollision $db $mode}
            if($cellApi -and $script:runset.qualification_scope -ceq 'composition-consumer-rest'){Invoke-XlsxCompositionConsumer $db $mode $control}
            $afterDefinitions = @(Invoke-ReleaseSql $db $definitions -Rows) | ConvertTo-Json -Depth 4 -Compress
            if ($beforeDefinitions -cne $afterDefinitions) { throw 'XLSX_FULL_SIZE_PRODUCT_OBJECT_DRIFT' }
            foreach ($action in @('Uninstall','UninstallAbsent')) {
                $stage=$action+'_'+$mode
                Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.exports.$mode.$action,[Text.Encoding]::UTF8))
                $empty=@(Invoke-ReleaseSql $db 'SELECT (SELECT COUNT(*) FROM sys.objects WHERE is_ms_shipped=0) Objects,(SELECT COUNT(*) FROM sys.assemblies WHERE is_user_defined=1) Assemblies;' -Rows)
                if ($empty.Count -ne 1 -or $empty[0].Objects -ne 0 -or $empty[0].Assemblies -ne 0) { throw 'XLSX_FULL_SIZE_UNINSTALL_REMAINS' }
                Assert-XlsxFullSizeNeutral $db
                $script:ledger.lifecycle += @(@{mode=$mode;action=$action;status='PASS'}); Save-ReleaseJournal
            }
            $db.Dispose(); $script:ledger.completedModes += @($mode); Save-ReleaseJournal
        }
        Assert-XlsxFullSizeInputs
    }
} catch {
    $failure = $_.Exception
    if ($script:ledger -and -not $AuditOnly) {
        $script:ledger.failure = @{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace}
        Save-ReleaseJournal
    }
    elseif($script:runset -and -not $AuditOnly){
        # Auch ein vor der Journalanlage abgewiesener Aufruf bleibt diagnostizierbar.
        $receipt=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('preflight-rejected-'+$CaseIndex+'.json'))
        $bytes=[Text.UTF8Encoding]::new($false).GetBytes((@{state='REJECTED_BEFORE_JOURNAL';stage=$stage;connection_count=$script:connections.Count;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace}|ConvertTo-Json -Depth 5))
        $stream=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
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
                    if ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint) { throw 'XLSX_FULL_SIZE_PREEXISTING_TRUST_DRIFT' }
                    continue
                }
                if ($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description) {
                    throw 'XLSX_FULL_SIZE_TRUST_CLEANUP_IDENTITY'
                }
                Assert-ClrCallerTrustCleanupScope $control $hash
                Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
                if ($null -ne (Get-ClrCallerTrust $control $hash)) { throw 'XLSX_FULL_SIZE_TRUST_NOT_REMOVED' }
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

if ($failure) { Write-Output 'FAIL XLSX_FULL_SIZE; inspect private journal; do not replay without reconciliation'; exit 1 }
if ($AuditOnly) { 'PASS XLSX_FULL_SIZE independent database/trust/configuration audit' }
elseif ($cellApi -and $script:runset.qualification_scope -ceq 'cell-client-rest') { 'PASS XLSX_CELL_CLIENT selected original metadata helpers; separate audit required' }
elseif ($cellApi) { 'PASS XLSX_CELL_API selected original fixtures; separate audit required' }
else { 'PASS XLSX_FULL_SIZE eight cases and package lifecycle local/direct-central; separate audit required' }
