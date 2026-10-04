[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Originaler öffentlicher 1.0-Release, keine nachträgliche Source- oder Markerkorrektur.
$revision='fdafa8038e4d5240dd727096f144c8d5fd884117'
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Legacyziel existiert; kein Überschreiben.'}
[void](New-Item -ItemType Directory -Path $destination)
$archive=Join-Path $destination 'original.zip'
# Gemeinsamer qualifizierter Helfer: endliche Toolprozesse, vorlaufende 4-MiB-Kanallimits.
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$helper=Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$toolPins=@{};$legacySourcePins=@{}
function Pin-LegacyTool([string]$path){$path=[IO.Path]::GetFullPath($path);$toolPins[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;return $path}
[void](Pin-LegacyTool $PSCommandPath);[void](Pin-LegacyTool $helper)
$helperBytes=[IO.File]::ReadAllBytes($helper);$h=[Security.Cryptography.SHA256]::Create()
try{if([BitConverter]::ToString($h.ComputeHash($helperBytes)).Replace('-','')-cne$toolPins[$helper]){throw 'LEGACY_HELPER_CAPTURE_DRIFT'}}finally{$h.Dispose()}
. ([scriptblock]::Create([Text.Encoding]::UTF8.GetString($helperBytes).TrimStart([char]0xFEFF)))
$git=Pin-LegacyTool (Get-Command git -ErrorAction Stop).Source
$pwsh=Pin-LegacyTool (Get-Command pwsh -ErrorAction Stop).Source
function Assert-LegacyPins{
 foreach($path in $toolPins.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-cne$toolPins[$path]){throw 'LEGACY_TOOL_PIN_DRIFT'}}
 foreach($path in $legacySourcePins.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-cne$legacySourcePins[$path]){throw 'LEGACY_ORIGINAL_SOURCE_DRIFT'}}
}
function Save-LegacyBytes([string]$name,[byte[]]$bytes){$f=$null;try{$f=[IO.File]::Open((Join-Path $destination $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$f.Write($bytes,0,$bytes.Length);$f.Flush($true)}finally{if($f){$f.Dispose()}}}
function Invoke-LegacyTool([string]$phase,[string]$tool,[string[]]$arguments,[int]$milliseconds,[bool]$quietError){
 $result=$null;$first=$null;$secondary=@()
 $receipt=[ordered]@{Phase=$phase;Started=$null;Ended=$null;Disposed=$null;CaptureComplete=$false;ExitCode=$null;PostPins=$false;Failure=$null;Secondary=@()}
 Assert-LegacyPins
 try{
  $result=Invoke-OwnedProcess -FileName $tool -Arguments $arguments -TimeoutMilliseconds $milliseconds
  # Der normale Helferreturn folgt erst auf beobachtetes Exit/EOF und abgeschlossene Dispose.
  $receipt.Started=$true;$receipt.Ended=$true;$receipt.Disposed=$true;$receipt.CaptureComplete=$result.CaptureComplete;$receipt.ExitCode=$result.ExitCode
  Save-LegacyBytes ($phase+'.stdout.txt') ([Text.UTF8Encoding]::new($false).GetBytes($result.Stdout))
  Save-LegacyBytes ($phase+'.stderr.txt') ([Text.UTF8Encoding]::new($false).GetBytes($result.Stderr))
  if($result.ExitCode-ne0-or-not$result.CaptureComplete-or($quietError-and$result.Stderr.Length-ne0)){throw 'LEGACY_TOOL_RESULT_REJECTED'}
 }catch{$first=$_;$receipt.Failure=if($null-eq$result){'LEGACY_HELPER_FAILED_DISPOSITION_UNKNOWN'}else{'LEGACY_TOOL_RESULT_OR_CAPTURE_REJECTED'}}finally{
  try{Assert-LegacyPins;$receipt.PostPins=$true}catch{if($null-eq$first){$first=$_;$receipt.Failure='LEGACY_POSTPIN_DRIFT'}else{$secondary+=,'LEGACY_POSTPIN_DRIFT'}}
  $receipt.Secondary=$secondary
  try{Save-LegacyBytes ($phase+'.process.json') ([Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $receipt -Depth 6)))}catch{if($null-eq$first){$first=$_}else{$secondary+=,'LEGACY_RECEIPT_SAVE_FAILED'}}
 }
 if($null-ne$first){if($secondary.Count){$first.Exception.Data['LegacySecondaryFailures']=$secondary -join ','};throw $first}
 return $result
}
function Git-Text([string]$phase,[string[]]$arguments){$r=Invoke-LegacyTool $phase $git $arguments 30000 $true;return $r.Stdout.Trim()}
[void](Git-Text 'Archive' @('archive','--format=zip',('--output='+$archive),$revision,'Modules/toolbelt.file.xlsx-memory','Modules/toolbelt.archive.zip-memory'))
$source=Join-Path $destination 'original'
Expand-Archive -LiteralPath $archive -DestinationPath $source
# Nur vor dem Build vorhandene Originaldateien pinnen; Buildoutputs werden nicht als Quellen adoptiert.
foreach($file in Get-ChildItem -LiteralPath $source -Recurse -File){$legacySourcePins[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
$legacy=Join-Path $source 'Modules/toolbelt.file.xlsx-memory'
if((Get-Content -LiteralPath (Join-Path $legacy 'module.yaml') -Raw) -notmatch '(?m)^version: "1\.0\.0"\s*$'){throw 'Gepinnter Originalrelease ist nicht XLSX1.0.'}
$files=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql',
 'Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql',
 'Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Clr/AssemblyInfo.cs','Clr/Toolbelt.File.XlsxMemory.csproj','Scripts/New-ClrReleaseArtifacts.ps1')
$pins=[ordered]@{}
foreach($relative in $files){
 $repoPath='Modules/toolbelt.file.xlsx-memory/'+$relative
 $phase=($relative.Replace('/','_').Replace('.','_'))
 $expected=Git-Text ('Blob_'+$phase) @('rev-parse',($revision+':'+$repoPath))
 $actual=Git-Text ('Hash_'+$phase) @('hash-object','--no-filters',(Join-Path $legacy $relative))
 if($actual -cne $expected){throw 'Legacydatei ist nicht der bytegleiche Originalblob.'}
 $pins[$relative]=[ordered]@{gitBlob=$expected;sha256=(Get-FileHash -LiteralPath (Join-Path $legacy $relative) -Algorithm SHA256).Hash}
}
foreach($module in @('toolbelt.archive.zip-memory','toolbelt.file.xlsx-memory')){
 $script=Join-Path $source ('Modules/'+$module+'/Scripts/New-ClrReleaseArtifacts.ps1')
 [void](Invoke-LegacyTool ('Build_'+$module.Replace('.','_').Replace('-','_')) $pwsh @('-NoProfile','-File',$script) 60000 $false)
}
Assert-LegacyPins
$manifest=Get-Content -LiteralPath (Join-Path $legacy 'Artifacts/Toolbelt.File.XlsxMemory.trust-manifest.json') -Raw|ConvertFrom-Json
$binary=Join-Path $legacy 'Artifacts/Toolbelt.File.XlsxMemory.dll'
if($manifest.moduleVersion -cne '1.0.0' -or (Get-FileHash -LiteralPath $binary -Algorithm SHA512).Hash -cne $manifest.sha512){throw 'Genuine1.0-Binarymanifest ist nicht kohärent.'}
[ordered]@{revision=$revision;sourcePins=$pins;assemblySHA512=$manifest.sha512;moduleVersion='1.0.0'}|
 ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $destination 'LegacyProvenance.json') -Encoding utf8
Assert-LegacyPins
Write-Output 'PASS: bytegleiche genuine XLSX1.0-Source und Originalbuild; SQL-Upgrade nicht ausgeführt.'
