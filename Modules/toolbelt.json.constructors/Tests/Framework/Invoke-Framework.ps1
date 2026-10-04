[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath,[Parameter(Mandatory)][string]$CompilerPath,
 [Parameter(Mandatory)][string]$ReferenceDirectory,[Parameter(Mandatory)][string]$FrameworkPowerShell,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'JSON_FRAMEWORK_REQUIRES_PWSH7_HOST'}
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1')
$registry=Get-Content -LiteralPath (Join-Path $moduleRoot 'Documentation/KNOWN_CLR_ARTIFACTS.json') -Raw -Encoding UTF8|ConvertFrom-Json
if($registry.status -cne 'OFFLINE_QUALIFIED_KNOWN_ARTIFACT' -or @($registry.artifacts).Count -ne 1){throw 'JSON_FRAMEWORK_REGISTRY'}
$expected=$registry.artifacts[0].Fields.binarySha256.ToUpperInvariant()
$sources=@(Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'Clr') -Filter '*.cs' -Recurse|ForEach-Object{$_.FullName})
$sources+=@((Join-Path $PSScriptRoot 'ProductHarness.cs'),(Join-Path $PSScriptRoot 'BridgeGoldens.tsv'),
 (Join-Path $PSScriptRoot 'Test-ProductIL.ps1'),$PSCommandPath,(Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1'),
 (Join-Path $moduleRoot 'Documentation/KNOWN_CLR_ARTIFACTS.json'),$AssemblyPath,$CompilerPath,$FrameworkPowerShell)
$references=@('mscorlib.dll','System.dll','System.Data.dll')|ForEach-Object{Join-Path $ReferenceDirectory $_}
$sources+= $references
$pins=@($sources|ForEach-Object{[pscustomobject]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
foreach($property in $registry.artifacts[0].Fields.psobject.Properties){if($property.Name.StartsWith('source/',[StringComparison]::Ordinal)){
 if((Get-FileHash -LiteralPath (Join-Path $moduleRoot ('Clr/'+$property.Name.Substring(7))) -Algorithm SHA256).Hash.ToLowerInvariant() -cne $property.Value){throw 'JSON_FRAMEWORK_SOURCE'}
}}
if((Get-FileHash -LiteralPath $AssemblyPath -Algorithm SHA256).Hash -cne $expected){throw 'JSON_FRAMEWORK_BINARY'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'JSON_FRAMEWORK_OUTPUT_EXISTS'}
[void][IO.Directory]::CreateDirectory($output)
$utf8=New-Object Text.UTF8Encoding($false)
function Write-New([string]$name,[byte[]]$bytes){$s=[IO.File]::Open((Join-Path $output $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($bytes,0,$bytes.Length);$s.Flush()}finally{$s.Dispose()}}
$binary=[IO.File]::ReadAllBytes($AssemblyPath)
$binaryHasher=[Security.Cryptography.SHA256]::Create()
try{if([BitConverter]::ToString($binaryHasher.ComputeHash($binary)).Replace('-','') -cne $expected){throw 'JSON_FRAMEWORK_CAPTURED_BINARY'}}finally{$binaryHasher.Dispose()}
Write-New 'Toolbelt.JsonConstructors.dll' $binary
$dll=Join-Path $output 'Toolbelt.JsonConstructors.dll'
$exe=Join-Path $output 'ProductHarness.exe'
$record=[ordered]@{scope='OFFLINE_FRAMEWORK_ONLY';status='FAILED';failure=$null;postPins=$false;phases=@()}
function Phase([string]$name,[string]$file,[string[]]$arguments,[int]$milliseconds,[string]$witness){
 $p=Invoke-OwnedProcess -FileName $file -Arguments $arguments -TimeoutMilliseconds $milliseconds
 Write-New ($name+'.stdout') ($utf8.GetBytes($p.Stdout));Write-New ($name+'.stderr') ($utf8.GetBytes($p.Stderr))
 $record.phases+= [ordered]@{name=$name;exitCode=$p.ExitCode;captureComplete=$p.CaptureComplete;deadlineMilliseconds=$milliseconds}
 if($p.ExitCode -ne 0 -or -not $p.CaptureComplete -or $p.Stderr.Length -ne 0 -or $p.Stdout -cne $witness){throw 'JSON_FRAMEWORK_PHASE'}
}
try{
 $compilerArguments=@('/nologo','/warnaserror+','/noconfig','/nostdlib+','/checked+','/optimize+','/deterministic+','/debug-',
  '/langversion:7.3','/target:exe',('/out:'+$exe))
 foreach($reference in $references){$compilerArguments+= '/reference:'+$reference}
 $compilerArguments+=@(('/reference:'+$dll),(Join-Path $PSScriptRoot 'ProductHarness.cs'))
 Phase 'Compiler' $CompilerPath $compilerArguments 15000 ''
 $exeHash=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
 Phase 'IL' $FrameworkPowerShell @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'Test-ProductIL.ps1'),
  '-BinaryPath',$dll,'-ExpectedSha256',$expected,'-EvidencePath',(Join-Path $output 'IL.json')) 15000 "PASS PRODUCT_IL`r`n"
 foreach($culture in @('en-US','de-DE','tr-TR')){
  Phase ('Small-'+$culture) $exe @('SMALL',$culture,(Join-Path $PSScriptRoot 'BridgeGoldens.tsv')) 45000 ("PASS PRODUCT_FRAMEWORK SMALL "+$culture+" ROWS 37 ASSERTIONS 962`r`n")
  if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -cne $exeHash){throw 'JSON_FRAMEWORK_EXE_DRIFT'}
 }
 Phase 'Large' $exe @('LARGE','invariant',(Join-Path $PSScriptRoot 'BridgeGoldens.tsv')) 45000 "PASS PRODUCT_FRAMEWORK LARGE invariant ROWS 3 ASSERTIONS 67`r`n"
 $record.status='COMPLETE'
}catch{$record.failure='JSON_FRAMEWORK_FAILED'}finally{
 try{
  foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'JSON_FRAMEWORK_POSTPIN'}}
  if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -cne $expected){throw 'JSON_FRAMEWORK_DLL_DRIFT'}
  if($null -ne (Get-Variable exeHash -ErrorAction SilentlyContinue) -and (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -cne $exeHash){throw 'JSON_FRAMEWORK_EXE_DRIFT'}
  $record.postPins=$true
 }catch{$record.status='FAILED';if($null -eq $record.failure){$record.failure='JSON_FRAMEWORK_POSTPIN'}}
 Write-New 'Receipt.json' ($utf8.GetBytes(($record|ConvertTo-Json -Depth 8)))
}
if($record.status -cne 'COMPLETE' -or -not $record.postPins){throw 'JSON_FRAMEWORK_FAILED'}
'PASS JSON_FRAMEWORK_OFFLINE_ONLY'
