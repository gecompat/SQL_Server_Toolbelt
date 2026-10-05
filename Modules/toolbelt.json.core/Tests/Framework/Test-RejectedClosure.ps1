[CmdletBinding()]
param([Parameter(Mandatory)][string]$CompilerPath,[Parameter(Mandatory)][string]$ReferenceDirectory,
 [Parameter(Mandatory)][string]$FrameworkPowerShell,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$helper=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $helper
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $output)){throw 'IL_NEGATIVE_OUTPUT'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE -ne 0){throw 'IL_NEGATIVE_OUTPUT_NOT_IGNORED'}
$fixture=Join-Path $PSScriptRoot 'RejectedClosureFixture.cs'
$gate=Join-Path $PSScriptRoot 'Test-JsonClosureIL.ps1'
$refs=@('mscorlib.dll','System.dll','System.Data.dll')|ForEach-Object{Join-Path $ReferenceDirectory $_}
$inputs=@($CompilerPath,$FrameworkPowerShell,$fixture,$gate,$helper,$PSCommandPath)+@($refs)
$pins=@($inputs|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
[void][IO.Directory]::CreateDirectory($output)
$record=[ordered]@{scope='REJECTED_IL_FIXTURES_ONLY';status='FAILED';postPins=$false;phases=@()}
$modes=[ordered]@{FILE='System.IO.File|';THREAD='System.Threading.Thread|';NETWORK='System.Net.WebClient|';CONTEXT='Microsoft.SqlServer.Server.SqlContext|';REFLECTION='System.Reflection.Assembly|';GENERIC='TYPE System.Collections.Generic.List`1<System.Guid>';MUTABLE='IL_MUTABLE_STATIC';PINVOKE='IL_PINVOKE'}
try{
 foreach($mode in $modes.Keys){
  $directory=Join-Path $output $mode;[void][IO.Directory]::CreateDirectory($directory)
  $binary=Join-Path $directory 'Toolbelt.JsonCore.dll'
  $arguments=@('/nologo','/noconfig','/nostdlib+','/warnaserror+','/checked+','/optimize+','/deterministic+','/debug-','/langversion:7.3','/target:library',('/out:'+$binary),('/define:'+$mode))+@($refs|ForEach-Object{'/reference:'+$_})+@($fixture)
  $compile=Invoke-OwnedProcess -FileName $CompilerPath -Arguments $arguments -TimeoutMilliseconds 15000
  [IO.File]::WriteAllText((Join-Path $directory 'Compile.stdout.private'),$compile.Stdout)
  [IO.File]::WriteAllText((Join-Path $directory 'Compile.stderr.private'),$compile.Stderr)
  if($compile.ExitCode -ne 0-or-not$compile.CaptureComplete-or$compile.Stdout.Length-ne0-or$compile.Stderr.Length-ne0){throw 'IL_NEGATIVE_COMPILE'}
  $hash=(Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash
  $evidence=Join-Path $directory 'IL.private.json'
  $process=Invoke-OwnedProcess -FileName $FrameworkPowerShell -Arguments @('-NoProfile','-NonInteractive','-File',$gate,'-BinaryPath',$binary,'-ExpectedSha256',$hash,'-EvidencePath',$evidence) -TimeoutMilliseconds 15000
  if($process.ExitCode-ne1-or-not$process.CaptureComplete-or$process.Stderr.Length-ne0-or$process.Stdout-cne"FAIL JSON_SHARED_PRODUCT_IL`r`n"){throw 'IL_NEGATIVE_ACCEPTED_OR_CAPTURE_FAILED'}
  $result=Get-Content -LiteralPath $evidence -Raw|ConvertFrom-Json
  if($result.status-cne'FAILED'){throw 'IL_NEGATIVE_RESULT'}
  if($mode-in@('MUTABLE','PINVOKE')){
   if($result.failure-cne$modes[$mode]){throw 'IL_NEGATIVE_WRONG_GATE'}
  }else{
   if(@($result.unknown|Where-Object{$_.StartsWith($modes[$mode],[StringComparison]::Ordinal)}).Count-eq0){throw 'IL_NEGATIVE_MISSING_BINDING_WITNESS'}
  }
  if((Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash-cne$hash){throw 'IL_NEGATIVE_BINARY_DRIFT'}
  $record.phases+=@([ordered]@{name=$mode;compilerExit=0;gateExit=1;captureComplete=$true;expectedRejection=$true})
  Write-Output ($mode+': rejected')
 }
 $record.status='COMPLETE'
}finally{
 try{foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash-cne$pin.sha256){throw 'IL_NEGATIVE_POSTPIN'}};$record.postPins=$true}catch{$record.status='FAILED'}
 [IO.File]::WriteAllText((Join-Path $output 'Receipt.private.json'),($record|ConvertTo-Json -Depth 6))
}
if($record.status-cne'COMPLETE'-or-not$record.postPins){throw 'IL_NEGATIVE_FAILED'}
'PASS REJECTED_JSON_IL_FIXTURES CASES 8'
