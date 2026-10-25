[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScriptDomDllPath,
    [Parameter(Mandatory)][string]$ProviderAssemblyPath,
    [ValidateSet('Focused','Full')][string]$Profile = 'Full',
    [string]$EvidencePath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$expectedDom = '459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
if ((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $expectedDom) { throw 'SSIS_SCRIPT_DOM_PIN_MISMATCH' }
$providerHash = (Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisFramework-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
Copy-Item -LiteralPath $ScriptDomDllPath -Destination $tempRoot
Copy-Item -LiteralPath $ProviderAssemblyPath -Destination $tempRoot
$executable = Join-Path $tempRoot 'Toolbelt.Tsql.SsisDebug.Tests.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$compilerOutput = & $compiler /nologo /optimize+ /target:exe "/out:$executable" /reference:System.Data.dll /reference:System.Core.dll /reference:System.Xml.Linq.dll "/reference:$ScriptDomDllPath" "/reference:$ProviderAssemblyPath" (Join-Path $PSScriptRoot 'ContractTests.cs') 2>&1
if ($LASTEXITCODE -ne 0) { throw ('SSIS_HARNESS_BUILD_FAILED: ' + ($compilerOutput -join "`n")) }
$cases = 0
function Invoke-Case([string[]]$Arguments) {
    $psi = [Diagnostics.ProcessStartInfo]::new($executable)
    $psi.Arguments = ($Arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.WindowStyle = 'Hidden'
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $child = [Diagnostics.Process]::Start($psi)
    $stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
    try {
        if (-not $child.WaitForExit(40000)) { $child.Kill(); throw 'SSIS_FRAMEWORK_CHILD_TIMEOUT' }
        $output = $stdout.GetAwaiter().GetResult(); $errorOutput = $stderr.GetAwaiter().GetResult()
        if ($child.ExitCode -ne 0 -or $output.Length -gt 4096 -or $errorOutput.Length -gt 16384 -or $output -notmatch '\ASSIS_FRAMEWORK_PASS [0-9]+\s*\z' -or $errorOutput.Length -ne 0) { throw ('SSIS_FRAMEWORK_CHILD_FAILED: ' + $errorOutput) }
        $script:cases++
    } finally { $child.Dispose() }
}
Invoke-Case @('json')
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
