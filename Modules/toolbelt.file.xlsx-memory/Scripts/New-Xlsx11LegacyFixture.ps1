[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Originaler öffentlicher 1.1-Release, keine nachträgliche Source- oder Markerkorrektur.
$revision='f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e'
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Legacyziel existiert; kein Überschreiben.'}
[void](New-Item -ItemType Directory -Path $destination)
$archive=Join-Path $destination 'original.zip'
$repo=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
. (Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$git=(Get-Command git -ErrorAction Stop).Source
$gitHash=(Get-FileHash -LiteralPath $git -Algorithm SHA256).Hash
$helper=Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$helperHash=(Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash
function Git-Text([string[]]$Arguments){
 $result=Invoke-OwnedProcess -FileName $git -Arguments (@('-C',$repo)+$Arguments) -TimeoutMilliseconds 30000
 if($result.ExitCode -ne 0 -or -not $result.CaptureComplete -or $result.Stderr.Length){throw 'XLSX11_GIT_FAILED'}
 if((Get-FileHash -LiteralPath $git -Algorithm SHA256).Hash -cne $gitHash){throw 'XLSX11_GIT_PIN_DRIFT'}
 return $result.Stdout.TrimEnd("`r","`n")
}
[void](Git-Text @('archive','--format=zip',('--output='+$archive),$revision,'Modules/toolbelt.file.xlsx-memory','Modules/toolbelt.archive.zip-memory'))
$source=Join-Path $destination 'original'
Expand-Archive -LiteralPath $archive -DestinationPath $source
$legacy=Join-Path $source 'Modules/toolbelt.file.xlsx-memory'
if((Get-Content -LiteralPath (Join-Path $legacy 'module.yaml') -Raw) -notmatch '(?m)^version: "1\.1\.0"\s*$'){throw 'Gepinnter Originalrelease ist nicht XLSX1.1.'}
$files=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql',
 'Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql',
 'Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Clr/XlsxCellType.cs','Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql','Clr/AssemblyInfo.cs','Clr/Toolbelt.File.XlsxMemory.csproj','Scripts/New-ClrReleaseArtifacts.ps1')
$pins=[ordered]@{}
foreach($relative in $files){
 $repoPath='Modules/toolbelt.file.xlsx-memory/'+$relative
 $expected=Git-Text @('rev-parse',($revision+':'+$repoPath))
 $actual=Git-Text @('hash-object','--no-filters',(Join-Path $legacy $relative))
 if($actual -cne $expected){throw 'Legacydatei ist nicht der bytegleiche Originalblob.'}
 $pins[$relative]=[ordered]@{gitBlob=$expected;sha256=(Get-FileHash -LiteralPath (Join-Path $legacy $relative) -Algorithm SHA256).Hash}
}
foreach($module in @('toolbelt.archive.zip-memory','toolbelt.file.xlsx-memory')){
 $script=Join-Path $source ('Modules/'+$module+'/Scripts/New-ClrReleaseArtifacts.ps1')
 $scriptHash=(Get-FileHash -LiteralPath $script -Algorithm SHA256).Hash
 $pwsh=(Get-Command pwsh -ErrorAction Stop).Source
 $pwshHash=(Get-FileHash -LiteralPath $pwsh -Algorithm SHA256).Hash
 $result=Invoke-OwnedProcess -FileName $pwsh -Arguments @('-NoProfile','-File',$script) -TimeoutMilliseconds 60000
 if($result.ExitCode -ne 0 -or -not $result.CaptureComplete){throw 'XLSX11_ORIGINAL_BUILD_FAILED'}
 if((Get-FileHash -LiteralPath $script -Algorithm SHA256).Hash -cne $scriptHash -or (Get-FileHash -LiteralPath $pwsh -Algorithm SHA256).Hash -cne $pwshHash){throw 'XLSX11_BUILD_INPUT_DRIFT'}

}
if((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -cne $helperHash){throw 'XLSX11_HELPER_DRIFT'}
foreach($relative in $files){if((Get-FileHash -LiteralPath (Join-Path $legacy $relative) -Algorithm SHA256).Hash -cne $pins[$relative].sha256){throw 'XLSX11_ORIGINAL_SOURCE_DRIFT'}}
$manifest=Get-Content -LiteralPath (Join-Path $legacy 'Artifacts/Toolbelt.File.XlsxMemory.trust-manifest.json') -Raw|ConvertFrom-Json
$binary=Join-Path $legacy 'Artifacts/Toolbelt.File.XlsxMemory.dll'
if($manifest.moduleVersion -cne '1.1.0' -or (Get-FileHash -LiteralPath $binary -Algorithm SHA512).Hash -cne $manifest.sha512){throw 'Genuine1.1-Binarymanifest ist nicht kohärent.'}
[ordered]@{revision=$revision;sourcePins=$pins;assemblySHA512=$manifest.sha512;moduleVersion='1.1.0'}|
 ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $destination 'LegacyProvenance.json') -Encoding utf8
Write-Output 'PASS: bytegleiche genuine XLSX1.1-Source und Originalbuild; SQL-Upgrade nicht ausgeführt.'
