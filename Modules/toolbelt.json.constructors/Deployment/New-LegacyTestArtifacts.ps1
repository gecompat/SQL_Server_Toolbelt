[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$revision='435340a25b10ef5dccd60bf892727bd7e4e45be6'
$modulePath='Modules/toolbelt.json.constructors/'
$repoRoot=(& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
if($LASTEXITCODE -ne 0){throw 'LEGACY_REPOSITORY_UNAVAILABLE'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){
 if(-not(Test-Path -LiteralPath $output -PathType Container) -or @(Get-ChildItem -LiteralPath $output -Force).Count){throw 'LEGACY_OUTPUT_MUST_BE_NEW_OR_EMPTY'}
}
function Read-GitBytes([string[]]$Arguments){
 # Binäre Blobübertragung statt PowerShell-Textkonvertierung; keine historischen Patches.
 $start=[Diagnostics.ProcessStartInfo]::new('git')
 $start.UseShellExecute=$false;$start.CreateNoWindow=$true
 $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 foreach($argument in @('-C',$repoRoot)+$Arguments){$start.ArgumentList.Add($argument)}
 $process=[Diagnostics.Process]::new();$process.StartInfo=$start
 $buffer=[IO.MemoryStream]::new()
 try{
  if(-not $process.Start()){throw 'LEGACY_GIT_START_FAILED'}
  $copy=$process.StandardOutput.BaseStream.CopyToAsync($buffer)
  $errorRead=$process.StandardError.ReadToEndAsync()
  if(-not $process.WaitForExit(10000)){$process.Kill($true);$process.WaitForExit();throw 'LEGACY_GIT_TIMEOUT'}
  $null=$copy.GetAwaiter().GetResult();$null=$errorRead.GetAwaiter().GetResult()
  if($process.ExitCode -ne 0){throw 'GENUINE_LEGACY_COMMIT_UNAVAILABLE'}
  return ,$buffer.ToArray()
 }finally{$buffer.Dispose();$process.Dispose()}
}
$resolved=[Text.Encoding]::UTF8.GetString((Read-GitBytes @('rev-parse','--verify',($revision+'^{commit}')))).Trim()
if($resolved -cne $revision){throw 'LEGACY_COMMIT_IDENTITY_MISMATCH'}
$tree=[Text.Encoding]::UTF8.GetString((Read-GitBytes @('ls-tree','-r','-z',$revision,($modulePath+'Deployment'),($modulePath+'Source'))))
$expected=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/USP_JsonConstructInternal.sql','Source/USP_JsonArray.sql','Source/USP_JsonObject.sql')
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
[ordered]@{moduleId='toolbelt.json.constructors';moduleVersion='1.0.0';publicCommit=$revision;files=$hashes}|
 ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $output 'legacy-provenance.json') -Encoding utf8
Write-Output 'PASS: genuine JSON constructors 1.0 original SQLCMD fixture packaged'
