[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$AssemblyPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedAssemblySHA256,
 [Parameter(Mandatory)][string]$CscPath,
 [Parameter(Mandatory)][string]$FrameworkReferenceDirectory,
 [Parameter(Mandatory)][string]$EvidenceDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Parent
$helper=Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$source=Join-Path $PSScriptRoot 'CsvHarness.cs'
$references=@('mscorlib.dll','System.dll','System.Data.dll')|ForEach-Object{Join-Path $FrameworkReferenceDirectory $_}
$inputs=@($PSCommandPath,$helper,$source,$AssemblyPath,$CscPath)+$references
function Get-Pins {foreach($path in $inputs){[ordered]@{Name=[IO.Path]::GetFileName($path);SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}}}
$pins=@(Get-Pins);$before=ConvertTo-Json -InputObject $pins -Compress
if((Get-FileHash -LiteralPath $AssemblyPath -Algorithm SHA256).Hash -ine $ExpectedAssemblySHA256){throw 'CSV_FRAMEWORK_BINARY_PIN'}
# Das tatsächlich geprüfte gepackte Binary bleibt unverändert; keine Source-Neukompilation im Harness.
. ([scriptblock]::Create([IO.File]::ReadAllText($helper)))
$output=[IO.Path]::GetFullPath($EvidenceDirectory)
$repoRoot=[IO.Path]::GetFullPath($repo).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
if($output.StartsWith($repoRoot,[StringComparison]::OrdinalIgnoreCase) -or $output.TrimEnd([IO.Path]::DirectorySeparatorChar) -ieq $repoRoot.TrimEnd([IO.Path]::DirectorySeparatorChar)){throw 'CSV_FRAMEWORK_PRIVATE_OUTPUT_REQUIRED'}
if(Test-Path -LiteralPath $output){throw 'CSV_FRAMEWORK_OUTPUT_EXISTS'}
[void][IO.Directory]::CreateDirectory($output)
function Save-New([string]$name,$record){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $record -Depth 8))
 $file=[IO.File]::Open((Join-Path $output $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
}
function Check-Pins {
 if((ConvertTo-Json -InputObject @(Get-Pins) -Compress) -cne $before){throw 'CSV_FRAMEWORK_INPUT_DRIFT'}
}
$copy=Join-Path $output 'Toolbelt.File.CsvMemory.dll'
# Fester Kopierpuffer statt ganzer DLLaufnahme; Länge und EOF bleiben an denselben Lesehandle gebunden.
$sourceStream=$null;$file=$null;$buffer=$null
try {
 $sourceStream=[IO.File]::Open($AssemblyPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 [long]$initialLength=$sourceStream.Length
 [long]$remaining=$initialLength
 $buffer=[byte[]]::new(65536)
 $file=[IO.File]::Open($copy,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 while($remaining -gt 0){
  $read=$sourceStream.Read($buffer,0,[int][Math]::Min([long]$buffer.Length,$remaining))
  if($read -le 0){throw 'CSV_FRAMEWORK_COPY_LENGTH'}
  $file.Write($buffer,0,$read)
  $remaining-=$read
 }
 if($sourceStream.ReadByte() -ne -1 -or $sourceStream.Length -ne $initialLength -or $file.Length -ne $initialLength){throw 'CSV_FRAMEWORK_COPY_LENGTH'}
} finally {
 try{if($null -ne $file){$file.Dispose()}}finally{if($null -ne $sourceStream){$sourceStream.Dispose()}}
 $buffer=$null
}
if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ine $ExpectedAssemblySHA256){throw 'CSV_FRAMEWORK_COPY_PIN'}
$exe=Join-Path $output 'CsvHarness.exe'
$arguments=@('/nologo','/noconfig','/nostdlib+','/checked+','/optimize+','/deterministic+','/langversion:7.3','/target:exe',('/out:'+$exe))+@($references|ForEach-Object{'/reference:'+$_})+@(('/reference:'+$copy),$source)
Check-Pins
$compile=Invoke-OwnedProcess -FileName $CscPath -Arguments $arguments -TimeoutMilliseconds 60000
Save-New 'Compile.process.json' $compile
if(-not $compile.CaptureComplete -or $compile.ExitCode -ne 0 -or $compile.Stdout.Length -ne 0 -or $compile.Stderr.Length -ne 0){throw 'CSV_FRAMEWORK_COMPILE'}
$harnessHash=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
$phases=@()
foreach($culture in @('en-US','de-DE','tr-TR')){
 $phase=$(if($culture -eq 'en-US'){'boundaries'}else{'corpus'})
 Check-Pins
 $run=Invoke-OwnedProcess -FileName $exe -Arguments @($culture,$phase) -TimeoutMilliseconds 60000
 Save-New ($culture+'.process.json') $run
 if(-not $run.CaptureComplete -or $run.ExitCode -ne 0 -or $run.Stderr.Length -ne 0 -or $run.Stdout -cnotmatch '^PASS CSV_FRAMEWORK;ASSERTIONS=[1-9][0-9]*\r?\n$'){throw 'CSV_FRAMEWORK_RUNTIME'}
 Check-Pins
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -cne $harnessHash -or (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ine $ExpectedAssemblySHA256){throw 'CSV_FRAMEWORK_EXECUTABLE_DRIFT'}
 $phases+=@([ordered]@{Culture=$culture;Scope=$phase;ExitCode=$run.ExitCode;CaptureComplete=$run.CaptureComplete})
}
Save-New 'Inputs.json' $pins
Save-New 'Receipt.json' ([ordered]@{Scope='CSV_PACKAGED_CLR_FRAMEWORK_ONLY';Phases=$phases;AssemblySHA256=$ExpectedAssemblySHA256.ToUpperInvariant();HarnessSHA256=$harnessHash;PostPins=$true;SqlExecuted=$false;FullProductQualified=$false})
'PASS CSV_PACKAGED_CLR_FRAMEWORK_ONLY'
