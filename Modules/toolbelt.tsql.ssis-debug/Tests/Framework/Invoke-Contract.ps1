[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScriptDomDllPath,
    [Parameter(Mandatory)][string]$ProviderAssemblyPath,
    [ValidateSet('Focused','Full','ComponentsV2','ComponentsV2Import','ComponentsV2Branch','ComponentsV2Utf8Collation')][string]$Profile = 'Full',
    [string]$EvidencePath,
    [string]$ResourceProbePath,
    [ValidateSet('V1','V2')][string]$ResourceProbeProfile = 'V1',
    [ValidateSet('Bytes','Utf16Nvarchar')][string]$ResourceProbeFormat = 'Bytes',
    [string]$FixtureExportRoot,
    [ValidateRange(1,4096)][int]$PlanBenchmarkGroups = 0,
    [switch]$ReportScaleMetrics
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workspaceRoot = (Resolve-Path (Join-Path $moduleRoot '../..')).Path
. (Join-Path $workspaceRoot 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$expectedDom = '459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
if ((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $expectedDom) { throw 'SSIS_SCRIPT_DOM_PIN_MISMATCH' }
$providerHash = (Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisFramework-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$tempRoot = (Resolve-Path -LiteralPath $tempRoot).Path
Copy-Item -LiteralPath $ScriptDomDllPath -Destination $tempRoot
Copy-Item -LiteralPath $ProviderAssemblyPath -Destination $tempRoot
$executable = Join-Path $tempRoot 'Toolbelt.Tsql.SsisDebug.Tests.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$compilerArguments = @('/nologo','/optimize+','/target:exe',"/out:$executable",'/reference:System.Data.dll','/reference:System.Core.dll','/reference:System.Xml.dll','/reference:System.Xml.Linq.dll',"/reference:$ScriptDomDllPath","/reference:$ProviderAssemblyPath",(Join-Path $PSScriptRoot 'ContractTests.cs'))
$compilerResult = Invoke-OwnedProcess -FileName $compiler -Arguments $compilerArguments -TimeoutMilliseconds 120000
if ($compilerResult.ExitCode -ne 0) { throw ('SSIS_HARNESS_BUILD_FAILED: ' + $compilerResult.Stderr + $compilerResult.Stdout) }
$cases = 0
function Invoke-Case([string[]]$Arguments,[string]$ExpectedPattern = '\ASSIS_FRAMEWORK_PASS [0-9]+\s*\z',[switch]$ReturnOutput,[ValidateRange(1000,120000)][int]$TimeoutMilliseconds = 40000) {
    $caseName = if ($Arguments.Count -gt 0 -and $Arguments[0] -match '\A[a-z0-9-]+\z') { $Arguments[0] } else { 'unknown' }
    $caseOrdinal = $script:cases + 1
    if ($Profile -eq 'Full' -and -not $ResourceProbePath) { [Console]::Out.WriteLine(('SSIS_FRAMEWORK_CASE_START ordinal={0} name={1}' -f $caseOrdinal,$caseName)) }
    $psi = [Diagnostics.ProcessStartInfo]::new($executable)
    $psi.Arguments = ($Arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.WindowStyle = 'Hidden'
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $child = [Diagnostics.Process]::Start($psi)
    $stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
    try {
        if (-not $child.WaitForExit($TimeoutMilliseconds)) { $child.Kill(); throw ('SSIS_FRAMEWORK_CHILD_TIMEOUT ordinal={0} name={1}' -f $caseOrdinal,$caseName) }
        $output = $stdout.GetAwaiter().GetResult(); $errorOutput = $stderr.GetAwaiter().GetResult()
        if ($child.ExitCode -ne 0 -or $output.Length -gt 4096 -or $errorOutput.Length -gt 16384 -or $output -notmatch $ExpectedPattern -or $errorOutput.Length -ne 0) {
            throw ('SSIS_FRAMEWORK_CHILD_FAILED ordinal={0} name={1}' -f $caseOrdinal,$caseName)
        }
        $script:cases++
        if ($ReturnOutput) { return $output.Trim() }
    } finally { $child.Dispose() }
}
function Remove-FrameworkTemp {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $resolved = (Resolve-Path -LiteralPath $tempRoot).Path
    $item = Get-Item -LiteralPath $resolved -Force
    if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -or $item.Name -notmatch '\AToolbeltSsisFramework-[0-9a-f]{32}\z' -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'SSIS_FRAMEWORK_TEMP_SCOPE' }
    if (Get-ChildItem -LiteralPath $resolved -Force -Recurse | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }) { throw 'SSIS_FRAMEWORK_TEMP_REPARSE' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
if ($ResourceProbePath) {
    $probeFile = Get-Item -LiteralPath $ResourceProbePath -Force -ErrorAction Stop
    $resolvedProbe = (Resolve-Path -LiteralPath $ResourceProbePath).Path
    if ($probeFile.PSIsContainer -or ($probeFile.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or [IO.Path]::GetExtension($resolvedProbe) -ine '.dtsx' -or $probeFile.Length -gt 16777216) { throw 'SSIS_RESOURCE_PROBE_INPUT_SCOPE' }
    $probeCursor = Split-Path -Parent $resolvedProbe
    while ($probeCursor) { $probeDirectory = Get-Item -LiteralPath $probeCursor -Force; if (($probeDirectory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'SSIS_RESOURCE_PROBE_INPUT_SCOPE' }; $parent = Split-Path -Parent $probeCursor; if ($parent -eq $probeCursor) { break }; $probeCursor = $parent }
    $probeEncoding = 'bytes'; if ($ResourceProbeFormat -eq 'Utf16Nvarchar') { $probeEncoding = 'utf16-nvarchar' }
    $probeOperation=if($ResourceProbeProfile -eq 'V2'){'v2-resource-probe'}else{'v1-resource-probe'}
    $probePattern=if($ResourceProbeProfile -eq 'V2'){'\ASSIS_V2_RESOURCE_PROBE first=[a-z_]+ counter=[A-Za-z0-9_]+\s*\z'}else{'\ASSIS_V1_RESOURCE_PROBE first=[a-z_]+ counter=[A-Za-z0-9_]+\s*\z'}
    try { $result = Invoke-Case -Arguments @($probeOperation,$probeEncoding,$resolvedProbe) -ExpectedPattern $probePattern -ReturnOutput; if ((Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash -cne $providerHash) { throw 'SSIS_PROVIDER_CHANGED_DURING_TEST' }; $result; return }
    finally { Remove-FrameworkTemp }
}
if ($Profile -eq 'ComponentsV2Branch') {
    try {
        Invoke-Case @('components-v2-branch')
        if ((Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash -cne $providerHash) { throw 'SSIS_PROVIDER_CHANGED_DURING_TEST' }
        "SSIS_FRAMEWORK_PASS $cases bounded children"
        return
    } finally { Remove-FrameworkTemp }
}
if ($Profile -eq 'ComponentsV2Import') {
    try {
        foreach ($format in @(6,8)) { Invoke-Case @('import', (Join-Path $moduleRoot "Tests/Fixtures/synthetic-$format.dtsx")) }
        if ((Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash -cne $providerHash) { throw 'SSIS_PROVIDER_CHANGED_DURING_TEST' }
        "SSIS_FRAMEWORK_PASS $cases bounded children"
        return
    } finally { Remove-FrameworkTemp }
}
if ($Profile -eq 'ComponentsV2Utf8Collation') {
    try {
        Invoke-Case @('components-v2-utf8-collation', (Join-Path $moduleRoot 'Tests/Fixtures/components-v2-variable-string.dtsx'))
        if ((Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash -cne $providerHash) { throw 'SSIS_PROVIDER_CHANGED_DURING_TEST' }
        "SSIS_FRAMEWORK_PASS $cases bounded children"
        return
    } finally { Remove-FrameworkTemp }
}
$v2Case = @('components-v2', (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
if ($PlanBenchmarkGroups -gt 0) { $v2Case += ('planbench:' + $PlanBenchmarkGroups.ToString([Globalization.CultureInfo]::InvariantCulture)) }
if ($FixtureExportRoot) {
    $runtimeRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot '.runtime')).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $exportFull = [IO.Path]::GetFullPath($FixtureExportRoot)
    if (-not $exportFull.StartsWith($runtimeRoot,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($exportFull) -notmatch '\Assis-v2-native-fixtures-[a-z0-9-]{1,48}\z') { throw 'SSIS_V2_FIXTURE_EXPORT_SCOPE' }
    $cursor = [IO.Path]::GetDirectoryName($exportFull)
    while ($cursor -and $cursor.StartsWith($runtimeRoot.TrimEnd([IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)) {
        if (Test-Path -LiteralPath $cursor) { $item = Get-Item -LiteralPath $cursor -Force; if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'SSIS_V2_FIXTURE_EXPORT_SCOPE' } }
        $parent = [IO.Path]::GetDirectoryName($cursor); if ($parent -eq $cursor) { break }; $cursor = $parent
    }
    $v2Case += $exportFull
}
if ($Profile -eq 'ComponentsV2') {
    try {
        if ($PlanBenchmarkGroups -gt 0) {
            $benchPattern = '\ASSIS_V2_PLAN_BENCH terms=[0-9]+ expressionUtf16Bytes=[0-9]+ units=[0-9]+ sqlUtf16Bytes=[0-9]+ maxUnitUtf16Bytes=[0-9]+ ms=[0-9]+\s*\z'
            $benchResult = Invoke-Case $v2Case -ExpectedPattern $benchPattern -ReturnOutput -TimeoutMilliseconds 120000
            $benchResult
        } else { Invoke-Case $v2Case -TimeoutMilliseconds 120000 }
        if ((Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash -cne $providerHash) { throw 'SSIS_PROVIDER_CHANGED_DURING_TEST' }
        "SSIS_FRAMEWORK_PASS $cases bounded children"
        return
    } finally { Remove-FrameworkTemp }
}
Invoke-Case @('json')
if ($Profile -eq 'Full') { Invoke-Case $v2Case -TimeoutMilliseconds 120000 }
else { Invoke-Case $v2Case }
$scaleArgs = @('components-v2-combined-scale', (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
if ($ReportScaleMetrics) { $scaleArgs += 'private-metrics'; $scalePattern = '\ASSIS_FRAMEWORK_SCALE_PASS components=3072 columns=57344 inputBytes=134217728 expressionUtf16Bytes=3145728 ms=[0-9]+ peakWorkingSetBytes=[0-9]+\s*\z' }
else { $scalePattern = '\ASSIS_FRAMEWORK_SCALE_PASS components=3072 columns=57344 inputBytes=134217728 expressionUtf16Bytes=3145728\s*\z' }
$scaleResult = Invoke-Case $scaleArgs -ExpectedPattern $scalePattern -ReturnOutput
if ($ReportScaleMetrics) { $scaleResult }
foreach ($format in @(6,8)) {
    $fixture = Join-Path $moduleRoot "Tests/Fixtures/synthetic-$format.dtsx"
    Invoke-Case @('import', $fixture)
    Invoke-Case @('translate', $fixture)
}
if ($Profile -eq 'Full') {
    # Weitere adversariale und Ressourcenfälle werden mit demselben begrenzten
    # Prozessadapter ausgeführt; kein SQL-Server-Aufruf in dieser Qualifikation.
    Invoke-Case @('safety', (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
    Invoke-Case @('sql-regression', (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
    Invoke-Case @('v1-boundaries', (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
    Invoke-Case @('v1-graph-boundaries', (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
    Invoke-Case @('components-v2-utf8-collation', (Join-Path $moduleRoot 'Tests/Fixtures/components-v2-variable-string.dtsx'))
    Invoke-Case @('release-output-bounds')
    Invoke-Case @('cooperative-budget')
    foreach ($operators in @(32,128,256,257,258)) { Invoke-Case @('parser-boundary', [string]$operators) }
    foreach ($shape in @('union','nested','unary','boolean','projection','comments','literal')) { Invoke-Case @('parser-shape', $shape) }
}
if ((Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash -cne $providerHash) { throw 'SSIS_PROVIDER_CHANGED_DURING_TEST' }
if ($EvidencePath) {
    [ordered]@{ schemaVersion=1; result='PASS'; scope='offline-framework'; profile=$Profile; cases=$cases; providerSha512=$providerHash; scriptDomSha512=$expectedDom; stackBytes=262144; sqlExecuted=$false } | ConvertTo-Json | Set-Content -LiteralPath $EvidencePath -Encoding utf8
}
"SSIS_FRAMEWORK_PASS $cases bounded children"
