#Requires -Version 7.5
[CmdletBinding()]
param(
    [string]$Python = '.runtime/sqlglot-spike-30.23.0/venv/Scripts/python.exe',
    [string]$Output = '.runtime/sql-dialect-performance/sql-server.json'
)

# Ein festes repräsentatives Hyper-V-Ziel. Nur eigene Session-Temp-Tabellen,
# keine Dienste, Serveroptionen, Cacheleerung oder Produktobjekte verändern.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Auch isoliert extrahierte Labfunktionen benötigen den gemeinsamen Reader.
. (Join-Path $PSScriptRoot '../../CI/LabQualifiedContract.ps1')

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$reportPath = [IO.Path]::GetFullPath((Join-Path $repoRoot $Output))
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime')) + [IO.Path]::DirectorySeparatorChar
if (-not $reportPath.StartsWith($runtimeRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'REPORT_OUTSIDE_RUNTIME' }
$directory = Split-Path -Parent $reportPath
[void][IO.Directory]::CreateDirectory($directory)
$fixturePath = Join-Path $directory 'performance-cases.json'
& (Join-Path $repoRoot $Python) (Join-Path $PSScriptRoot 'performance_cases.py') --output $fixturePath
if ($LASTEXITCODE -ne 0) { throw 'FIXTURE_GENERATION_FAILED' }
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -DateKind String
$sourceHashes = @{}
foreach ($name in @('performance_cases.py','run_performance_lab.ps1')) {
    $sourceHashes[$name] = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $name) -Algorithm SHA256).Hash
}
$tokens = $null; $parseErrors = $null
$helperPath = Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'
$helperHash = (Get-FileHash -LiteralPath $helperPath -Algorithm SHA256).Hash
$ast = [Management.Automation.Language.Parser]::ParseFile($helperPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'LAB_HELPER_SYNTAX' }
foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady',
                    'Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')) {
    $definitions = @($ast.FindAll({param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true))
    if ($definitions.Count -ne 1) { throw 'LAB_HELPER_NOT_UNIQUE' }
    . ([scriptblock]::Create($definitions[0].Extent.Text))
}

function Invoke-OwnedSql {
    param([Data.SqlClient.SqlConnection]$Connection, [string]$Sql, [int]$Size = 0)
    $command = $Connection.CreateCommand()
    try {
        $command.CommandText = $Sql; $command.CommandTimeout = 120
        if ($Size) { [void]$command.Parameters.Add('@Size',[Data.SqlDbType]::Int); $command.Parameters['@Size'].Value = $Size }
        [void]$command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

function Read-PerformanceQuery {
    param([Data.SqlClient.SqlConnection]$Connection, $Case, [switch]$Plan)
    $command = $Connection.CreateCommand()
    $command.CommandTimeout = 45
    $command.CommandText = if ($Plan) { "SET STATISTICS XML ON;`n" + $Case.sql + '; SET STATISTICS XML OFF;' } else { $Case.sql }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $keys = [Collections.Generic.List[string]]::new()
    $xml = $null
    try {
        $reader = $command.ExecuteReader()
        try {
            do {
                if ($reader.FieldCount -eq 4) {
                    while ($reader.Read()) {
                        $values = [string[]]::new(4)
                        for ($i=0; $i -lt 4; $i++) { $values[$i] = if ($reader.IsDBNull($i)) { 'N' } else { $reader.GetInt32($i).ToString([Globalization.CultureInfo]::InvariantCulture) } }
                        $keys.Add(($values -join ','))
                    }
                } elseif ($reader.FieldCount -eq 1 -and $Plan) {
                    while ($reader.Read()) { $xml = $reader.GetString(0) }
                } elseif ($reader.FieldCount -ne 0) { throw 'UNEXPECTED_RESULTSET' }
            } while ($reader.NextResult())
        } finally { $reader.Dispose() }
    } finally { $watch.Stop(); $command.Dispose() }
    # Vergleich und Sortierung liegen außerhalb der gemessenen Readerzeit.
    $rows = $keys.ToArray()
    if (-not $Case.ordered) { [Array]::Sort($rows, [StringComparer]::Ordinal) }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($rows -join "`n") + "`n")
    $sha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    return [pscustomobject]@{ rows=$rows.Count; sha256=$sha; elapsed_ms=$watch.Elapsed.TotalMilliseconds; xml=$xml }
}

function Assert-PerformanceRows {
    param($Actual, $Wanted)
    if ($Actual.rows -ne $Wanted.rows -or $Actual.sha256 -cne $Wanted.sha256) { throw 'RESULT_ORACLE_MISMATCH' }
}

$setup = @'
SET NOCOUNT ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;
SET QUOTED_IDENTIFIER ON; SET NUMERIC_ROUNDABORT OFF;
WITH D(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),
N AS (SELECT a.n+10*b.n+100*c.n+1000*d.n i FROM D a CROSS JOIN D b CROSS JOIN D c CROSS JOIN D d)
INSERT #PerfParent SELECT i+1,CASE WHEN i%97=0 THEN NULL WHEN i%113=0 THEN 1001 ELSE i%1000+1 END,
CASE WHEN i%89=0 THEN NULL ELSE DATEADD(second,((@Size/1000)*CASE WHEN i<1000 THEN 1 ELSE 3 END/4)/2,CAST('20260101' AS datetime2(6))) END FROM N WHERE i<2000;
WITH D(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),
N AS (SELECT a.n+10*b.n+100*c.n+1000*d.n+10000*e.n+100000*f.n i FROM D a CROSS JOIN D b CROSS JOIN D c CROSS JOIN D d CROSS JOIN D e CROSS JOIN D f)
INSERT #PerfEvent SELECT i+1,CASE WHEN i%997=0 THEN NULL ELSE i%1000+1 END,
CASE WHEN i%97=0 THEN NULL ELSE (i/1000)/2 END,
CASE WHEN i%97=0 THEN NULL ELSE DATEADD(second,(i/1000)/2,CAST('20260101' AS datetime2(6))) END FROM N WHERE i<@Size;
CREATE STATISTICS PerfEventParentStats ON #PerfEvent(ParentId) WITH FULLSCAN;
'@

$report = [ordered]@{ generated_at=[DateTimeOffset]::UtcNow.ToString('o'); engine='SQL Server';
    status='not executed'; selector='windows/2025/cu8'; test_purpose='Functional';
    source_hashes=$sourceHashes; lab_helper_hash=$helperHash; fixture_hash=(Get-FileHash $fixturePath -Algorithm SHA256).Hash;
    cache_profile='warm buffers and plan cache; no shared cache flush'; cases=[Collections.Generic.List[object]]::new();
    unsafe_controls=[Collections.Generic.List[object]]::new(); datasets=[Collections.Generic.List[object]]::new() }
$connection = $null; $exitCode=2
try {
    $lab = Resolve-LabContract
    $targets = @(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version='2025';Patch='cu8'}))
    if ($targets.Count -ne 1 -or $targets[0].provider -cne 'hyperv') { throw 'EXACT_HYPERV_TARGET_UNAVAILABLE' }
    $target = $targets[0]
    $preflight = Invoke-LabPreflight -Entry $target -TestPurpose Functional
    $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target -TestPurpose Functional))
    $builder.Pooling = $false
    $connection = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString); $connection.Open()
    $report.actual_version=$preflight.ActualVersion
    $exitCode=0
    foreach ($dataset in $fixtures.datasets) {
        # DDL ohne RPC-Parameter im Session-Batch anlegen. Innerhalb eines
        # parametrisierten sp_executesql erzeugte #Tabellen wären danach weg.
        Invoke-OwnedSql $connection 'SET NOCOUNT ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET QUOTED_IDENTIFIER ON; SET NUMERIC_ROUNDABORT OFF; CREATE TABLE #PerfParent(RowId int NOT NULL PRIMARY KEY,ParentId int NULL,CutoffTime datetime2(6) NULL); CREATE TABLE #PerfEvent(EventId int NOT NULL,ParentId int NULL,EventTick int NULL,EventTime datetime2(6) NULL);'
        Invoke-OwnedSql $connection $setup $dataset.events
        $totalsCommand=$connection.CreateCommand()
        try {
            $totalsCommand.CommandText='SELECT COUNT_BIG(*),SUM(CONVERT(bigint,EventId)),SUM(CONVERT(bigint,COALESCE(ParentId,0))),SUM(CONVERT(bigint,CASE WHEN ParentId IS NULL THEN 1 ELSE 0 END)),SUM(CONVERT(bigint,CASE WHEN EventTime IS NULL THEN 1 ELSE 0 END)),SUM(CONVERT(bigint,COALESCE(EventTick,0))) FROM #PerfEvent;'
            $totalsReader=$totalsCommand.ExecuteReader()
            try {
                [void]$totalsReader.Read(); $i=0
                foreach ($name in @('events','sum_id','sum_parent','null_parent','null_time','sum_tick')) {
                    if ($totalsReader.GetInt64($i) -ne $dataset.totals.$name) { throw 'FIXTURE_TOTALS_MISMATCH' }; $i++
                }
            } finally { $totalsReader.Dispose() }
        } finally { $totalsCommand.Dispose() }
        $report.datasets.Add([pscustomobject]@{events=$dataset.events; status='validated'})
        foreach ($layout in @('heap','parent_index','global_index')) {
            if ($layout -ceq 'parent_index') { Invoke-OwnedSql $connection 'CREATE INDEX IX_PerfEvent_Parent_Time_Id ON #PerfEvent(ParentId,EventTime DESC,EventId DESC) INCLUDE(EventTick);' }
            if ($layout -ceq 'global_index') { Invoke-OwnedSql $connection 'CREATE INDEX IX_PerfEvent_Time_Id ON #PerfEvent(EventTime DESC,EventId DESC) INCLUDE(ParentId,EventTick);' }
            foreach ($case in $fixtures.tsql_cases) {
                if ($layout -ceq 'heap' -and $case.scenario -notin @('selective','global')) { continue }
                if ($layout -ceq 'global_index' -and $case.scenario -cne 'global') { continue }
                $entry=[ordered]@{events=$dataset.events;layout=$layout;name=$case.name;status='failed';batches=@()}
                try {
                    $wanted=$dataset.expected.($case.scenario)
                    $warm=@()
                    for ($w=0;$w -lt 2;$w++) { $actual=Read-PerformanceQuery $connection $case; Assert-PerformanceRows $actual $wanted; $warm+= $actual.elapsed_ms }
                    $inner=[Math]::Min(32,[Math]::Max(1,[Math]::Ceiling(100.0/[Math]::Max(0.01,$warm[-1]))))
                    $entry.inner_repetitions=[int]$inner
                    $batches=[Collections.Generic.List[object]]::new()
                    for ($batch=0;$batch -lt $fixtures.batches;$batch++) {
                        $samples=[Collections.Generic.List[double]]::new()
                        for ($sample=0;$sample -lt $fixtures.repetitions;$sample++) {
                            $elapsed=0.0
                            for ($iteration=0;$iteration -lt $inner;$iteration++) { $actual=Read-PerformanceQuery $connection $case; Assert-PerformanceRows $actual $wanted; $elapsed+=$actual.elapsed_ms }
                            $samples.Add($elapsed/$inner)
                        }
                        $batches.Add($samples.ToArray())
                    }
                    $entry.batches=$batches.ToArray()
                    $actual=Read-PerformanceQuery $connection $case -Plan; Assert-PerformanceRows $actual $wanted
                    if (-not $actual.xml) { throw 'ACTUAL_PLAN_MISSING' }
                    $planName=($dataset.events.ToString()+'_'+$layout+'_'+$case.name.Replace('/','_')+'.sqlplan')
                    [IO.File]::WriteAllText((Join-Path $directory $planName),$actual.xml)
                    $document=[xml]::new(); $document.XmlResolver=$null; $document.LoadXml($actual.xml)
                    $ns=[Xml.XmlNamespaceManager]::new($document.NameTable); $ns.AddNamespace('p','http://schemas.microsoft.com/sqlserver/2004/07/showplan')
                    $entry.plan_file=$planName
                    $entry.operators=@($document.SelectNodes('//p:RelOp',$ns) | ForEach-Object { $_.GetAttribute('PhysicalOp') })
                    $entry.runtime_counters=@($document.SelectNodes('//p:RunTimeCountersPerThread',$ns) | ForEach-Object {
                        $attrs=@{}; foreach ($attr in $_.Attributes) { $attrs[$attr.Name]=$attr.Value }; $attrs })
                    $entry.warnings=@($document.SelectNodes('//p:Warnings/*',$ns) | ForEach-Object { $_.LocalName })
                    $entry.status='validated'; $entry.rows=$actual.rows; $entry.result_sha256=$actual.sha256
                } catch {
                    $failure=$_.Exception.GetBaseException()
                    $entry.code=if ($failure -is [Data.SqlClient.SqlException]) { 'SQL_'+$failure.Number } else { 'QUERY_OR_ORACLE_FAILURE' }
                    $entry.failure_line=$_.InvocationInfo.ScriptLineNumber; $entry.failure_type=$failure.GetType().Name; $exitCode=1
                }
                $report.cases.Add([pscustomobject]$entry)
                Write-Output ($dataset.events.ToString()+'/'+$layout+'/'+$case.name+': '+$entry.status)
                if ($entry.status -cne 'validated') { throw 'CASE_FAILED_STOP_BOUND' }
            }
        }
        $unsafe=[pscustomobject]@{sql=$fixtures.unsafe_tsql;ordered=$false}
        $wrong=Read-PerformanceQuery $connection $unsafe
        if ($wrong.sha256 -ceq $dataset.expected.cutoff.sha256) { throw 'UNSAFE_REWRITE_CONTROL_FAILED' }
        $report.unsafe_controls.Add([pscustomobject]@{events=$dataset.events;status='validated';code='CUTOFF_AFTER_RANK_DETECTED'})
        Invoke-OwnedSql $connection 'DROP TABLE #PerfEvent; DROP TABLE #PerfParent;'
    }
    $report.status='validated'
} catch {
    $failure=$_.Exception.GetBaseException()
    $report.code=if ($failure -is [Data.SqlClient.SqlException]) { 'SQL_'+$failure.Number } else { 'LOCAL_LAB_OR_WORKLOAD_FAILURE' }
    $report.failure_line=$_.InvocationInfo.ScriptLineNumber; $report.failure_type=$failure.GetType().Name
    if ($exitCode -eq 0) { $exitCode=1 }; $report.status=if($exitCode -eq 2){'not executed'}else{'failed'}
} finally {
    if ($null -ne $connection) { $connection.Dispose() } # Nicht gepoolt: eigene #Tabellen verschwinden sicher.
    Remove-Variable lab,target,targets,builder -ErrorAction SilentlyContinue
}
foreach ($name in $sourceHashes.Keys) { if ((Get-FileHash (Join-Path $PSScriptRoot $name) -Algorithm SHA256).Hash -cne $sourceHashes[$name]) { $report.status='failed';$report.code='SOURCE_DRIFT';$exitCode=1 } }
if ((Get-FileHash $helperPath -Algorithm SHA256).Hash -cne $helperHash) { $report.status='failed';$report.code='SOURCE_DRIFT';$exitCode=1 }
$report | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $reportPath -Encoding utf8
exit $exitCode
