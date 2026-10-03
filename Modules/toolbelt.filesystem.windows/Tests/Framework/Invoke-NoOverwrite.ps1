# Begrenzter Offline-Test des kanonischen Providers; keine SQL-/Trust-/Identitätsprobe.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedRunnerSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedProviderSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedHarnessSHA256,
 [string]$CompilerPath,
 [string]$EvidenceDirectory
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$record=[ordered]@{Scope='OFFLINE_HELPER_ONLY';Status='PREPARING';Failure=$null;SecondaryFailures=@();Phases=@();Inputs=@();Assertions=$null;Cases=$null;StreamingCases=$null;StreamingAssertions=$null;CleanupVerified=$false;FinalPinsPassed=$false;SqlExecuted=$false;NativeProviderQualified=$false}
$pins=[Collections.Generic.List[object]]::new();$work=$null;$harnessTemp=$null;$executable=$null;$success=$false;$ownEvidenceCreated=$false
function Set-TestFailure($State,[string]$Code){
 if($null-eq$State.Failure){$State.Failure=$Code}else{$State.SecondaryFailures+=,$Code}
}
function Get-TestSHA([byte[]]$Bytes){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes))}
function Add-TestPin([string]$Path,[string]$Expected){
 $bytes=[IO.File]::ReadAllBytes($Path);$hash=Get-TestSHA $bytes
 if($Expected -and $hash-cne$Expected){throw 'FS_TEST_INPUT_PIN'}
 $pins.Add([pscustomobject]@{Path=$Path;SHA256=$hash});return ,$bytes
}
function Assert-TestPins{
 foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.Path -Algorithm SHA256).Hash-cne$pin.SHA256){throw 'FS_TEST_POST_PIN'}}
}
function Test-NoOverwriteWitness([string]$Text){
 $match=[regex]::Match($Text,'\APASS FIXED_HELPER CASES=(\d+) STAGING_CREATE_ACTIONS=(\d+) SENTINEL_CREATE_ACTIONS=(\d+) DISTINCT_OWN_PATHS=(\d+) MAX_SIMULTANEOUS_OWN_FILES=(\d+) ASSERTIONS=(\d+) STREAMING_CASES=(\d+) STREAMING_ASSERTIONS=(\d+) CLEANUP_VERIFIED=1 OFFLINE_ONLY\r?\n\z')
 if(-not$match.Success){throw 'FS_TEST_WITNESS_SHAPE'}
 $v=@();for($i=1;$i-le8;$i++){$n=0;if(-not[int]::TryParse($match.Groups[$i].Value,[ref]$n)){throw 'FS_TEST_WITNESS_INTEGER'};$v+=,$n}
 if($v[0]-ne9-or$v[1]-ne9-or$v[2]-ne5-or$v[3]-ne10-or$v[4]-lt1-or$v[4]-gt2-or$v[5]-le0-or$v[6]-ne7-or$v[7]-le0-or$v[7]-gt4096){throw 'FS_TEST_WITNESS_VALUE'}
 [pscustomobject]@{Cases=$v[0];Assertions=$v[5];StreamingCases=$v[6];StreamingAssertions=$v[7]}
}
function Invoke-TestChild([string]$Phase,[string]$File,[string[]]$Arguments,[int]$Seconds){
 # Zwei aktive ReadAsync-Puffer begrenzen jeden Kanal bereits beim Lesen.
 $proc=$null;$outStream=[IO.MemoryStream]::new();$errStream=[IO.MemoryStream]::new()
 $state=[ordered]@{Phase=$Phase;Started=$false;Terminated=$false;TimedOut=$false;ExitCode=$null;CaptureComplete=$false;DisposePassed=$false;Failure=$null;SecondaryFailures=@()}
 $channels=@();$deadline=[Diagnostics.Stopwatch]::StartNew()
 try{
  Assert-TestPins
  $start=[Diagnostics.ProcessStartInfo]::new();$start.FileName=$File;$start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
  foreach($argument in $Arguments){[void]$start.ArgumentList.Add($argument)}
  $start.Environment['TEMP']=$harnessTemp;$start.Environment['TMP']=$harnessTemp
  $proc=[Diagnostics.Process]::new();$proc.StartInfo=$start
  if(-not$proc.Start()){throw 'FS_TEST_START'};$state.Started=$true
  foreach($pair in @(@($proc.StandardOutput.BaseStream,$outStream),@($proc.StandardError.BaseStream,$errStream))){
   $buffer=[byte[]]::new(4096);$channels+=,[pscustomobject]@{Source=$pair[0];Sink=$pair[1];Buffer=$buffer;Task=$pair[0].ReadAsync($buffer,0,$buffer.Length);Done=$false}
  }
  while($true){
   foreach($channel in $channels){if(-not$channel.Done-and$channel.Task.IsCompleted){
    $count=$channel.Task.GetAwaiter().GetResult()
    if($count-eq0){$channel.Done=$true}else{
     if($channel.Sink.Length+$count-gt262144){throw 'FS_TEST_CAPTURE_BOUND'}
     $channel.Sink.Write($channel.Buffer,0,$count)
     $channel.Task=$channel.Source.ReadAsync($channel.Buffer,0,$channel.Buffer.Length)
    }
   }}
   if($proc.HasExited-and@($channels|Where-Object {-not$_.Done}).Count-eq0){break}
   if($deadline.Elapsed.TotalSeconds-ge$Seconds){$state.TimedOut=$true;throw 'FS_TEST_TIMEOUT'}
   [Threading.Thread]::Sleep(10)
  }
  $state.Terminated=$true;$state.ExitCode=$proc.ExitCode;$state.CaptureComplete=$true
  if($state.ExitCode-ne0){throw 'FS_TEST_CHILD_EXIT'}
 }catch{
  $code='FS_TEST_CHILD_FAILED'
  # Nur selbst definierte Codes transportieren; keine fremden Fehlermeldungen.
  $known=@('FS_TEST_INPUT_PIN','FS_TEST_POST_PIN','FS_TEST_START','FS_TEST_CAPTURE_BOUND','FS_TEST_TIMEOUT','FS_TEST_CHILD_EXIT')
  if($known -ccontains $_.Exception.Message){$code=$_.Exception.Message}
  Set-TestFailure $state $code
 }finally{
  # Auch Start-/Wait-/Capturefehler dürfen keinen eigenen lebenden Child zurücklassen.
  if($proc){try{
   if($state.Started-and-not$proc.HasExited){$proc.Kill($true);if(-not$proc.WaitForExit(2000)){throw 'FS_TEST_TERMINATION'}}
   if($state.Started-and$proc.HasExited){$state.Terminated=$true;$state.ExitCode=$proc.ExitCode}
  }catch{Set-TestFailure $state 'FS_TEST_TERMINATION_FAILED'}
   try{$proc.Dispose();$state.DisposePassed=$true}catch{Set-TestFailure $state 'FS_TEST_DISPOSE_FAILED'}
  }
  foreach($channel in $channels){if(-not$channel.Done){try{if($channel.Task.Wait(1000)){
   $count=$channel.Task.GetAwaiter().GetResult();if($count-gt0-and$channel.Sink.Length+$count-le262144){$channel.Sink.Write($channel.Buffer,0,$count)}
  }}catch{}}}
  try{[IO.File]::WriteAllBytes((Join-Path $work ($Phase+'.stdout.bin')),$outStream.ToArray());[IO.File]::WriteAllBytes((Join-Path $work ($Phase+'.stderr.bin')),$errStream.ToArray())}catch{Set-TestFailure $state 'FS_TEST_CAPTURE_SAVE_FAILED'}
  try{$outStream.Dispose()}finally{$errStream.Dispose()}
  try{Assert-TestPins}catch{Set-TestFailure $state 'FS_TEST_POST_PIN_FAILED'}
  $record.Phases+=,[pscustomobject]$state
 }
 if($state.Failure-or-not$state.Started-or-not$state.Terminated-or-not$state.CaptureComplete-or-not$state.DisposePassed-or$state.TimedOut-or$state.ExitCode-ne0){throw 'FS_TEST_PHASE_FAILED'}
}
try{
 if(-not$IsWindows){throw 'FS_TEST_WINDOWS_REQUIRED'}
 $provider=Join-Path $PSScriptRoot '../../Clr/WindowsFilesystemProvider.cs';$harness=Join-Path $PSScriptRoot 'NoOverwriteHarness.cs'
 $runnerBytes=Add-TestPin $PSCommandPath $ExpectedRunnerSHA256
 $providerBytes=Add-TestPin $provider $ExpectedProviderSHA256;$harnessBytes=Add-TestPin $harness $ExpectedHarnessSHA256
 if(-not$CompilerPath){$CompilerPath=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'}
 $CompilerPath=[IO.Path]::GetFullPath($CompilerPath);[void](Add-TestPin $CompilerPath '')
 $referencePaths=@();foreach($name in @('mscorlib.dll','System.dll','System.Data.dll','System.Xml.dll')){
  $path=Join-Path ([IO.Path]::GetDirectoryName($CompilerPath)) $name;[void](Add-TestPin $path '');$referencePaths+=,$path
 }
 if(-not$EvidenceDirectory){$EvidenceDirectory=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltNoOverwriteEvidence-'+[guid]::NewGuid().ToString('N'))}
 $work=[IO.Path]::GetFullPath($EvidenceDirectory)
 if([IO.Directory]::Exists($work)-or[IO.File]::Exists($work)){throw 'FS_TEST_EVIDENCE_REUSE'}
 [void][IO.Directory]::CreateDirectory($work)
 if([IO.Directory]::GetFileSystemEntries($work).Length-ne0){throw 'FS_TEST_EVIDENCE_COLLISION'}
 $owner=[IO.FileStream]::new((Join-Path $work 'Owner.marker'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$bytes=[Text.Encoding]::ASCII.GetBytes([guid]::NewGuid().ToString('N'));$owner.Write($bytes,0,$bytes.Length);$owner.Flush($true)}finally{$owner.Dispose()}
 $ownEvidenceCreated=$true
 $snapshotProvider=Join-Path $work 'WindowsFilesystemProvider.cs';$snapshotHarness=Join-Path $work 'NoOverwriteHarness.cs'
 [IO.File]::WriteAllBytes($snapshotProvider,$providerBytes);[IO.File]::WriteAllBytes($snapshotHarness,$harnessBytes)
 [void](Add-TestPin $snapshotProvider $ExpectedProviderSHA256);[void](Add-TestPin $snapshotHarness $ExpectedHarnessSHA256)
 $harnessTemp=Join-Path $work 'harness-temp';[void][IO.Directory]::CreateDirectory($harnessTemp)
 $executable=Join-Path $work 'NoOverwriteHarness.exe'
 $argv=@('/nologo','/noconfig','/nostdlib+','/target:exe','/main:NoOverwriteHarness',('/out:'+$executable))
 foreach($path in $referencePaths){$argv+=,('/reference:'+$path)};$argv+=,$snapshotProvider;$argv+=,$snapshotHarness
 Invoke-TestChild 'Compile' $CompilerPath $argv 15
 if([IO.File]::ReadAllBytes((Join-Path $work 'Compile.stdout.bin')).Length-ne0-or[IO.File]::ReadAllBytes((Join-Path $work 'Compile.stderr.bin')).Length-ne0){throw 'FS_TEST_COMPILER_NOT_QUIET'}
 [void](Add-TestPin $executable '')
 Invoke-TestChild 'Harness' $executable @() 15
 if([IO.File]::ReadAllBytes((Join-Path $work 'Harness.stderr.bin')).Length-ne0){throw 'FS_TEST_HARNESS_STDERR'}
 $result=Test-NoOverwriteWitness ([Text.UTF8Encoding]::new($false,$true).GetString([IO.File]::ReadAllBytes((Join-Path $work 'Harness.stdout.bin'))))
 $record.Assertions=$result.Assertions;$record.Cases=$result.Cases;$record.StreamingCases=$result.StreamingCases;$record.StreamingAssertions=$result.StreamingAssertions;$success=$true
}catch{Set-TestFailure $record 'FS_NO_OVERWRITE_OFFLINE_FAILED';$success=$false}finally{
 # Der Harness löscht seine eigenen bekannten Dateien. Unbekannte Reste niemals rekursiv löschen.
 try{if($harnessTemp-and[IO.Directory]::Exists($harnessTemp)){
  if([IO.Directory]::GetFileSystemEntries($harnessTemp).Length-ne0){throw 'FS_TEST_CLEANUP_BLOCKED'}
  [IO.Directory]::Delete($harnessTemp,$false)
 };$record.CleanupVerified=$true}catch{Set-TestFailure $record 'FS_TEST_CLEANUP_BLOCKED';$success=$false}
 try{Assert-TestPins;$record.FinalPinsPassed=$true}catch{Set-TestFailure $record 'FS_TEST_FINAL_PIN_FAILED';$success=$false}
 $record.Inputs=$pins.ToArray();$record.Status=if($success){'COMPLETE'}else{'FAILED'}
 if($ownEvidenceCreated){try{[IO.File]::WriteAllText((Join-Path $work 'RunEvidence.json'),($record|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))}catch{Set-TestFailure $record 'FS_TEST_EVIDENCE_SAVE_FAILED';$success=$false}}
}
if($success){'PASS OFFLINE_NO_OVERWRITE_FRAMEWORK';exit 0}
'FAILED OFFLINE_NO_OVERWRITE_FRAMEWORK';exit 1
