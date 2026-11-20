#requires -Version 7.4
<#
.SYNOPSIS
Baut normale markerfreie SQL-Installer für alle oder ausgewählte Module.
.DESCRIPTION
Reiner Offlinebuild. Keine Verbindung, Konfiguration oder Rechteänderung.
ModuleId ergänzt transitive Abhängigkeiten. In der Ausgabe nur USE anpassen.
#>
[CmdletBinding(DefaultParameterSetName='Build')]
param(
    [Parameter(Mandatory,ParameterSetName='Build')][string]$Inputs,
    [Parameter(Mandatory,ParameterSetName='Build')][string]$OutputSqlFile,
    [Parameter(Mandatory,ParameterSetName='Plan')][switch]$PlanOnly,
    [ValidateSet('Windows','Portable')][string]$Platform = 'Windows',
    [ValidateSet('local','central')][string]$DeploymentMode = 'local',
    [ValidateSet('auto','hash','trustworthy-checked','trustworthy')][string]$TrustMethod = 'auto',
    [string[]]$ModuleId = @(),
    [string]$PythonPath = 'python',
    [Parameter(ParameterSetName='Build')][string]$WorkDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$arguments = [Collections.Generic.List[string]]::new()
foreach ($value in @('-B',(Join-Path $root 'Scripts/Install/New-SimpleCommonInstall.py'),
    '--platform',$Platform,'--mode',$DeploymentMode,'--trust-mode',$TrustMethod)) {
    $arguments.Add($value)
}
if($PlanOnly){$arguments.Add('--plan')}
else{
    $inputPath = (Resolve-Path -LiteralPath $Inputs).Path
    $outputPath = [IO.Path]::GetFullPath($OutputSqlFile)
    if (Test-Path -LiteralPath $outputPath) { throw 'TBX_BUILD_OUTPUT_EXISTS: Eine neue SQL-Ausgabedatei angeben.' }
    if (-not $WorkDirectory) { $WorkDirectory = Join-Path $root ('.runtime/install-build-' + [guid]::NewGuid().ToString('N')) }
    foreach($value in @('--inputs',$inputPath,'--work',[IO.Path]::GetFullPath($WorkDirectory),'--output',$outputPath)){$arguments.Add($value)}
}
foreach ($id in $ModuleId) { $arguments.Add('--module'); $arguments.Add($id) }
$start = [Diagnostics.ProcessStartInfo]::new($PythonPath)
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.Environment['PYTHONUTF8'] = '1'
foreach ($argument in $arguments) { $start.ArgumentList.Add($argument) }
$process = [Diagnostics.Process]::Start($start)
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
try {
    if (-not $process.WaitForExit(180000)) {
        $process.Kill($true)
        throw 'TBX_BUILD_TIMEOUT: Offlinebuild nach 180 Sekunden beendet; privaten Arbeitsordner prüfen.'
    }
    $out = $stdout.GetAwaiter().GetResult()
    $err = $stderr.GetAwaiter().GetResult()
    if ($process.ExitCode -ne 0) { throw ('TBX_BUILD_FAILED: ' + $err + $out) }
} finally { $process.Dispose() }
if($PlanOnly){return ($out|ConvertFrom-Json)}
$manifestPath = $outputPath + '.manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
$hash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
if ($hash -ine $manifest.sql_sha256) { throw 'TBX_BUILD_OUTPUT_BINDING: Ausgabe stimmt nicht mit Buildmanifest überein.' }
[pscustomobject]@{
    Status = 'BUILT'
    SqlFile = $outputPath
    Manifest = $manifestPath
    Modules = @($manifest.modules)
    Platform = $Platform
    DeploymentMode = $DeploymentMode
    TrustMethod = $TrustMethod
    SqlExecuted = $false
}
