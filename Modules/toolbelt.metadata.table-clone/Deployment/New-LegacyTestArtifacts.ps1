[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Echter öffentlicher V1-Stand, keine Rückversionierung der W1-Source.
$commit='fdafa8038e4d5240dd727096f144c8d5fd884117'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$prefix='Modules/toolbelt.metadata.table-clone/'
$files=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/USP_ScriptTableCloneInternal.sql','Source/USP_ScriptTableClone.sql','module.yaml')
if(Test-Path -LiteralPath $OutputDirectory){throw 'Legacy-Ziel muss neu und isoliert sein.'}
[void](New-Item -ItemType Directory -Path $OutputDirectory)
$rows=@()
foreach($file in $files){
 $destination=Join-Path $OutputDirectory $file
 [void](New-Item -ItemType Directory -Path (Split-Path $destination) -Force)
 $start=[Diagnostics.ProcessStartInfo]::new('git')
 $start.WorkingDirectory=$root;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
 $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 $start.ArgumentList.Add('cat-file');$start.ArgumentList.Add('blob');$start.ArgumentList.Add($commit+':'+$prefix+$file)
 $process=$null;$stream=$null;$copyTask=$null;$errorTask=$null
 try{
  $process=[Diagnostics.Process]::Start($start)
  $stream=[IO.File]::Create($destination)
  $copyTask=$process.StandardOutput.BaseStream.CopyToAsync($stream)
  $errorTask=$process.StandardError.ReadToEndAsync()
  if(-not $process.WaitForExit(15000)){throw 'LEGACY_PROCESS_TIMEOUT'}
  if(-not $copyTask.Wait(5000) -or -not $errorTask.Wait(5000)){throw 'LEGACY_CHANNEL_TIMEOUT'}
  [void]$copyTask.GetAwaiter().GetResult();[void]$errorTask.GetAwaiter().GetResult()
  if($process.ExitCode-ne0){throw 'LEGACY_BLOB_UNAVAILABLE'}
 }catch{throw 'Öffentlicher Legacyblob konnte nicht begrenzt gelesen werden; kein Fallback.'}
 finally{
  try{
   if($null-ne$process){
    try{if(-not$process.HasExited){$process.Kill($true);if(-not$process.WaitForExit(5000)){throw 'LEGACY_PROCESS_TERMINATION'}}}
    finally{
     try{if($null-ne$copyTask){if(-not$copyTask.Wait(5000)){throw 'LEGACY_COPY_CLEANUP'}};if($null-ne$errorTask){if(-not$errorTask.Wait(5000)){throw 'LEGACY_ERROR_CLEANUP'}}}
     catch{throw 'Legacy-Kanäle konnten nicht begrenzt abgeschlossen werden.'}
    }
   }
  }catch{throw 'Legacy-Prozesscleanup nicht vollständig.'}
  finally{try{if($null-ne$stream){$stream.Dispose()}}finally{if($null-ne$process){$process.Dispose()}}}
 }
 $rows+=@{path=$file;sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash}
}
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'provenance.json'),(@{moduleId='toolbelt.metadata.table-clone';version='1.0.0';publicCommit=$commit;files=$rows}|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output 'PASS: Genuine V1-Artefakte isoliert; keine SQL-Ausführung.'
