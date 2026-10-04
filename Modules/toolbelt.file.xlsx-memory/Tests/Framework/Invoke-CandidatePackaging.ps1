# Bound existing generators as owned children; archived source blobs are untouched.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
if([IO.Directory]::Exists($OutputDirectory)-or[IO.File]::Exists($OutputDirectory)){throw 'PACKAGING_OUTPUT_NOT_FRESH'}
$pins=@{}
function Pin([string]$path){$path=[IO.Path]::GetFullPath($path);$pins[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;return $path}
function Check-Pins{foreach($path in $pins.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-cne$pins[$path]){throw 'PACKAGING_INPUT_DRIFT'}}}
$helper=Pin (Join-Path $root 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$helperBytes=[IO.File]::ReadAllBytes($helper)
Check-Pins
if((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash-cne$pins[$helper]){throw 'PACKAGING_HELPER_DRIFT'}
$hash=[Security.Cryptography.SHA256]::Create();try{if([BitConverter]::ToString($hash.ComputeHash($helperBytes)).Replace('-','')-cne$pins[$helper]){throw 'PACKAGING_HELPER_CAPTURE_DRIFT'}}finally{$hash.Dispose()}
. ([scriptblock]::Create([Text.Encoding]::UTF8.GetString($helperBytes).TrimStart([char]0xFEFF)))
[void](Pin $PSCommandPath);$pwsh=Pin (Get-Command pwsh -ErrorAction Stop).Source;$git=Pin (Get-Command git -ErrorAction Stop).Source
$phases=@(
 @('zip','Modules/toolbelt.archive.zip-memory/Scripts/New-ClrReleaseArtifacts.ps1'),
 @('xlsx','Modules/toolbelt.file.xlsx-memory/Scripts/New-ClrReleaseArtifacts.ps1'),
 @('zip13','Modules/toolbelt.file.xlsx-memory/Scripts/New-Zip13LegacyFixture.ps1'),
 @('xlsx10','Modules/toolbelt.file.xlsx-memory/Scripts/New-Xlsx10LegacyFixture.ps1'),
 @('xlsx11','Modules/toolbelt.file.xlsx-memory/Scripts/New-Xlsx11LegacyFixture.ps1'))
foreach($phase in $phases){[void](Pin (Join-Path $root $phase[1]))}
# Source pre/post pins cover each current provider and its packaging helpers.
foreach($module in @('toolbelt.archive.zip-memory','toolbelt.file.xlsx-memory')){
 foreach($path in Get-ChildItem -LiteralPath (Join-Path $root ('Modules/'+$module+'/Clr')) -Recurse -File | Where-Object {$_.Extension-in@('.cs','.csproj')-and$_.FullName-notmatch'[\\/]obj[\\/]'} ){[void](Pin $path.FullName)}
}
[void](Pin (Join-Path $root 'Modules/toolbelt.file.xlsx-memory/Scripts/Invoke-XlsxBuildProcess.ps1'))
[void][IO.Directory]::CreateDirectory($OutputDirectory)
$records=@();$failure=$null;$secondary=@()
try{
 foreach($phase in $phases){
  Check-Pins
  $r=$null;$primary=$null
  try{$r=Invoke-OwnedProcess -FileName $pwsh -Arguments @('-NoProfile','-File',(Join-Path $root $phase[1]),'-OutputDirectory',(Join-Path $OutputDirectory $phase[0])) -TimeoutMilliseconds 120000 -BinaryOutputPath (Join-Path $OutputDirectory ($phase[0]+'.stdout.txt'))}
  catch{$primary=$_}
  finally{try{Check-Pins}catch{if($null-eq$primary){$primary=$_}else{$secondary+=,'PACKAGING_POSTPIN_FAILED'}}}
  if($null-ne$primary){throw $primary}
  [IO.File]::WriteAllText((Join-Path $OutputDirectory ($phase[0]+'.stderr.txt')),$r.Stderr,[Text.UTF8Encoding]::new($false))
  # Successful helper return follows observed exit/EOF and completed disposal.
  $records+=,[ordered]@{Phase=$phase[0];Ended=$true;Disposed=$true;CaptureComplete=$r.CaptureComplete;ExitCode=$r.ExitCode}
  if($r.ExitCode-ne0-or-not$r.CaptureComplete){throw 'PACKAGING_CHILD_FAILED'}
 }
}catch{$failure='PACKAGING_FAILED'}finally{
 try{Check-Pins}catch{if($null-eq$failure){$failure='PACKAGING_POSTPIN_FAILED'}else{$secondary+=,'PACKAGING_POSTPIN_FAILED'}}
 [IO.File]::WriteAllText((Join-Path $OutputDirectory 'PackagingEvidence.json'),(ConvertTo-Json -InputObject ([ordered]@{Phases=$records;Failure=$failure;Secondary=$secondary;SQLExecuted=$false;Scope='BOUNDED_PACKAGING_ONLY'}) -Depth 6),[Text.UTF8Encoding]::new($false))
}
if($null-ne$failure-or$secondary.Count-ne0-or$records.Count-ne5){throw 'PACKAGING_FAILED'}
'PASS XLSX_BOUNDED_PACKAGING'
