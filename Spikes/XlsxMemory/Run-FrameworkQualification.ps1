# Portable binary qualification. Product and ZIP must already be packaged.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$XlsxDirectory,[Parameter(Mandatory)][string]$ZipDirectory,
      [Parameter(Mandatory)][string]$OutputDirectory,[string]$CompilerPath)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot '../../Modules/toolbelt.file.xlsx-memory/Tests/Framework/Invoke-CandidateQualification.ps1') @PSBoundParameters
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
