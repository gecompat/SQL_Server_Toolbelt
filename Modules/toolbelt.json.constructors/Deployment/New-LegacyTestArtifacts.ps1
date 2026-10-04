[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory,[ValidateSet('1.0.0','1.1.0')][string]$Version='1.0.0')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$revision=if($Version -ceq '1.0.0'){'435340a25b10ef5dccd60bf892727bd7e4e45be6'}else{'f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e'}
$helperPath=Join-Path (Split-Path -Parent $PSScriptRoot) 'Scripts/Invoke-OwnedProcess.ps1'
$sourcePins=@($PSCommandPath,$helperPath)|ForEach-Object{[pscustomobject]@{Path=$_;Hash=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}}
. $helperPath
$git=Get-Command git -CommandType Application -ErrorAction Stop|Select-Object -First 1
$gitHash=(Get-FileHash -LiteralPath $git.Source -Algorithm SHA256).Hash
$modulePath='Modules/toolbelt.json.constructors/'
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){
 if(-not(Test-Path -LiteralPath $output -PathType Container) -or @(Get-ChildItem -LiteralPath $output -Force).Count){throw 'LEGACY_OUTPUT_MUST_BE_NEW_OR_EMPTY'}
}
function Read-GitBytes([string[]]$Arguments){
 # Echter Git-Blob, getrennte Livekanäle und endliche Kill-/Drainfristen.
 $scratch=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltJsonGit-'+[Guid]::NewGuid().ToString('N'))
 if(Test-Path -LiteralPath $scratch){throw 'LEGACY_SCRATCH_EXISTS'}
 [void][IO.Directory]::CreateDirectory($scratch)
 $capture=Join-Path $scratch 'stdout.bin'
 $first=$null;$cleanupFailed=$false;$snapshot=$null
 try{
  $result=Invoke-OwnedProcess -FileName $git.Source -Arguments (@('-C',$PSScriptRoot)+$Arguments) -TimeoutMilliseconds 10000 -BinaryOutputPath $capture
  if($result.ExitCode -ne 0 -or -not $result.CaptureComplete -or $result.Stderr.Length -ne 0){throw 'GENUINE_LEGACY_COMMIT_UNAVAILABLE'}
  $snapshot=[IO.File]::ReadAllBytes($capture)
 }catch{$first=$_}finally{
  try{
  if(Test-Path -LiteralPath $capture){[IO.File]::Delete($capture)}
  if(@(Get-ChildItem -LiteralPath $scratch -Force).Count -ne 0){throw 'LEGACY_SCRATCH_FOREIGN'}
  [IO.Directory]::Delete($scratch,$false)
  }catch{$cleanupFailed=$true}
 }
 if($null -ne $first){throw $first}
 if($cleanupFailed){throw 'LEGACY_SCRATCH_CLEANUP_FAILED'}
 return ,$snapshot
}
$repoRoot=[Text.Encoding]::UTF8.GetString((Read-GitBytes @('rev-parse','--show-toplevel'))).Trim()
$resolved=[Text.Encoding]::UTF8.GetString((Read-GitBytes @('rev-parse','--verify',($revision+'^{commit}')))).Trim()
if($resolved -cne $revision){throw 'LEGACY_COMMIT_IDENTITY_MISMATCH'}
$expected=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/USP_JsonConstructInternal.sql','Source/USP_JsonArray.sql','Source/USP_JsonObject.sql')
if($Version -ceq '1.1.0'){$expected+=@('Source/USP_JsonArraysByGroup.sql','Source/USP_JsonObjectsByGroup.sql')}
# Historische Toolskripte sind kein SQL-Payload. Nur die geschlossene Dateiliste
# abfragen; fehlende oder abweichende Blobs bleiben weiterhin Fehler.
$treePaths=@($expected|ForEach-Object{$modulePath+$_})
$tree=[Text.Encoding]::UTF8.GetString((Read-GitBytes (@('ls-tree','--full-tree','-r','-z',$revision)+$treePaths)))
$entries=@()
foreach($entry in $tree.Split([char]0,[StringSplitOptions]::RemoveEmptyEntries)){
 if($entry -cnotmatch '^100644 blob ([0-9a-f]{40})\t(.+)$'){throw 'LEGACY_TREE_INVALID'}
 $blob=$Matches[1];$path=$Matches[2]
 if(-not $path.StartsWith($modulePath,[StringComparison]::Ordinal)){throw 'LEGACY_TREE_SCOPE_INVALID'}
 $relative=$path.Substring($modulePath.Length)
 if($relative -cnotin $expected){throw 'LEGACY_FILE_SET_MISMATCH'}
 $entries+=,[pscustomobject]@{path=$relative;blob=$blob}
}
if($entries.Count -ne $expected.Count -or @($entries.path | Select-Object -Unique).Count -ne $expected.Count){throw 'LEGACY_FILE_SET_MISMATCH'}
[IO.Directory]::CreateDirectory($output)|Out-Null
$hashes=@()
foreach($entry in $entries){
 $bytes=Read-GitBytes @('cat-file','blob',$entry.blob)
 $destination=Join-Path $output $entry.path
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))|Out-Null
 [IO.File]::WriteAllBytes($destination,$bytes)
 $verified=[Text.Encoding]::UTF8.GetString((Read-GitBytes @('hash-object','--no-filters','--',$destination))).Trim()
 if($verified -cne $entry.blob){throw 'LEGACY_BLOB_IDENTITY_MISMATCH'}
 $hashes+=,[ordered]@{path=$entry.path;gitBlob=$entry.blob;sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash}
}
[ordered]@{moduleId='toolbelt.json.constructors';moduleVersion=$Version;publicCommit=$revision;files=$hashes}|
 ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $output 'legacy-provenance.json') -Encoding utf8
if((Get-FileHash -LiteralPath $git.Source -Algorithm SHA256).Hash -cne $gitHash){throw 'LEGACY_GIT_POSTPIN'}
foreach($pin in $sourcePins){if((Get-FileHash -LiteralPath $pin.Path -Algorithm SHA256).Hash -cne $pin.Hash){throw 'LEGACY_SOURCE_POSTPIN'}}
Write-Output ('PASS: genuine JSON constructors '+$Version+' original SQLCMD fixture packaged')
