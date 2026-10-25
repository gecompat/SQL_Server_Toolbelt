#Requires -Version 7.5
[CmdletBinding()]
param(
    [string]$Python = '.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe',
    [string]$Output = '.runtime/sqlglot-spike-30.23.0/native-report.json',
    [ValidateSet('Functional', 'AuthenticatedTls', IgnoreCase=$false)][string]$TestPurpose = 'Functional',
    [switch]$SelfTest
)

# Ausschließlich feste synthetische SELECTs; keine Schema-/Servermutation.
# Vertragsauswahl und zweckgebundene Transportpolicy kommen aus dem kanonischen Runner.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Auch isoliert extrahierte Labfunktionen benötigen den gemeinsamen Reader.
. (Join-Path $PSScriptRoot '../../CI/LabQualifiedContract.ps1')

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))

function Assert-ProbeResult {
    param($Case, $Actual)
    if (@($Actual.columns).Count -ne @($Case.columns).Count) { throw 'COLUMN_COUNT' }
    for ($i = 0; $i -lt @($Case.columns).Count; $i++) {
        $wanted = $Case.columns[$i]
        $found = $Actual.columns[$i]
        foreach ($property in $wanted.PSObject.Properties) {
            if ([string]$found.($property.Name) -cne [string]$property.Value) { throw ('COLUMN_' + $property.Name) }
        }
    }
    $wantedRows = @($Case.expected_rows | ForEach-Object { ConvertTo-Json -InputObject $_ -Compress -Depth 4 })
    $actualRows = @($Actual.rows | ForEach-Object { ConvertTo-Json -InputObject $_ -Compress -Depth 4 })
    if (-not $Case.ordered) {
        $wantedRows = @($wantedRows | Sort-Object -CaseSensitive)
        $actualRows = @($actualRows | Sort-Object -CaseSensitive)
    }
    if ($wantedRows.Count -ne $actualRows.Count -or
        ($wantedRows -join "`n") -cne ($actualRows -join "`n")) { throw 'RESULT_BAG_OR_ORDER' }
    # NULL-Wertprüfung und Metadaten-Nullability sind getrennte Aussagen.
    for ($i = 0; $i -lt @($Actual.columns).Count; $i++) {
        foreach ($row in $Actual.rows) {
            if ($null -eq $row[$i] -and -not $Actual.columns[$i].nullable) { throw 'NULLABILITY_CONTRADICTION' }
        }
    }
}

function Test-ProbeOracle {
    # Negativkontrollen prüfen den tatsächlichen Vergleicher ohne Netzwerk.
    $case = '{"columns":[{"name":"v","sql_type":"int","clr_type":"System.Int32"}],"expected_rows":[["1"],[null],["1"]],"ordered":false}' | ConvertFrom-Json
    $good = '{"columns":[{"name":"v","sql_type":"int","clr_type":"System.Int32","nullable":true}],"rows":[[null],["1"],["1"]]}' | ConvertFrom-Json
    Assert-ProbeResult $case $good
    $faults = @(
        '{"columns":[{"name":"v","sql_type":"int","clr_type":"System.Int32","nullable":true}],"rows":[[null],["1"]]}',
        '{"columns":[{"name":"v","sql_type":"int","clr_type":"System.Int32","nullable":true}],"rows":[["0"],["1"],["1"]]}',
        '{"columns":[{"name":"v","sql_type":"bigint","clr_type":"System.Int64","nullable":true}],"rows":[[null],["1"],["1"]]}',
        '{"columns":[{"name":"v","sql_type":"int","clr_type":"System.Int32","nullable":false}],"rows":[[null],["1"],["1"]]}'
    )
    foreach ($fault in $faults) {
        $rejected = $false
        try { Assert-ProbeResult $case ($fault | ConvertFrom-Json) } catch { $rejected = $true }
        if (-not $rejected) { throw 'ORACLE_ACCEPTED_FAULT' }
    }
    $case.ordered = $true
    $rejected = $false
    try { Assert-ProbeResult $case $good } catch { $rejected = $true }
    if (-not $rejected) { throw 'ORACLE_IGNORED_ORDER' }
    $typed = '{"columns":[{"name":"v","sql_type":"decimal","clr_type":"System.Decimal","precision":12,"scale":2,"size":17}],"expected_rows":[["1.25"]],"ordered":false}' | ConvertFrom-Json
    $actual = '{"columns":[{"name":"v","sql_type":"decimal","clr_type":"System.Decimal","precision":12,"scale":2,"size":17,"nullable":true}],"rows":[["1.25"]]}' | ConvertFrom-Json
    Assert-ProbeResult $typed $actual
    foreach ($property in @('precision', 'scale', 'size')) {
        $before = $actual.columns[0].$property
        $actual.columns[0].$property = $before + 1
        $rejected = $false
        try { Assert-ProbeResult $typed $actual } catch { $rejected = $true }
        if (-not $rejected) { throw 'ORACLE_IGNORED_TYPE_DIMENSION' }
        $actual.columns[0].$property = $before
    }
    Write-Output 'NATIVE_ORACLE_SELFTEST_PASS (2 positive, 8 negative controls)'
}

if ($SelfTest) { Test-ProbeOracle; exit 0 }

function Read-ProbeResult {
    param([Data.SqlClient.SqlConnection]$Connection, $Case)
    $command = $Connection.CreateCommand()
    $command.CommandTimeout = 30
    $command.CommandText = $Case.sql
    foreach ($binding in $Case.parameters) {
        # Festes INT-Profil; kein AddWithValue und kein Einsetzen in SQL-Text.
        if ($binding.type -cne 'Int') { throw 'UNSUPPORTED_FIXTURE_BINDING' }
        $parameter = $command.Parameters.Add('@' + $binding.name, [Data.SqlDbType]::Int)
        $parameter.Value = if ($null -eq $binding.value) { [DBNull]::Value } else { [int]$binding.value }
    }
    try {
        $reader = $command.ExecuteReader()
        try {
            $schema = $reader.GetSchemaTable()
            $columns = [Collections.Generic.List[object]]::new()
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $column = $schema.Rows[$i]
                $columns.Add([pscustomobject]@{
                    name = $reader.GetName($i); sql_type = $reader.GetDataTypeName($i)
                    clr_type = $reader.GetFieldType($i).FullName; nullable = [bool]$column.AllowDBNull
                    precision = if ($column.NumericPrecision -is [DBNull]) { $null } else { [int]$column.NumericPrecision }
                    scale = if ($column.NumericScale -is [DBNull]) { $null } else { [int]$column.NumericScale }
                    size = [int]$column.ColumnSize
                })
            }
            $rows = [Collections.Generic.List[object]]::new()
            while ($reader.Read()) {
                $row = [object[]]::new($reader.FieldCount)
                for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                    if ($reader.IsDBNull($i)) { $row[$i] = $null; continue }
                    $value = $reader.GetValue($i)
                    $row[$i] = if ($columns[$i].sql_type -eq 'date') {
                        $value.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
                    } elseif ($value -is [DateTime]) {
                        $value.ToString('yyyy-MM-ddTHH:mm:ss.fffffff', [Globalization.CultureInfo]::InvariantCulture)
                    } elseif ($value -is [IFormattable]) {
                        $value.ToString($null, [Globalization.CultureInfo]::InvariantCulture)
                    } else { [string]$value }
                }
                $rows.Add($row)
            }
            if ($reader.NextResult()) { throw 'UNEXPECTED_RESULTSET' }
            return [pscustomobject]@{ rows = $rows.ToArray(); columns = $columns.ToArray() }
        } finally { $reader.Dispose() }
    } finally { $command.Dispose() }
}

function Get-ProbeFailureCode {
    param($ErrorRecord)
    $failure = $ErrorRecord.Exception
    while ($failure.InnerException) { $failure = $failure.InnerException }
    if ($failure -is [Data.SqlClient.SqlException]) { return ('SQL_' + $failure.Number) }
    # Nur eigene deterministische Codes veröffentlichen, keine Treibermeldungen.
    if ($failure.Message -cmatch '^(COLUMN_[a-z_]+|COLUMN_COUNT|RESULT_BAG_OR_ORDER|NULLABILITY_CONTRADICTION|UNEXPECTED_RESULTSET|SOURCE_DRIFT)$') {
        return $failure.Message
    }
    return ('CLIENT_' + $failure.GetType().Name)
}

$reportPath = [IO.Path]::GetFullPath((Join-Path $repoRoot $Output))
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime')) + [IO.Path]::DirectorySeparatorChar
if (-not $reportPath.StartsWith($runtimeRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'REPORT_OUTSIDE_RUNTIME' }
$pythonPath = if ([IO.Path]::IsPathRooted($Python)) { $Python } else { Join-Path $repoRoot $Python }
$casePath = Join-Path (Split-Path -Parent $reportPath) 'native-cases.json'
& $pythonPath (Join-Path $PSScriptRoot 'build_native_cases.py') --output $casePath
if ($LASTEXITCODE -ne 0) { throw 'CASE_GENERATION_FAILED' }
# ISO-Zeitwerte sind Vergleichsstrings, keine impliziten Client-DateTime-Werte.
$fixtures = Get-Content -LiteralPath $casePath -Raw | ConvertFrom-Json -DateKind String

# Funktionsdefinitionen lesen, niemals den allgemeinen mutierenden Runner starten.
$tokens = $null; $parseErrors = $null
$labHelper = Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile($labHelper, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'LAB_HELPER_SYNTAX' }
foreach ($name in @('Get-EnvironmentVariableValue', 'Resolve-LabContract', 'Test-LabTargetReady',
                    'Get-LabTargetsForSelector', 'New-LabConnectionString', 'Invoke-LabPreflight')) {
    $definitions = @($ast.FindAll({ param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true))
    if ($definitions.Count -ne 1) { throw 'LAB_HELPER_NOT_UNIQUE' }
    . ([scriptblock]::Create($definitions[0].Extent.Text))
}
$helperHash = (Get-FileHash -LiteralPath $labHelper -Algorithm SHA256).Hash
$report = [ordered]@{
    generated_at = [DateTimeOffset]::UtcNow.ToString('o'); source_hashes = $fixtures.source_hashes
    lab_helper_hash = $helperHash; sqlglot_version = $fixtures.sqlglot_version
    sqlclient_assembly_version = [Data.SqlClient.SqlConnection].Assembly.GetName().Version.ToString()
    databricks_execution = 'not executed'; performance = 'not executed'
    test_purpose = $TestPurpose; authenticated_tls_qualification = 'not executed'
    cases_per_target = @($fixtures.cases).Count; roundtrip_rejections = $fixtures.roundtrip_rejections
    targets = [Collections.Generic.List[object]]::new()
}
try { $lab = Resolve-LabContract } catch {
    # Schema-/Discoveryfehler können private Dateipfade enthalten.
    throw 'LAB_CONTRACT_INVALID_OR_MISSING'
}
$exitCode = 0
foreach ($platform in @('linux', 'windows')) {
    foreach ($version in @('2019', '2022', '2025')) {
        $patch = if ($platform -ceq 'linux') { 'latest' } else { 'base' }
        $selector = [pscustomobject]@{ Platform = $platform; Version = $version; Patch = $patch }
        $targets = @(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $selector)
        if (-not $targets.Count) {
            $report.targets.Add([pscustomobject]@{ platform = $platform; version = $version; requested_patch = $patch
                status = 'not executed'; code = 'NO_READY_TARGET'; cases = @() })
            if ($exitCode -eq 0) { $exitCode = 2 }
        }
        foreach ($target in $targets) {
            $targetReport = [ordered]@{ platform = $platform; version = $version; requested_patch = $patch
                selected_patch = [string]$target.patch; provider = [string]$target.provider
                status = 'not executed'; cases = [Collections.Generic.List[object]]::new() }
            $connection = $null
            try {
                if ($target.encrypt -isnot [bool] -or $target.encrypt -ne $true -or
                    $target.trustServerCertificate -isnot [bool] -or
                    ($TestPurpose -ceq 'AuthenticatedTls' -and $target.trustServerCertificate)) {
                    $targetReport.code = 'TLS_CONTRACT_REJECTED'
                    if ($exitCode -eq 0) { $exitCode = 2 }
                    continue
                }
                $preflight = Invoke-LabPreflight -Entry $target -TestPurpose $TestPurpose
                $targetReport.actual_version = $preflight.ActualVersion
                $connection = [Data.SqlClient.SqlConnection]::new((New-LabConnectionString -Entry $target -TestPurpose $TestPurpose))
                $connection.Open()
                $targetReport.encrypted = $true
                $targetReport.trust_server_certificate = $target.trustServerCertificate
                $targetReport.server_certificate_validation = if ($target.trustServerCertificate) { 'bypassed_by_lab_contract' } else { 'validated_by_sqlclient' }
                $settings = $connection.CreateCommand()
                try {
                    $settings.CommandText = 'SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET QUOTED_IDENTIFIER ON; SET NUMERIC_ROUNDABORT OFF; SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID();'
                    $settings.CommandTimeout = 30
                    $targetReport.compatibility_level = [int]$settings.ExecuteScalar()
                } finally { $settings.Dispose() }
                foreach ($case in $fixtures.cases) {
                    $caseReport = [ordered]@{ name = $case.name; status = 'failed' }
                    try {
                        $actual = Read-ProbeResult $connection $case
                        # Auch Abweichungen bleiben lokal für die Diagnose erhalten.
                        $caseReport.result = $actual
                        Assert-ProbeResult $case $actual
                        $caseReport.status = 'validated'
                    } catch {
                        $caseReport.code = Get-ProbeFailureCode $_
                        $exitCode = 1
                    }
                    $targetReport.cases.Add([pscustomobject]$caseReport)
                }
                $targetReport.status = if (@($targetReport.cases | Where-Object status -eq 'failed').Count) { 'failed' } else { 'validated' }
            } catch {
                $targetReport.code = Get-ProbeFailureCode $_
                if ($exitCode -eq 0) { $exitCode = 2 }
            } finally {
                if ($null -ne $connection) { $connection.Dispose() }
                $report.targets.Add([pscustomobject]$targetReport)
                Write-Output ("$platform/$version/$($target.patch): " + $targetReport.status)
            }
        }
    }
}
# Testbindung erneut prüfen: parallele Änderungen machen den Lauf ungültig.
foreach ($entry in $fixtures.source_hashes.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $entry.Name) -Algorithm SHA256).Hash -ine $entry.Value) {
        $report.source_drift = $true; $exitCode = 1
    }
}
if ((Get-FileHash -LiteralPath $labHelper -Algorithm SHA256).Hash -cne $helperHash) {
    $report.source_drift = $true; $exitCode = 1
}
$report | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $reportPath -Encoding utf8
Remove-Variable lab, target, targets -ErrorAction SilentlyContinue
exit $exitCode
