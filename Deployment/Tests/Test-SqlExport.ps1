#requires -Version 7.4
<#
Original SQLCMD-export assertions run against their immutable implementation.
Current markerless client/package checks remain separate mandatory gates.
Neither suite starts SQL or deploys native objects.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$code="import sys;from pathlib import Path;sys.path.insert(0,str(Path.cwd()/'Tests/Release'));from ssis_historical_context import historical_root;print(historical_root(Path.cwd(),'2fbe8e3e86f370b22ad2ce9f9716d971072a052b'))"
Push-Location $root
try { $frozen=(& python -B -c $code | Select-Object -Last 1) } finally { Pop-Location }
if($LASTEXITCODE -ne 0){throw 'HISTORICAL_EXPORT_SOURCE_UNAVAILABLE'}
Write-Host 'HISTORICAL_SQLCMD_EXPORT_SCOPE source=2fbe8e3e; current markerless installer checked separately'
& (Join-Path $frozen 'Deployment/Tests/Test-SqlExport.ps1')
& (Join-Path $PSScriptRoot 'Test-MarkerlessPackage.ps1')
& (Join-Path $PSScriptRoot 'Test-CurrentInstall.ps1')
