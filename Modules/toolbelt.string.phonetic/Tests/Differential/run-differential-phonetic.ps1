#Requires -Version 7.3
[CmdletBinding()]
param([Parameter(Mandatory)][string]$BindingPath,
      [Parameter(Mandatory)][string]$ExpectedBindingSHA256)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Explizite gebundene Windows-Framework-/JDK-Eingaben; keine Tooldiscovery.
$watch=[Diagnostics.Stopwatch]::StartNew()
$phase='preflight';$childCount=0;$primaryFailure=$null;$cleanupFailure=$null;$postcheckFailure=$null
$ownedEvidence=$null;$copyPins=@();$generatedPins=@();$inputPins=@()
$utf8=[Text.UTF8Encoding]::new($false,$true)
function Need([bool]$Value){if(-not $Value){throw 'PHONETIC_DIFFERENTIAL_COORDINATOR_FAILED'}}
function Hash([byte[]]$Bytes){Need ($watch.ElapsedMilliseconds -lt 240000);$sha=[Security.Cryptography.SHA256]::Create();try{$digest=$sha.ComputeHash($Bytes);Need ($watch.ElapsedMilliseconds -lt 240000);return [Convert]::ToHexString($digest)}finally{$sha.Dispose()}}
function NoReparse([string]$Path){
 $current=[IO.Path]::GetFullPath($Path)
 while($current){
  if([IO.File]::Exists($current) -or [IO.Directory]::Exists($current)){
   Need (([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) -eq 0)
  }else{Need $false}
  $next=[IO.Path]::GetDirectoryName($current);if($next -ceq $current){break};$current=$next
 }
}
function BoundedBytes([string]$Path,[int]$Limit){
 Need ($watch.ElapsedMilliseconds -lt 240000)
 NoReparse $Path
 $buffer=[byte[]]::new($Limit+1);$count=0
 $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try{while($count -lt $buffer.Length){$read=$stream.Read($buffer,$count,$buffer.Length-$count);if($read -eq 0){break};$count+=$read}}finally{$stream.Dispose()}
 Need ($count -le $Limit -and $watch.ElapsedMilliseconds -lt 240000)
 $result=[byte[]]::new($count);[Buffer]::BlockCopy($buffer,0,$result,0,$count)
 return ,$result
}
function PinnedBytes($Pin){
 Need ($Pin -is [Collections.IDictionary] -and $Pin.Count -eq 3 -and $Pin.Contains('Path') -and $Pin.Contains('SHA256') -and $Pin.Contains('Bytes'))
 Need ($Pin.Path -is [string] -and [IO.Path]::IsPathFullyQualified($Pin.Path) -and $Pin.SHA256 -is [string] -and $Pin.SHA256 -cmatch '^[0-9A-F]{64}$')
 Need (($Pin.Bytes -is [int] -or $Pin.Bytes -is [long]) -and $Pin.Bytes -gt 0 -and $Pin.Bytes -le 16777216)
 $bytes=BoundedBytes $Pin.Path ([int]$Pin.Bytes)
 Need ($bytes.Length -eq $Pin.Bytes -and (Hash $bytes) -ceq $Pin.SHA256)
 return ,$bytes
}
function SaveBytes([string]$Path,[byte[]]$Bytes){
 NoReparse ([IO.Path]::GetDirectoryName($Path))
 $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($Bytes,0,$Bytes.Length)}finally{$stream.Dispose()}
}
function SaveJson([string]$Name,$Value){SaveBytes (Join-Path $ownedEvidence $Name) ($utf8.GetBytes((ConvertTo-Json -InputObject $Value -Depth 20)))}
function CopyInput([string]$Name,[byte[]]$Bytes){
 $path=Join-Path $ownedEvidence $Name
 $parent=[IO.Path]::GetDirectoryName($path)
 if(-not [IO.Directory]::Exists($parent)){[void][IO.Directory]::CreateDirectory($parent)}
 SaveBytes $path $Bytes
 $script:copyPins+=@(@{Path=$path;SHA256=(Hash $Bytes);Bytes=$Bytes.Length})
 return $path
}
function AssertPins{
 foreach($pin in $inputPins+$copyPins+$generatedPins){Need ($watch.ElapsedMilliseconds -lt 240000);[void](PinnedBytes $pin)}
}
function ClassFiles([string]$Root){
 $pending=[Collections.Generic.Queue[string]]::new();$pending.Enqueue($Root)
 $files=[Collections.Generic.List[string]]::new();$directories=0
 while($pending.Count -gt 0){
  Need ($watch.ElapsedMilliseconds -lt 240000)
  $directory=$pending.Dequeue();NoReparse $directory;$directories++;Need ($directories -le 32)
  $entries=[IO.Directory]::GetFileSystemEntries($directory);Need ($entries.Length -le 128)
  foreach($path in $entries){
   $attributes=[IO.File]::GetAttributes($path);Need (($attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0)
   if(($attributes -band [IO.FileAttributes]::Directory) -ne 0){$pending.Enqueue($path)}
   else{Need ($path.EndsWith('.class',[StringComparison]::Ordinal));$files.Add($path);Need ($files.Count -le 128)}
  }
 }
 $result=$files.ToArray();[Array]::Sort($result,[StringComparer]::Ordinal)
 return ,$result
}
function Natural([string]$Text,[int]$Maximum){
 $value=0
 Need ([int]::TryParse($Text,[Globalization.NumberStyles]::None,[Globalization.CultureInfo]::InvariantCulture,[ref]$value) -and $value -ge 0 -and $value -le $Maximum -and $Text -ceq $value.ToString([Globalization.CultureInfo]::InvariantCulture))
 return $value
}
function AsciiText([byte[]]$Bytes){foreach($b in $Bytes){Need ($b -eq 9 -or $b -eq 10 -or ($b -ge 32 -and $b -le 126))};return [Text.Encoding]::ASCII.GetString($Bytes)}
function Canonical64([string]$Text,[int]$Limit){
 $bytes=[Convert]::FromBase64String($Text)
 Need ($bytes.Length -le $Limit -and [Convert]::ToBase64String($bytes) -ceq $Text)
 return ,$bytes
}
function Corpus([byte[]]$Bytes){
 Need ($Bytes.Length -gt 0 -and $Bytes.Length -le 32768)
 $lines=(AsciiText $Bytes).Split([char[]]@([char]10),[StringSplitOptions]::None)
 Need ($lines.Length -ge 3 -and $lines.Length -le 66 -and $lines[0] -ceq 'PHONETIC_CORPUS_V1' -and $lines[-1] -ceq '')
 $items=@();$aj=$false
 for($i=1;$i -lt $lines.Length-1;$i++){
  $fields=$lines[$i].Split([char[]]@([char]9),[StringSplitOptions]::None)
  Need ($fields.Length -eq 3 -and $fields[0] -ceq $i.ToString([Globalization.CultureInfo]::InvariantCulture) -and $fields[1] -cin @('C','D'))
  $raw=Canonical64 $fields[2] 256;Need ($raw.Length -ge 2 -and $raw.Length%2 -eq 0)
  $chars=[char[]]::new($raw.Length/2);$core=$false
  for($j=0;$j -lt $chars.Length;$j++){
   $ch=[char]([int]$raw[2*$j]+256*[int]$raw[2*$j+1]);$extra=if($fields[1] -ceq 'C'){'ÄÖÜäöüß'}else{'ÇçÑñ'}
   Need ([int]$ch -le 127 -or $extra.IndexOf($ch) -ge 0);$chars[$j]=$ch;$core=$core -or [int]$ch -gt 32
  }
  Need ($fields[1] -ceq 'C' -or $core);$text=[string]::new($chars)
  $aj=$aj -or ($fields[1] -ceq 'D' -and $text -ceq 'AJ')
  $items+=@([pscustomobject]@{Id=$i;Algorithm=$fields[1];Text=$text})
 }
 Need ($items.Count -ge 1 -and $items.Count -le 64 -and $aj)
 return ,$items
}
function Wire([byte[]]$Bytes,[string]$Status,$Cases){
 $lines=(AsciiText $Bytes).Split([char[]]@([char]10),[StringSplitOptions]::None)
 Need ($lines.Length -eq $Cases.Count+2 -and $lines[0] -ceq 'PHONETIC_DIFFERENTIAL_V1' -and $lines[-1] -ceq '')
 $rows=@()
 for($i=0;$i -lt $Cases.Count;$i++){
  Need ($watch.ElapsedMilliseconds -lt 240000)
  $fields=$lines[$i+1].Split([char[]]@([char]9),[StringSplitOptions]::None)
  Need ($fields.Length -eq 7 -and $fields[0] -ceq $Cases[$i].Id.ToString([Globalization.CultureInfo]::InvariantCulture) -and $fields[1] -ceq $Cases[$i].Algorithm -and $fields[2] -ceq $Status)
  $length=Natural $fields[3] 16384;$primary=Canonical64 $fields[4] 16384
  Need ($primary.Length -eq $length);foreach($b in $primary){Need ($b -le 127)}
  if($fields[1] -ceq 'C'){
   Need ($fields[5] -ceq '-1' -and $fields[6] -ceq '-');$alternate=$null
  }else{
   $alternateLength=Natural $fields[5] 16384;$alternate=Canonical64 $fields[6] 16384
   Need ($alternate.Length -eq $alternateLength -and $primary.Length+$alternate.Length -le 32768)
   foreach($b in $alternate){Need ($b -le 127)}
   if($Cases[$i].Text -ceq 'AJ'){Need ([Convert]::ToHexString($alternate) -ceq '4120')}
  }
  $rows+=@([pscustomobject]@{Primary=$primary;Alternate=$alternate})
 }
 return ,$rows
}
function Child([string]$Stage,[string]$Program,[string[]]$Arguments,[string]$RawOutput){
 $script:phase=$Stage;AssertPins
 $remaining=240000-[int]$watch.ElapsedMilliseconds
 Need ($remaining -gt 0 -and $childCount -lt 4)
 $script:childCount++
 try{
  if($RawOutput){$result=Invoke-OwnedProcess -FileName $Program -Arguments $Arguments -TimeoutMilliseconds ([Math]::Min(60000,$remaining)) -BinaryOutputPath $RawOutput}
  else{$result=Invoke-OwnedProcess -FileName $Program -Arguments $Arguments -TimeoutMilliseconds ([Math]::Min(60000,$remaining))}
 }catch{
  if($_.Exception.Message -ceq 'OWNED_PROCESS_CLEANUP_UNSAFE'){
   $script:cleanupFailure='OWNED_PROCESS_CLEANUP_UNSAFE';$script:primaryFailure='UNAVAILABLE_FROM_SHARED_HELPER'
  }elseif($_.Exception.Message -ceq 'OWNED_PROCESS_FAILED'){
   $script:primaryFailure='OWNED_PROCESS_FAILED'
  }else{
   $script:primaryFailure='UNCLASSIFIED'
  }
  throw
 }finally{
  try{AssertPins}catch{$script:postcheckFailure='PHONETIC_DIFFERENTIAL_PIN_POSTCHECK_FAILED';throw}
 }
 SaveJson ($Stage+'.process.private.json') @{ExitCode=$result.ExitCode;CaptureComplete=$result.CaptureComplete;ReturnedDecodedStderr=$result.Stderr;ReturnedDecodedStdout=$result.Stdout}
 Need ($result.CaptureComplete -ceq $true -and $result.ExitCode -eq 0 -and $result.Stderr.Length -eq 0 -and $result.Stdout.Length -eq 0)
}
try{
 Need $IsWindows
 Need ($ExpectedBindingSHA256 -cmatch '^[0-9A-F]{64}$')
 $bindingBytes=BoundedBytes $BindingPath 262144;Need ((Hash $bindingBytes) -ceq $ExpectedBindingSHA256)
 $inputPins+=@(@{Path=[IO.Path]::GetFullPath($BindingPath);SHA256=$ExpectedBindingSHA256;Bytes=$bindingBytes.Length})
 $binding=ConvertFrom-Json -InputObject ($utf8.GetString($bindingBytes)) -AsHashtable
 $roles=@('Coordinator','CSharpConsumer','JavaConsumer','Corpus','Transport','OwnedProcess','ApacheManifest','Assembly','Csc','Java','Javac','Mscorlib','System','SystemData')
 Need ($binding -is [Collections.IDictionary] -and $binding.Count -eq 5 -and $binding.Contains('Schema') -and $binding.Contains('Ready') -and $binding.Contains('Inputs') -and $binding.Contains('EvidenceDirectory') -and $binding.Contains('ReferenceDirectory') -and $binding.Schema -ceq 'PHONETIC_DIFFERENTIAL_BINDING_V1' -and $binding.Ready -is [bool] -and $binding.Ready -ceq $true)
 Need ($binding.Inputs -is [Collections.IDictionary] -and $binding.Inputs.Count -eq $roles.Count)
 $snapshots=@{}
 foreach($role in $roles){Need ($binding.Inputs.Contains($role));$pin=$binding.Inputs[$role];$snapshots[$role]=PinnedBytes $pin;$inputPins+=@($pin)}
 Need ([IO.Path]::GetFullPath($binding.Inputs.Coordinator.Path) -ceq [IO.Path]::GetFullPath($PSCommandPath))
 Need ($binding.Inputs.Assembly.Bytes -le 4194304)
 Need ($binding.Inputs.OwnedProcess.SHA256 -ceq 'FF2CCE9C0C33335892EFFAC843D90BF2B131B597C68E9514850CC91C80CAC993' -and $binding.Inputs.OwnedProcess.Bytes -eq 5227)
 Need ($binding.Inputs.ApacheManifest.SHA256 -ceq 'D3839828C20B7831DF95B4362C700E67A12338BA7E3D869B35246BA9C97EEBA8')
 $reference=ConvertFrom-Json -InputObject ($utf8.GetString($snapshots.ApacheManifest)) -AsHashtable
 Need ($reference -is [Collections.IDictionary] -and $reference.Count -eq 4 -and $reference.Contains('Commit') -and $reference.Contains('GitTree') -and $reference.Contains('DeclaredRelease') -and $reference.Contains('Files'))
 Need ($reference.Commit -ceq '5f76abb946164b943bc2cf367bc1d70b8f6e70d1' -and $reference.GitTree -ceq 'bec710ef2e34636a6331644d9ab2ee84b48e2b60' -and $reference.DeclaredRelease -ceq '1.18.0' -and $reference.Files.Count -eq 11)
 Need ($binding.ReferenceDirectory -is [string] -and [IO.Path]::IsPathFullyQualified($binding.ReferenceDirectory))
 $referenceRoot=[IO.Path]::GetFullPath($binding.ReferenceDirectory);Need ([IO.Directory]::Exists($referenceRoot));NoReparse $referenceRoot
 $referencePrefix=[IO.Path]::TrimEndingDirectorySeparator($referenceRoot)+[IO.Path]::DirectorySeparatorChar
 $expectedSources=@('src/main/java/org/apache/commons/codec/language/ColognePhonetic.java','src/main/java/org/apache/commons/codec/language/DoubleMetaphone.java','src/main/java/org/apache/commons/codec/EncoderException.java','src/main/java/org/apache/commons/codec/StringEncoder.java','src/main/java/org/apache/commons/codec/Encoder.java','src/main/java/org/apache/commons/codec/binary/StringUtils.java','src/main/java/org/apache/commons/codec/CharEncoding.java','src/main/java/org/apache/commons/codec/binary/CharSequenceUtils.java','LICENSE.txt','NOTICE.txt','pom.xml')
 $apacheSnapshots=@{}
 foreach($entry in $reference.Files){
  Need ($entry -is [Collections.IDictionary] -and $entry.Count -eq 4 -and $entry.Contains('SourcePath') -and $entry.Contains('GitBlob') -and $entry.Contains('SHA256') -and $entry.Contains('Bytes'))
  Need ($entry.SourcePath -is [string] -and $entry.SourcePath -cin $expectedSources -and -not $apacheSnapshots.ContainsKey($entry.SourcePath) -and $entry.GitBlob -is [string] -and $entry.GitBlob -cmatch '^[0-9a-f]{40}$')
  $sourcePath=[IO.Path]::GetFullPath((Join-Path $referenceRoot $entry.SourcePath))
  Need ($sourcePath.StartsWith($referencePrefix,[StringComparison]::OrdinalIgnoreCase))
  $pin=@{Path=$sourcePath;SHA256=$entry.SHA256;Bytes=$entry.Bytes};$apacheSnapshots[$entry.SourcePath]=PinnedBytes $pin;$inputPins+=@($pin)
 }
 Need ($apacheSnapshots.Count -eq 11)
 # Keine impliziten Javaoptionen oder fremde Classpath-Ergaenzungen konsumieren.
 foreach($name in @('JAVA_TOOL_OPTIONS','JDK_JAVA_OPTIONS','JDK_JAVAC_OPTIONS','_JAVA_OPTIONS','CLASSPATH')){Need ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name)))}
 $cases=Corpus $snapshots.Corpus
 Need ($binding.EvidenceDirectory -is [string] -and [IO.Path]::IsPathFullyQualified($binding.EvidenceDirectory))
 $evidence=[IO.Path]::GetFullPath($binding.EvidenceDirectory)
 Need (-not [IO.File]::Exists($evidence) -and -not [IO.Directory]::Exists($evidence))
 NoReparse ([IO.Path]::GetDirectoryName($evidence))
 [void][IO.Directory]::CreateDirectory($evidence);$ownedEvidence=$evidence
 SaveBytes (Join-Path $ownedEvidence 'OWNED_SCOPE.private') ($utf8.GetBytes('PHONETIC_DIFFERENTIAL_OWNED_SCOPE_V1'))
 $helper=CopyInput 'Inputs/Invoke-OwnedProcess.ps1' $snapshots.OwnedProcess
 $csharp=CopyInput 'Inputs/PhoneticDifferentialConsumer.cs' $snapshots.CSharpConsumer
 $java=CopyInput 'Inputs/PhoneticReferenceConsumer.java' $snapshots.JavaConsumer
 $corpus=CopyInput 'Inputs/DifferentialCorpus.tsv' $snapshots.Corpus
 $assembly=CopyInput 'Inputs/Toolbelt.String.Phonetic.dll' $snapshots.Assembly
 $references=@(foreach($role in @('Mscorlib','System','SystemData')){CopyInput ('Inputs/'+$role+'.dll') $snapshots[$role]})
 $javaSources=@()
 foreach($path in $expectedSources){$copy=CopyInput ('Apache/'+$path) $apacheSnapshots[$path];if($path.EndsWith('.java',[StringComparison]::Ordinal)){$javaSources+=@($copy)}}
 AssertPins
 . $helper
 $exe=Join-Path $ownedEvidence 'PhoneticDifferentialConsumer.exe'
 $classes=Join-Path $ownedEvidence 'Classes';[void][IO.Directory]::CreateDirectory($classes)
 $cscArgs=@('/nologo','/noconfig','/nostdlib+','/checked+','/optimize+','/debug-','/codepage:65001','/target:exe',('/out:'+$exe))+@($references|ForEach-Object{'/reference:'+$_})+@($csharp)
 Child 'compile-csharp' $binding.Inputs.Csc.Path $cscArgs ''
 Child 'compile-java' $binding.Inputs.Javac.Path (@('-encoding','UTF-8','-proc:none','-implicit:none','-classpath',$classes,'-sourcepath',(Join-Path $ownedEvidence 'Apache/src/main/java'),'-d',$classes)+$javaSources+@($java)) ''
 # Nur der frische eigene Compileoutput wird begrenzt inventarisiert und danach strikt erhalten.
 $beforeClassFiles=ClassFiles $classes
 $outputs=@($exe)+$beforeClassFiles
 Need ($outputs.Count -ge 10 -and $outputs.Count -le 128)
 $total=0L
 foreach($path in $outputs){$bytes=BoundedBytes $path 4194304;Need ($bytes.Length -gt 0);$total+=$bytes.Length;Need ($total -le 16777216);$generatedPins+=@(@{Path=$path;SHA256=(Hash $bytes);Bytes=$bytes.Length})}
 Need ([IO.File]::Exists((Join-Path $classes 'PhoneticReferenceConsumer.class')))
 $leftPath=Join-Path $ownedEvidence 'CSharp.stdout.raw.private'
 $rightPath=Join-Path $ownedEvidence 'Java.stdout.raw.private'
 Child 'consume-csharp' $exe @($assembly,$binding.Inputs.Assembly.SHA256,$binding.Inputs.Assembly.Bytes.ToString([Globalization.CultureInfo]::InvariantCulture),$corpus,$binding.Inputs.Corpus.SHA256) $leftPath
 Child 'consume-java' $binding.Inputs.Java.Path @('-cp',$classes,'PhoneticReferenceConsumer',$corpus,$binding.Inputs.Corpus.SHA256) $rightPath
 $left=Wire (BoundedBytes $leftPath 4194304) '0' $cases
 $right=Wire (BoundedBytes $rightPath 4194304) '-' $cases
 for($i=0;$i -lt $cases.Count;$i++){
  Need ($watch.ElapsedMilliseconds -lt 240000)
  Need ([Convert]::ToHexString($left[$i].Primary) -ceq [Convert]::ToHexString($right[$i].Primary))
  if($cases[$i].Algorithm -ceq 'D'){Need ([Convert]::ToHexString($left[$i].Alternate) -ceq [Convert]::ToHexString($right[$i].Alternate))}
 }
 AssertPins
 $afterClassFiles=ClassFiles $classes
 Need ($afterClassFiles.Length -eq $beforeClassFiles.Length)
 for($i=0;$i -lt $beforeClassFiles.Length;$i++){Need ($beforeClassFiles[$i] -ceq $afterClassFiles[$i])}
 Need ($childCount -eq 4 -and $watch.ElapsedMilliseconds -le 240000)
 SaveJson 'Receipt.private.json' @{Status='PASS_BOUNDED_DIFFERENTIAL_CORPUS';Cases=$cases.Count;Children=$childCount;InputPins=$inputPins;ConsumedCopyPins=$copyPins;GeneratedPins=$generatedPins;ReturnedDecodedStderrEmpty=$true;RawStderrAttested=$false;FilesRetained=$true;SQLExecuted=$false;PrimaryFailure=$null;CleanupFailure=$null;PostcheckFailure=$null}
 Write-Output 'PHONETIC_DIFFERENTIAL_SCOPE_PASS'
}catch{
 if($null -eq $primaryFailure){$primaryFailure='PHONETIC_DIFFERENTIAL_COORDINATOR_FAILED'}
 if($ownedEvidence){try{SaveJson 'Failure.private.json' @{Status='FAILED_OR_UNREADY';Phase=$phase;Children=$childCount;PrimaryFailure=$primaryFailure;CleanupFailure=$cleanupFailure;PostcheckFailure=$postcheckFailure;FilesRetained=$true}}catch{}}
 Write-Output 'PHONETIC_DIFFERENTIAL_SCOPE_FAILED_OR_UNREADY'
 exit 1
}finally{
 # Prozesse werden allein im unveraenderten Helper beendet; private Dateien bleiben erhalten.
 $watch.Stop();$snapshots=$null;$apacheSnapshots=$null;$bindingBytes=$null
}
