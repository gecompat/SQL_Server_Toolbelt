[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath,[Parameter(Mandatory)][string]$CoreAssemblyPath,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$coreScript=Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1'
& $coreScript -ModuleId 'toolbelt.json.constructors' -AssemblyPath $AssemblyPath -CoreAssemblyPath $CoreAssemblyPath -OutputDirectory $OutputDirectory
