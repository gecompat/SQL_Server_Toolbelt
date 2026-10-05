[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath,[Parameter(Mandatory)][string]$CoreAssemblyPath,
 [Parameter(Mandatory)][string]$CompilerPath,[Parameter(Mandatory)][string]$ReferenceDirectory,
 [Parameter(Mandatory)][string]$FrameworkPowerShell,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$pins=@($AssemblyPath,$CoreAssemblyPath)|ForEach-Object{[pscustomobject]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}}
$driver=Join-Path $repoRoot 'Modules/toolbelt.json.schema/Tests/Framework/Invoke-SourceQualification.ps1'
& $driver -CompilerPath $CompilerPath -ReferenceDirectory $ReferenceDirectory -FrameworkPowerShell $FrameworkPowerShell -OutputDirectory $OutputDirectory
foreach($item in @(@{path=$AssemblyPath;file='Toolbelt.JsonConstructors.dll'},@{path=$CoreAssemblyPath;file='Toolbelt.JsonCore.dll'})){
 if((Get-FileHash -LiteralPath $item.path -Algorithm SHA256).Hash -cne (Get-FileHash -LiteralPath (Join-Path $OutputDirectory $item.file) -Algorithm SHA256).Hash){throw 'JSON_FRAMEWORK_SUPPLIED_BINARY_MISMATCH'}
}
foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'JSON_FRAMEWORK_SUPPLIED_BINARY_DRIFT'}}
'PASS JSON_FRAMEWORK_CURRENT_CLOSURE_ONLY'
