# Test-/Paketierungshelfer: endliche Prozesse und getrennte 4-MiB-Ausgabekanäle.
function Invoke-XlsxBuildProcess {
 [CmdletBinding()]
 param([Parameter(Mandatory)][string]$FileName,
       [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Arguments,
       [Parameter(Mandatory)][ValidateRange(1,120000)][int]$TimeoutMilliseconds,
       [string]$BinaryOutputPath,
       [Parameter(Mandatory)][string]$WorkingDirectory,
       [Parameter(Mandatory)][hashtable]$ChildEnvironment)
 $child=$null;$stream=$null;$started=$false;$cleanupUnsafe=$false;$channels=@()
 $cap=4L*1024*1024
 $watch=[Diagnostics.Stopwatch]::StartNew()
 try {
  $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$FileName
  $info.UseShellExecute=$false;$info.CreateNoWindow=$true
  $info.WorkingDirectory=[IO.Path]::GetFullPath($WorkingDirectory)
  $info.Environment.Clear()
  foreach($key in $ChildEnvironment.Keys){$info.Environment.Add([string]$key,[string]$ChildEnvironment[$key])}
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
 } catch { throw 'OWNED_PROCESS_FAILED' }
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

# Nur der Buildchild erhält diese geschlossene OS-Umgebung. Hostwerte bleiben
# unverändert; keine beliebigen MSBuild-Propertys aus dem Host weiterreichen.
function New-XlsxBuildControl([string]$ProjectPath,[string]$MSBuildPath) {
 $project=[IO.Path]::GetFullPath($ProjectPath);$tool=[IO.Path]::GetFullPath($MSBuildPath)
 if(-not[IO.File]::Exists($project)-or-not[IO.File]::Exists($tool)){throw 'RELEASE_BUILD_PATH'}
 $environment=@{}
 foreach($name in @('SystemRoot','WINDIR','COMSPEC','PATHEXT','OS','PROCESSOR_ARCHITECTURE','PROCESSOR_IDENTIFIER','NUMBER_OF_PROCESSORS','ProgramFiles','ProgramFiles(x86)','ProgramW6432','USERPROFILE','LOCALAPPDATA','APPDATA','TEMP','TMP')){
  $value=[Environment]::GetEnvironmentVariable($name,'Process')
  if(-not[string]::IsNullOrWhiteSpace($value)){$environment[$name]=$value}
 }
 foreach($required in @('SystemRoot','TEMP','TMP')){if(-not$environment.ContainsKey($required)-or-not[IO.Path]::IsPathFullyQualified($environment[$required])-or-not[IO.Directory]::Exists($environment[$required])){throw 'RELEASE_BUILD_OS_ENV'}}
  $bin=[IO.Path]::GetDirectoryName($tool);$targetBin=$bin
 if([IO.Path]::GetFileName($targetBin)-ieq'amd64'){$targetBin=[IO.Path]::GetDirectoryName($targetBin)}
 if([IO.Path]::GetFileName($targetBin)-ine'Bin'-or[IO.Path]::GetFileName([IO.Path]::GetDirectoryName($targetBin))-ine'Current'){throw 'RELEASE_BUILD_TOOL_LAYOUT'}
 $extensions=[IO.Path]::GetFullPath((Join-Path $targetBin '../..'))
 $environment['PATH']=$bin+[IO.Path]::PathSeparator+(Join-Path $environment['SystemRoot'] 'System32')
 $absent=Join-Path ([IO.Path]::GetDirectoryName($project)) ('.tbx-disabled-import-'+[guid]::NewGuid().ToString('N'))
 $properties=[Collections.Generic.List[string]]::new()
 foreach($family in @('MicrosoftCommonProps','MicrosoftCommonTargets','MicrosoftCSharpTargets')){
  foreach($position in @('Before','After')){
   $properties.Add('/p:ImportByWildcard'+$position+$family+'=false')
   $properties.Add('/p:ImportUserLocationsByWildcard'+$position+$family+'=false')
  }
 }
 foreach($name in @('ImportDirectoryBuildProps','ImportDirectoryBuildTargets','ImportProjectExtensionProps','ImportProjectExtensionTargets','ImportDirectoryPackagesProps')){$properties.Add('/p:'+ $name +'=false')}
 foreach($name in @('CustomBeforeDirectoryBuildProps','CustomAfterDirectoryBuildProps','CustomBeforeDirectoryBuildTargets','CustomAfterDirectoryBuildTargets')){$properties.Add('/p:'+$name+'=')}
 foreach($name in @('CustomBeforeMicrosoftCommonProps','CustomAfterMicrosoftCommonProps','CustomBeforeMicrosoftCommonTargets','CustomAfterMicrosoftCommonTargets','CustomBeforeMicrosoftCSharpTargets','CustomAfterMicrosoftCSharpTargets')){$properties.Add('/p:'+$name+'='+$absent)}
 # Diese vier DirectoryBuild-Hooks importieren jeden nichtleeren Pfad ohne Exists-Prüfung.
 # Globale leere Werte verhindern daher den Import; die sechs übrigen Hooks bleiben auf einem nicht vorhandenen Pfad.
 $properties.Add('/p:UseSharedCompilation=false')
 return [pscustomobject]@{Project=$project;Tool=$tool;WorkingDirectory=[IO.Path]::GetDirectoryName($project);Environment=$environment;Extensions=$extensions;Absent=$absent;Arguments=@('/noAutoResponse','/nr:false')+$properties.ToArray()}
}
function Assert-XlsxBuildImports($Control) {
 # Only this fixed global CLI vector disables tool-root wildcard imports.
 # Their mere presence is not consumption; the private /pp import graph remains
 # pinned before a build. User, ancestor and custom-import checks stay fresh.
 $expected=[Collections.Generic.List[string]]::new()
 $expected.Add('/noAutoResponse');$expected.Add('/nr:false')
 foreach($family in @('MicrosoftCommonProps','MicrosoftCommonTargets','MicrosoftCSharpTargets')){
  foreach($position in @('Before','After')){
   $expected.Add('/p:ImportByWildcard'+$position+$family+'=false')
   $expected.Add('/p:ImportUserLocationsByWildcard'+$position+$family+'=false')
  }
 }
 foreach($name in @('ImportDirectoryBuildProps','ImportDirectoryBuildTargets','ImportProjectExtensionProps','ImportProjectExtensionTargets','ImportDirectoryPackagesProps')){$expected.Add('/p:'+ $name +'=false')}
 foreach($name in @('CustomBeforeDirectoryBuildProps','CustomAfterDirectoryBuildProps','CustomBeforeDirectoryBuildTargets','CustomAfterDirectoryBuildTargets')){$expected.Add('/p:'+$name+'=')}
 foreach($name in @('CustomBeforeMicrosoftCommonProps','CustomAfterMicrosoftCommonProps','CustomBeforeMicrosoftCommonTargets','CustomAfterMicrosoftCommonTargets','CustomBeforeMicrosoftCSharpTargets','CustomAfterMicrosoftCSharpTargets')){$expected.Add('/p:'+$name+'='+$Control.Absent)}
 $expected.Add('/p:UseSharedCompilation=false')
 if(@($Control.Arguments).Count-ne$expected.Count){throw 'RELEASE_BUILD_IMPORT_ARGUMENTS'}
 foreach($argument in $expected){if(@($Control.Arguments|Where-Object{$_-is[string]-and$_-ceq$argument}).Count-ne1){throw 'RELEASE_BUILD_IMPORT_ARGUMENTS'}}
 if([IO.File]::Exists($Control.Absent)-or[IO.Directory]::Exists($Control.Absent)-or[IO.File]::Exists($Control.Project+'.user')){throw 'RELEASE_BUILD_USER_IMPORT'}
 # Auch deaktivierte Verzeichnis-/Responseimports werden vor jeder Evaluation
 # frisch gelesen und abgewiesen. Keine Reparatur oder Löschung fremder Dateien.
 $directory=[IO.DirectoryInfo]::new($Control.WorkingDirectory)
 while($null-ne$directory){
  foreach($leaf in @('Directory.Build.props','Directory.Build.targets','Directory.Build.rsp','MSBuild.rsp','Directory.Packages.props')){if([IO.File]::Exists((Join-Path $directory.FullName $leaf))){throw 'RELEASE_BUILD_ANCESTOR_IMPORT'}}
  $directory=$directory.Parent
 }
 $roots=[Collections.Generic.List[string]]::new();$roots.Add($Control.Extensions)
 if($Control.Environment.ContainsKey('LOCALAPPDATA')){$roots.Add((Join-Path $Control.Environment['LOCALAPPDATA'] 'Microsoft/MSBuild'))}
 foreach($base in $roots){
  foreach($family in @('Microsoft.Common.props','Microsoft.Common.targets','Microsoft.CSharp.targets')){
   foreach($position in @('ImportBefore','ImportAfter')){
    $path=Join-Path $base ('Current/'+$(if($family-ceq'Microsoft.Common.props'){'Imports/'}else{''})+$family+'/'+$position)
    if($base-cne$Control.Extensions-and[IO.Directory]::Exists($path)-and@(Get-ChildItem -LiteralPath $path -File -Force).Count-ne0){throw 'RELEASE_BUILD_WILDCARD_IMPORT'}
   }
  }
  foreach($family in @('Microsoft.Common.props','Microsoft.Common.targets','Microsoft.CSharp.targets')){
   foreach($position in @('Before','After')){if([IO.File]::Exists((Join-Path $base ('vCurrent/Custom.'+$position+'.'+$family)))){throw 'RELEASE_BUILD_CUSTOM_IMPORT'}}
  }
 }
}