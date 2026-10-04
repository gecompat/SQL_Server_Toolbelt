[CmdletBinding()]
param([string]$OutputDirectory='.runtime/xlsx-zip13-legacy')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Tatsächlicher voriger ZIP-Release; kein nachträglich ummarkierter neuer Build.
$revision='677e68c269b084379143c058cad0f03baee1bf79'
$destination=if([IO.Path]::IsPathRooted($OutputDirectory)){[IO.Path]::GetFullPath($OutputDirectory)}else{[IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))}
if(Test-Path -LiteralPath $destination){throw 'Legacy-Fixture-Ziel existiert; kein automatisches Überschreiben.'}
[void](New-Item -ItemType Directory -Path $destination)
$source=Join-Path $destination 'source';[void](New-Item -ItemType Directory -Path $source)
$archive=Join-Path $destination 'source.zip'
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
[void](Git-Text 'Archive' @('archive','--format=zip',('--output='+$archive),$revision,'Modules/toolbelt.archive.zip-memory'))
Expand-Archive -LiteralPath $archive -DestinationPath $source
foreach($file in Get-ChildItem -LiteralPath $source -Recurse -File){$legacySourcePins[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
[void](Invoke-LegacyTool 'Build' $pwsh @('-NoProfile','-File',(Join-Path $source 'Modules/toolbelt.archive.zip-memory/Scripts/New-ClrReleaseArtifacts.ps1'),'-OutputDirectory',(Join-Path $destination 'artifacts')) 60000 $false)
Assert-LegacyPins
$manifest=Get-Content -LiteralPath (Join-Path $destination 'artifacts/Toolbelt.Archive.ZipMemory.trust-manifest.json') -Raw|ConvertFrom-Json
if($manifest.moduleVersion-cne'1.3.0'){throw 'Keine echte ZIP-1.3-Fixture.'}
Assert-LegacyPins
'PASS: pinned real ZIP 1.3.0 fixture built; not an SQL upgrade claim.'
