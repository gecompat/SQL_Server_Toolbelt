[CmdletBinding()]
param([string]$CompilerPath,[ValidateRange(1,60)][int]$DeadlineSeconds=20,[string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$module=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repo=Split-Path (Split-Path $module -Parent) -Parent
$helper=Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$pins=@{};$phases=@();$failure=$null;$secondary=@();$run=$null;$owned=$false
function Hash-Bytes([byte[]]$Bytes){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes))}
function Capture([string]$Path){
 $bytes=[IO.File]::ReadAllBytes($Path);$hash=Hash-Bytes $bytes
 if((Get-FileHash -LiteralPath $Path).Hash -cne $hash){throw 'DISPLAY_SNAPSHOT_DRIFT'}
 $script:pins[$Path]=$hash;return ,$bytes
}
function Check-Pins {foreach($path in $script:pins.Keys){if((Get-FileHash -LiteralPath $path).Hash -cne $script:pins[$path]){throw 'DISPLAY_PIN_DRIFT'}}}
function Save([string]$Path,[byte[]]$Bytes){
 $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($Bytes,0,$Bytes.Length)}finally{$stream.Dispose()}
}
function Phase([string]$Name,[string]$File,[string[]]$Arguments,[string]$Witness){
 Check-Pins
 $result=Invoke-OwnedProcess -FileName $File -Arguments $Arguments -TimeoutMilliseconds ($DeadlineSeconds*1000)
 Save (Join-Path $script:run ($Name+'.stdout.txt')) ([Text.UTF8Encoding]::new($false).GetBytes($result.Stdout))
 Save (Join-Path $script:run ($Name+'.stderr.txt')) ([Text.UTF8Encoding]::new($false).GetBytes($result.Stderr))
 if($result.ExitCode-ne0 -or -not$result.CaptureComplete -or $result.Stderr.Length-ne0 -or $result.Stdout.TrimEnd("`r","`n")-cne$Witness){throw 'DISPLAY_PHASE_FAILED'}
 Check-Pins
 $script:phases+=@([ordered]@{Name=$Name;ExitCode=$result.ExitCode;CaptureComplete=$result.CaptureComplete;EndedAndDisposed=$true})
}
try{
 [void](Capture $PSCommandPath)
 $helperBytes=Capture $helper
 . ([scriptblock]::Create([Text.UTF8Encoding]::new($false,$true).GetString($helperBytes)))
 if(-not$CompilerPath){
  $vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
  [void](Capture $vswhere)
  $found=Invoke-OwnedProcess -FileName $vswhere -Arguments @('-latest','-products','*','-find','MSBuild/**/Bin/Roslyn/csc.exe') -TimeoutMilliseconds ($DeadlineSeconds*1000)
  if($found.ExitCode-ne0-or-not$found.CaptureComplete-or$found.Stderr.Length){throw 'DISPLAY_COMPILER_DISCOVERY'}
  $CompilerPath=@($found.Stdout -split '\r?\n'|Where-Object {$_})[0]
 }
 if(-not$CompilerPath-or-not(Test-Path -LiteralPath $CompilerPath -PathType Leaf)){throw 'DISPLAY_COMPILER_REQUIRED'}
 [void](Capture $CompilerPath)
 $refs=Join-Path ${env:ProgramFiles(x86)} 'Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8'
 $references=@();foreach($name in @('mscorlib.dll','System.dll','System.Data.dll')){$path=Join-Path $refs $name;[void](Capture $path);$references+=('/reference:'+$path)}
 if(-not$OutputDirectory){$OutputDirectory=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltXlsxDisplayFramework-'+[guid]::NewGuid().ToString('N'))}
 $script:run=[IO.Path]::GetFullPath($OutputDirectory)
 if(Test-Path -LiteralPath $run){throw 'DISPLAY_OUTPUT_EXISTS'}
 [void](New-Item -Path $run -ItemType Directory -ErrorAction Stop)
 $owned=$true
 $sources=@();foreach($name in @('XlsxCellType.cs','XlsxCellDisplay.cs','XlsxCellDisplayBridge.cs')){
  $bytes=Capture (Join-Path $module ('Clr/'+$name));$path=Join-Path $run $name;Save $path $bytes;[void](Capture $path);$sources+=$path
 }
 foreach($name in @('DisplayHarness.cs','DisplayTransportHarness.cs','display-numeric-goldens.tsv')){
  $bytes=Capture (Join-Path $PSScriptRoot $name);$path=Join-Path $run $name;Save $path $bytes;[void](Capture $path)
 }
 $base=@('/nologo','/optimize+','/deterministic+','/langversion:7.3','/nostdlib+','/target:exe')+$references
 $display=Join-Path $run 'Display.exe';$transport=Join-Path $run 'Transport.exe'
 Phase 'CompileDisplay' $CompilerPath ($base+@('/out:'+$display)+$sources+@(Join-Path $run 'DisplayHarness.cs')) ''
 [void](Capture $display)
 Phase 'CompileTransport' $CompilerPath ($base+@('/out:'+$transport)+$sources+@(Join-Path $run 'DisplayTransportHarness.cs')) ''
 [void](Capture $transport)
 foreach($culture in @('de-DE','en-US','tr-TR')){Phase ('Display_'+$culture) $display @((Join-Path $run 'display-numeric-goldens.tsv'),$culture) 'PASS CASES=5619'}
 Phase 'Transport' $transport @() 'PASS TRANSPORT ASSERTIONS=55'
}catch{$failure='DISPLAY_FRAMEWORK_FAILED'}
finally{
 try{Check-Pins}catch{if($null-eq$failure){$failure='DISPLAY_FINAL_PIN_FAILED'}else{$secondary+=@('DISPLAY_FINAL_PIN_FAILED')}}
 if($owned){
  $record=[ordered]@{Scope='DISPLAY_CORE_AND_CLR_TRANSPORT_FRAMEWORK_ONLY';Result=if($failure){'FAILED'}else{'COMPLETE'};Failure=$failure;SecondaryFailures=$secondary;Phases=$phases;Inputs=@(foreach($path in $pins.Keys){[ordered]@{Name=[IO.Path]::GetFileName($path);SHA256=$pins[$path]}});SqlExecuted=$false;FullProductQualified=$false}
  try{Save (Join-Path $run 'RunEvidence.json') ([Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 8)))}catch{if($null-eq$failure){$failure='DISPLAY_EVIDENCE_FAILED'}}
 }
}
if($failure){throw $failure}
'PASS DISPLAY_FRAMEWORK_ONLY'
