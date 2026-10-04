[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath,[Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedAssemblySHA256,
 [Parameter(Mandatory)][string]$CscPath,[Parameter(Mandatory)][string]$EvidenceDirectory,
 [Parameter(Mandatory)][string]$FrameworkReferenceDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../../Scripts/Invoke-OwnedProcess.ps1')
if(Test-Path -LiteralPath $EvidenceDirectory){throw 'PHONETIC_FRAMEWORK_OUTPUT_EXISTS'}
$references=@('mscorlib.dll','System.dll','System.Data.dll')|ForEach-Object{Join-Path $FrameworkReferenceDirectory $_}
$source=Join-Path $PSScriptRoot 'PhoneticHarness.cs'
$inputs=@($PSCommandPath,$source,(Join-Path $PSScriptRoot '../../Scripts/Invoke-OwnedProcess.ps1'),$AssemblyPath,$CscPath)+$references
function Get-Pins {foreach($path in $inputs){[ordered]@{path=[IO.Path]::GetFullPath($path);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}}}
$pins=@(Get-Pins);$before=ConvertTo-Json -InputObject $pins -Compress
if((Get-FileHash -LiteralPath $AssemblyPath -Algorithm SHA256).Hash -ine $ExpectedAssemblySHA256){throw 'PHONETIC_FRAMEWORK_BINARY'}
[void][IO.Directory]::CreateDirectory($EvidenceDirectory)
$utf8=[Text.UTF8Encoding]::new($false)
function Save-New([string]$name,$value){$bytes=$utf8.GetBytes((ConvertTo-Json -InputObject $value -Depth 10));$file=[IO.File]::Open((Join-Path $EvidenceDirectory $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}}
$exe=Join-Path $EvidenceDirectory 'PhoneticHarness.exe'
$arguments=@('/nologo','/noconfig','/nostdlib+','/checked+','/optimize+','/target:exe',('/out:'+$exe))+@($references|ForEach-Object{'/reference:'+$_})+@($source)
$compile=Invoke-OwnedProcess -FileName $CscPath -Arguments $arguments -TimeoutMilliseconds 60000
Save-New 'Compile.argv.json' $arguments;Save-New 'Compile.process.json' $compile
if(-not $compile.CaptureComplete -or $compile.ExitCode -ne 0 -or $compile.Stdout.Length -ne 0 -or $compile.Stderr.Length -ne 0){throw 'PHONETIC_FRAMEWORK_COMPILE'}
$harnessHash=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
$phases=@()
foreach($culture in @('en-US','de-DE','tr-TR')){
 $arguments=@($AssemblyPath,$culture)
 $run=Invoke-OwnedProcess -FileName $exe -Arguments $arguments -TimeoutMilliseconds 60000
 Save-New ($culture+'.argv.json') $arguments;Save-New ($culture+'.process.json') $run
 if(-not $run.CaptureComplete -or $run.ExitCode -ne 0 -or $run.Stderr.Length -ne 0 -or $run.Stdout -cnotmatch '^PASS PHONETIC_FRAMEWORK;ASSERTIONS=[1-9][0-9]*\r?\n$'){throw 'PHONETIC_FRAMEWORK_RUNTIME'}
 if((ConvertTo-Json -InputObject @(Get-Pins) -Compress) -cne $before -or (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -cne $harnessHash){throw 'PHONETIC_FRAMEWORK_DRIFT'}
 $phases+=@([ordered]@{culture=$culture;exitCode=$run.ExitCode;complete=$run.CaptureComplete})
}
Save-New 'Inputs.json' $pins
Save-New 'Receipt.json' ([ordered]@{scope='OFFLINE_CANDIDATE_ONLY';phases=$phases;providerBuilt=$false;sqlExecuted=$false;assemblySHA256=$ExpectedAssemblySHA256;harnessSHA256=$harnessHash;postPins=$true})
Write-Output 'PASS PHONETIC_OFFLINE_CANDIDATE_ONLY'