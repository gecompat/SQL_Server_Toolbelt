# Test-/Paketierungshelfer: endliche Prozesse und getrennte 4-MiB-Ausgabekanäle.
function Invoke-OwnedProcess {
 [CmdletBinding()]
 param([Parameter(Mandatory)][string]$FileName,
       [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Arguments,
       [Parameter(Mandatory)][ValidateRange(1,900000)][int]$TimeoutMilliseconds,
       [string]$BinaryOutputPath)
 $child=$null;$stream=$null;$started=$false;$cleanupUnsafe=$false;$channels=@()
 $cap=4L*1024*1024
 $watch=[Diagnostics.Stopwatch]::StartNew()
 try {
  $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$FileName
  $info.UseShellExecute=$false;$info.CreateNoWindow=$true
  $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
  foreach($argument in $Arguments){$info.ArgumentList.Add($argument)}
  if($BinaryOutputPath){$stream=[IO.File]::Open($BinaryOutputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)}
  $child=[Diagnostics.Process]::new();$child.StartInfo=$info
  if(-not $child.Start()){throw 'OWNED_PROCESS_START'};$started=$true
  # Zwei gleichzeitig aktive Reads verhindern einen vollen unbeachteten Pipekanal.
  $channels=@(
   [pscustomobject]@{Binary=($null -ne $stream);Reader=$child.StandardOutput;Buffer=$null;Text=[Text.StringBuilder]::new();Encoder=[Text.UTF8Encoding]::new($false).GetEncoder();Encoded=[byte[]]::new(24582);Bytes=0L;Task=$null;Done=$false},
   [pscustomobject]@{Binary=$false;Reader=$child.StandardError;Buffer=$null;Text=[Text.StringBuilder]::new();Encoder=[Text.UTF8Encoding]::new($false).GetEncoder();Encoded=[byte[]]::new(24582);Bytes=0L;Task=$null;Done=$false})
  foreach($channel in $channels){
   if($channel.Binary){$channel.Buffer=[byte[]]::new(8192);$channel.Task=$channel.Reader.BaseStream.ReadAsync($channel.Buffer,0,8192)}
   else{$channel.Buffer=[char[]]::new(8192);$channel.Task=$channel.Reader.ReadAsync($channel.Buffer,0,8192)}
  }
  while($true){
   if($watch.ElapsedMilliseconds -ge $TimeoutMilliseconds){throw 'OWNED_PROCESS_TIMEOUT'}
   foreach($channel in $channels){
    if($channel.Done -or -not $channel.Task.IsCompleted){continue}
    if($channel.Task.IsFaulted -or $channel.Task.IsCanceled){throw 'OWNED_PROCESS_CAPTURE_FAILED'}
    # Result ist erst nach dem beobachteten endlichen Taskabschluss zugänglich.
    $count=$channel.Task.Result;$channel.Task=$null
    if($count -eq 0){
     if(-not $channel.Binary){
      $usedChars=0;$flush=0;$complete=$false
      $channel.Encoder.Convert([char[]]::new(0),0,0,$channel.Encoded,0,$channel.Encoded.Length,$true,[ref]$usedChars,[ref]$flush,[ref]$complete)
      if(-not $complete -or $usedChars -ne 0){throw 'OWNED_PROCESS_ENCODING_FAILED'}
      if($channel.Bytes+$flush -gt $cap){throw 'OWNED_PROCESS_CAPTURE_LIMIT'}
      $channel.Bytes+=$flush
     }
     $channel.Done=$true;continue
    }
    if($channel.Binary){
     if($channel.Bytes+$count -gt $cap){throw 'OWNED_PROCESS_CAPTURE_LIMIT'}
     $stream.Write($channel.Buffer,0,$count);$channel.Bytes+=$count
     $channel.Task=$channel.Reader.BaseStream.ReadAsync($channel.Buffer,0,8192)
    }else{
     # Der zustandsbehaftete Encoder zählt UTF-8 auch über Surrogat-Chunkgrenzen.
     $usedChars=0;$bytes=0;$complete=$false
     $channel.Encoder.Convert($channel.Buffer,0,$count,$channel.Encoded,0,$channel.Encoded.Length,$false,[ref]$usedChars,[ref]$bytes,[ref]$complete)
     if(-not $complete -or $usedChars -ne $count){throw 'OWNED_PROCESS_ENCODING_FAILED'}
     if($channel.Bytes+$bytes -gt $cap){throw 'OWNED_PROCESS_CAPTURE_LIMIT'}
     [void]$channel.Text.Append($channel.Buffer,0,$count);$channel.Bytes+=$bytes
     $channel.Task=$channel.Reader.ReadAsync($channel.Buffer,0,8192)
    }
   }
   if($channels[0].Done -and $channels[1].Done -and $child.HasExited){break}
   $remaining=$TimeoutMilliseconds-[int]$watch.ElapsedMilliseconds
   if($remaining -le 0){throw 'OWNED_PROCESS_TIMEOUT'}
   $pending=@($channels | Where-Object {-not $_.Done -and $null -ne $_.Task} | ForEach-Object {$_.Task})
   if($pending.Count -gt 0){[void][Threading.Tasks.Task]::WaitAny([Threading.Tasks.Task[]]$pending,[Math]::Min(10,$remaining))}
   elseif(-not $child.HasExited){[void]$child.WaitForExit([Math]::Min(10,$remaining))}
  }
  $child.Refresh()
  [pscustomobject]@{ExitCode=$child.ExitCode;Stdout=$channels[0].Text.ToString();Stderr=$channels[1].Text.ToString();CaptureComplete=$true}
 } catch {
  # Nur feste Fehlerkategorien verlassen den privaten Prozesskontext.
  # Insbesondere Exceptiontexte mit Hostpfaden oder Childausgaben bleiben aus CI.
  $category=$_.Exception.Message
  if($category -cnotin @('OWNED_PROCESS_START','OWNED_PROCESS_TIMEOUT',
    'OWNED_PROCESS_CAPTURE_FAILED','OWNED_PROCESS_ENCODING_FAILED',
    'OWNED_PROCESS_CAPTURE_LIMIT')){$category='OWNED_PROCESS_FAILED'}
  throw $category
 }
 finally {
  $cleanupWatch=[Diagnostics.Stopwatch]::StartNew()
  try {
   if($started -and -not $child.HasExited){
    try{$child.Kill($true)}catch{$cleanupUnsafe=$true}
    try{if(-not $child.WaitForExit(3000)){$cleanupUnsafe=$true}}catch{$cleanupUnsafe=$true}
   }
   foreach($channel in $channels){
    if($null -ne $channel.Task -and -not $channel.Task.IsCompleted){
     $remaining=3000-[int]$cleanupWatch.ElapsedMilliseconds
     try{if($remaining -le 0 -or -not $channel.Task.Wait($remaining)){$cleanupUnsafe=$true}}catch{$cleanupUnsafe=$true}
    }
   }
  } finally {
   try{if($stream){$stream.Dispose()}}catch{$cleanupUnsafe=$true}
   try{if($child){$child.Dispose()}}catch{$cleanupUnsafe=$true}
   $cleanupWatch.Stop();$watch.Stop()
  }
  if($cleanupUnsafe){throw 'OWNED_PROCESS_CLEANUP_UNSAFE'}
 }
}
