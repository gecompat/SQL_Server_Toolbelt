[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][string]$OutputPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$runtime = Join-Path $root '.runtime'
$output = [IO.Path]::GetFullPath($OutputPath)
if ([IO.Path]::GetDirectoryName($output) -cne $runtime -or
    [IO.Path]::GetFileName($output) -notmatch '^parser-[a-f0-9]{12}$') { throw 'SCRIPT_PARSER_OUTPUT_SCOPE' }
foreach ($path in @($runtime)) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or -not $item.PSIsContainer) { throw 'SCRIPT_PARSER_RUNTIME_SCOPE' }
    }
}
if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath ($output + '.stages'))) { throw 'SCRIPT_PARSER_OUTPUT_NOT_FRESH' }
if ($PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { throw 'SCRIPT_PARSER_REQUIRES_PWSH7' }

$runsetFile = (Resolve-Path -LiteralPath $RunsetPath).Path
$runset = Get-Content -LiteralPath $runsetFile -Raw | ConvertFrom-Json
if ($runset.schema -cne 'edit-distance-package-runset/v1' -or
    @($runset.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'schema,tools' -or
    @($runset.tools.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'python,roslyn_csc,windows_powershell') { throw 'SCRIPT_PARSER_RUNSET_SCHEMA' }
foreach ($name in @('python','roslyn_csc','windows_powershell')) {
    $tool = $runset.tools.$name
    if (@($tool.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'path,sha256' -or
        -not [IO.Path]::IsPathRooted([string]$tool.path) -or [string]$tool.sha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'SCRIPT_PARSER_RUNSET_TOOL' }
}

$moduleRoot = Join-Path $root 'Modules/toolbelt.tsql.script-parser'
. (Join-Path $root 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$python = [string]$runset.tools.python.path
$csc = [string]$runset.tools.roslyn_csc.path
$winps = [string]$runset.tools.windows_powershell.path
$toolPins = @{}
foreach ($name in @('python','roslyn_csc','windows_powershell')) {
    $tool = $runset.tools.$name
    if (-not (Test-Path -LiteralPath $tool.path -PathType Leaf) -or
        (Get-FileHash -LiteralPath $tool.path -Algorithm SHA256).Hash -ine $tool.sha256) { throw 'SCRIPT_PARSER_TOOL_PIN' }
    $toolPins[[string]$tool.path] = [string]$tool.sha256
}

$helper = Join-Path $root 'Scripts/Release/script_parser_package.py'
$fixture = Join-Path $root 'Tests/Release/ScriptParserPackageContractInputs.json'
$package = Join-Path $root 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$owned = Join-Path $root 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$sources = @(
    'Modules/toolbelt.tsql.script-parser/Tests/Framework/ProviderTests.cs',
    'Modules/toolbelt.tsql.script-parser/Tests/Framework/TestInputs.cs',
    'Modules/toolbelt.tsql.script-parser/Tests/Framework/GuardTests.cs',
    'Modules/toolbelt.tsql.script-parser/Tests/Framework/Invoke-Contract.ps1',
    'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuard.cs',
    'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs',
    'Modules/toolbelt.tsql.script-parser/Clr/Properties/AssemblyInfo.cs',
    'Modules/toolbelt.tsql.script-parser/Clr/Toolbelt.Tsql.ScriptParser.csproj',
    'Modules/toolbelt.tsql.script-parser/module.yaml'
)
$pins = [ordered]@{}
$paths = @($package, ($package + '.sha256'), (Join-Path $root 'Releases/1.0.0/clr-qualification.json'), $owned,
    $helper, $fixture, $PSCommandPath, $runsetFile) + @($sources | ForEach-Object { Join-Path $root $_ })
foreach ($path in $paths) {
    $full = [IO.Path]::GetFullPath($path)
    if (-not $pins.Contains($full)) { $pins[$full] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant() }
}

$stageDir = $output + '.stages'
$null = [IO.Directory]::CreateDirectory($stageDir)
$stages = [Collections.Generic.List[object]]::new()
$actual = 0
$outputPins = @{}
function Invoke-Stage([string]$Name, [string]$File, [string[]]$Arguments, [int]$TimeoutMs) {
    $result = Invoke-OwnedProcess -FileName $File -Arguments $Arguments -TimeoutMilliseconds $TimeoutMs
    $record = [ordered]@{stage=$Name;exit_code=$result.ExitCode;stdout=$result.Stdout;stderr=$result.Stderr;capture_complete=$result.CaptureComplete}
    $stages.Add($record)
    [IO.File]::WriteAllText((Join-Path $stageDir ($Name + '.private.json')), ($record | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
    if ($result.ExitCode -ne 0 -or $result.Stderr.Length -ne 0 -or -not $result.CaptureComplete) { throw ('SCRIPT_PARSER_STAGE_' + $Name) }
    return $result.Stdout.Replace("`r`n", "`n")
}

try {
    $binding = Invoke-Stage 'package_binding' $python @('-B',$helper,'--root',$root,'--output',$output) 60000 | ConvertFrom-Json
    if ($binding.package_sha256 -cne '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287' -or
        $binding.provider.sha256 -cne '51dcb066f373d8a91c61320c04139c62332c9ad1b1e2db4d42bea6e703e7e75f' -or
        $binding.scriptdom.sha256 -cne 'c467c638ed53caba55ec1a4ae534990326ac1811046ef12775f5bbd46478b7cb') { throw 'SCRIPT_PARSER_PACKAGE_RESULT' }
    $provider = Join-Path $output 'Toolbelt.Tsql.ScriptParser.dll'
    $scriptdom = Join-Path $output 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    foreach ($path in @($provider,$scriptdom)) { $outputPins[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
    $providerExe = Join-Path $output 'ProviderTests.exe'
    $guardExe = Join-Path $output 'GuardTests.exe'
    $providerCompile = @('/nologo','/optimize+','/target:exe',('/out:'+$providerExe),('/reference:System.Data.dll'),('/reference:'+$provider),('/reference:'+$scriptdom),
        (Join-Path $moduleRoot 'Tests/Framework/ProviderTests.cs'),(Join-Path $moduleRoot 'Tests/Framework/TestInputs.cs'))
    [void](Invoke-Stage 'provider_compile' $csc $providerCompile 60000)
    $guardCompile = @('/nologo','/optimize+','/target:exe',('/out:'+$guardExe),('/reference:'+$scriptdom),
        (Join-Path $moduleRoot 'Clr/PreparseGuard.cs'),(Join-Path $moduleRoot 'Clr/PreparseGuardCore.cs'),
        (Join-Path $moduleRoot 'Tests/Framework/GuardTests.cs'),(Join-Path $moduleRoot 'Tests/Framework/TestInputs.cs'))
    [void](Invoke-Stage 'source_guard_compile' $csc $guardCompile 60000)
    foreach ($path in @($providerExe,$guardExe)) { $outputPins[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
    $guard = Invoke-Stage 'source_guard' $guardExe @() 30000
    if ($guard -cne "GUARD_PASS 60`n") { throw 'SCRIPT_PARSER_SOURCE_GUARD_ORACLE' }

    function Invoke-Provider([string[]]$CaseArguments) {
        $script:actual++
        $result = Invoke-Stage ('provider_case_' + $script:actual.ToString('D2')) $providerExe $CaseArguments 30000
        if ($result -cne "FRAMEWORK_PASS`n") { throw ('SCRIPT_PARSER_PROVIDER_ORACLE_' + $script:actual) }
    }
    Invoke-Provider @('parameters')
    foreach ($version in @(80,90,100,110,120,130,140,150,160,170)) { Invoke-Provider @('legacy',[string]$version) }
    $corpusRecord = Get-Content -LiteralPath $fixture -Raw | ConvertFrom-Json
    if ($corpusRecord.schema -cne 'script-parser-corpus/v1' -or $corpusRecord.corpus.Count -ne 16 -or
        (Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash.ToLowerInvariant() -cne '9d12f047c8b41badf0221135815fb2ae6e541bece775b2b0b6cec8f934429b21') { throw 'SCRIPT_PARSER_CORPUS_BINDING' }
    $expectedCorpus = @(
        'SELECT 1;',
        "SELECT N'𝄞é' AS [x];",
        'WITH c AS (SELECT 1 AS n) SELECT n FROM c WHERE EXISTS (SELECT 1);',
        'SELECT a.n FROM (SELECT 1 AS n) a JOIN (SELECT 2 AS n) b ON a.n=b.n CROSS APPLY (SELECT a.n) c;',
        'SELECT 1 UNION ALL SELECT 2 INTERSECT SELECT 3 EXCEPT SELECT 4;',
        'INSERT INTO dbo.t(n) VALUES(1); UPDATE dbo.t SET n=n+1; DELETE FROM dbo.t WHERE n>2;',
        'MERGE dbo.t AS t USING (SELECT 1 AS n) s ON t.n=s.n WHEN MATCHED THEN UPDATE SET n=s.n WHEN NOT MATCHED THEN INSERT(n) VALUES(s.n);',
        'CREATE TABLE dbo.t(n int NOT NULL CONSTRAINT pk PRIMARY KEY); CREATE INDEX ix ON dbo.t(n); ALTER TABLE dbo.t ADD x int; DROP TABLE dbo.t;',
        'CREATE PROCEDURE dbo.p AS BEGIN SELECT 1; END;',
        'CREATE FUNCTION dbo.f() RETURNS int AS BEGIN RETURN 1; END;',
        'CREATE TRIGGER dbo.tr ON dbo.t AFTER INSERT AS BEGIN SELECT 1; END;',
        'BEGIN TRY BEGIN TRANSACTION; SAVE TRANSACTION s; COMMIT; END TRY BEGIN CATCH ROLLBACK; THROW; END CATCH;',
        'CREATE ROLE demo; GRANT SELECT ON dbo.t TO demo; DENY INSERT ON dbo.t TO demo; REVOKE SELECT ON dbo.t FROM demo;',
        "/* quoted '' [ ] */ SELECT 1;`nGO`n-- unicode é`nSELECT 2;",
        ('SELECT ' + ('1+' * 120) + '1 WHERE ' + ('1=1 AND ' * 20) + '1=1;'),
        'SELECT 1;'
    )
    $corpus = @($corpusRecord.corpus)
    if ($corpus.Count -ne 16) { throw 'SCRIPT_PARSER_CORPUS_COUNT' }
    for ($i=0; $i -lt 16; $i++) { if ([string]$corpus[$i] -cne [string]$expectedCorpus[$i]) { throw ('SCRIPT_PARSER_CORPUS_CASE_' + $i) } }
    $corpus[$corpus.Count - 1] = 'SELECT 1 FROM (SELECT 1 AS n) a' + ((1..12 | ForEach-Object { ' CROSS JOIN (SELECT 1 AS n) b' + $_ }) -join '') + ';'
    $index = 0
    foreach ($version in @(150,160,170)) {
        foreach ($sql in $corpus) {
            $file = Join-Path $output ('corpus-' + $index.ToString('D2') + '.sql')
            [IO.File]::WriteAllText($file,$sql,[Text.UTF8Encoding]::new($false))
            $outputPins[$file] = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
            Invoke-Provider @('corpus',$file,[string]$version)
            $index++
        }
    }
    foreach ($case in @(
        @{Sql='SELECT SUM(x) OVER w FROM (VALUES(1))v(x) WINDOW w AS(ORDER BY x);';Positive=160;Negative=150},
        @{Sql='SELECT JSON_ARRAYAGG(x ORDER BY x) FROM (VALUES(1))v(x);';Positive=170;Negative=160}
    )) {
        $file = Join-Path $output ('version-' + $case.Positive + '.sql')
        [IO.File]::WriteAllText($file,$case.Sql,[Text.UTF8Encoding]::new($false))
        $outputPins[$file] = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        Invoke-Provider @('corpus',$file,[string]$case.Positive)
        Invoke-Provider @('negative',$file,[string]$case.Negative)
    }
    if ($actual -ne 63) { throw 'SCRIPT_PARSER_CHILD_COUNT' }
    if ((Get-FileHash -LiteralPath $provider -Algorithm SHA256).Hash.ToLowerInvariant() -cne $binding.provider.sha256 -or
        (Get-FileHash -LiteralPath $scriptdom -Algorithm SHA256).Hash.ToLowerInvariant() -cne $binding.scriptdom.sha256) { throw 'SCRIPT_PARSER_POST_DLL_PIN' }
    foreach ($path in $outputPins.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $outputPins[$path]) { throw 'SCRIPT_PARSER_OUTPUT_DRIFT' }
    }
    foreach ($path in $toolPins.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ine $toolPins[$path]) { throw 'SCRIPT_PARSER_TOOL_DRIFT' }
    }
    foreach ($path in $pins.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $pins[$path]) { throw 'SCRIPT_PARSER_INPUT_DRIFT' }
    }
    $postInputs = [ordered]@{}
    foreach ($path in $pins.Keys) { $postInputs[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
    $postTools = [ordered]@{}
    foreach ($path in $toolPins.Keys) { $postTools[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
    $postOutputs = [ordered]@{}
    foreach ($path in $outputPins.Keys) { $postOutputs[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
    $fixtureFull = [IO.Path]::GetFullPath($fixture)
    $summary = [ordered]@{status='PASS';provider_cases=$actual;source_guard_cases=60;stage_count=$stages.Count;package_sha256=$binding.package_sha256;
        provider_sha256=$binding.provider.sha256;scriptdom_sha256=$binding.scriptdom.sha256;sql_or_lab='NOT_EXECUTED';
        input_pins_before=$pins;input_pins_after=$postInputs;tool_pins_before=$toolPins;tool_pins_after=$postTools;
        output_pins_before=$outputPins;output_pins_after=$postOutputs;fixture_sha256=$pins[$fixtureFull]}
    [IO.File]::WriteAllText((Join-Path $output 'result.private.json'),($summary|ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
    $summary | ConvertTo-Json -Compress
} catch {
    $failure = [ordered]@{status='FAILED';completed_provider_cases=$actual;failure=$_.Exception.Message}
    if (Test-Path -LiteralPath $output -PathType Container) {
        [IO.File]::WriteAllText((Join-Path $output 'failure.private.json'),($failure|ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
    }
    throw
}
