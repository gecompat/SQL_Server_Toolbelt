[CmdletBinding()]
param([Parameter(Mandatory)][string]$MSBuildPath,
 [Parameter(Mandatory)][string]$QualifiedDirectory,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$helper=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $helper
$qualified=[IO.Path]::GetFullPath($QualifiedDirectory)
$receipt=Get-Content -LiteralPath (Join-Path $qualified 'Receipt.private.json') -Raw|ConvertFrom-Json
if($receipt.scope-cne'OFFLINE_SOURCE_FRAMEWORK_ONLY'-or$receipt.status-cne'COMPLETE'-or-not$receipt.postPins){throw 'PROJECT_BUILD_UNQUALIFIED_INPUT'}
$pins=@(Get-Content -LiteralPath (Join-Path $qualified 'FrozenInputs.private.json') -Raw|ConvertFrom-Json)
foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash-cne$pin.sha256){throw 'PROJECT_BUILD_SOURCE_DRIFT'}}
$inputBinaries=@('Toolbelt.JsonCore','Toolbelt.JsonConstructors','Toolbelt.JsonSchema')
foreach($product in $inputBinaries){
 $entries=@($receipt.binaryPins|Where-Object{$_.fileName-ceq($product+'.dll')})
 if($entries.Count-ne1-or(Get-FileHash -LiteralPath (Join-Path $qualified ($product+'.dll')) -Algorithm SHA256).Hash-cne$entries[0].sha256){throw 'PROJECT_BUILD_BINARY_PIN'}
}
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $output)){throw 'PROJECT_BUILD_OUTPUT'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE-ne0){throw 'PROJECT_BUILD_OUTPUT_NOT_IGNORED'}
$driverPins=@($MSBuildPath,$helper,$PSCommandPath)|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}}
[void][IO.Directory]::CreateDirectory($output)
$record=[ordered]@{scope='CANONICAL_PROJECT_BYTE_EQUALITY_ONLY';status='FAILED';postPins=$false;phases=@()}
try{
 foreach($product in $inputBinaries){
  $module=switch($product){'Toolbelt.JsonCore'{'toolbelt.json.core'};'Toolbelt.JsonConstructors'{'toolbelt.json.constructors'};'Toolbelt.JsonSchema'{'toolbelt.json.schema'}}
  $directory=Join-Path $output ($module+'/')
  $arguments=@((Join-Path $repoRoot ('Modules/'+$module+'/Clr/'+$product+'.csproj')),
   '/nologo','/v:minimal','/m:1','/nr:false','/t:Build','/p:Configuration=Release',
   ('/p:OutputPath='+$directory),('/p:IntermediateOutputPath='+(Join-Path $directory 'obj/')))
  if($product-cne'Toolbelt.JsonCore'){$arguments+=('/p:CoreReferenceHintPath='+(Join-Path $output 'toolbelt.json.core/Toolbelt.JsonCore.dll'))}
  $process=Invoke-OwnedProcess -FileName $MSBuildPath -Arguments $arguments -TimeoutMilliseconds 45000
  [IO.File]::WriteAllText((Join-Path $output ($module+'.stdout.private')),$process.Stdout)
  [IO.File]::WriteAllText((Join-Path $output ($module+'.stderr.private')),$process.Stderr)
  if($process.ExitCode-ne0-or-not$process.CaptureComplete-or$process.Stderr.Length-ne0){throw 'PROJECT_BUILD_PROCESS'}
  $expected=(Get-FileHash -LiteralPath (Join-Path $qualified ($product+'.dll')) -Algorithm SHA256).Hash
  $actual=(Get-FileHash -LiteralPath (Join-Path $directory ($product+'.dll')) -Algorithm SHA256).Hash
  if($actual-cne$expected){throw 'PROJECT_BUILD_BYTE_MISMATCH'}
  $record.phases+=@([ordered]@{product=$product;exitCode=0;captureComplete=$true;byteEqual=$true;sha256=$actual})
  Write-Output ($product+': byte equal')
 }
 $record.status='COMPLETE'
}finally{
 try{
  foreach($pin in @($pins)+@($driverPins)){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash-cne$pin.sha256){throw 'PROJECT_BUILD_POSTPIN'}}
  foreach($entry in $receipt.binaryPins){if((Get-FileHash -LiteralPath (Join-Path $qualified $entry.fileName) -Algorithm SHA256).Hash-cne$entry.sha256){throw 'PROJECT_BUILD_POSTBINARY'}}
  $record.postPins=$true
 }catch{$record.status='FAILED'}
 [IO.File]::WriteAllText((Join-Path $output 'Receipt.private.json'),($record|ConvertTo-Json -Depth 6))
}
if($record.status-cne'COMPLETE'-or-not$record.postPins){throw 'PROJECT_BUILD_FAILED'}
'PASS JSON_CANONICAL_PROJECT_BYTE_EQUALITY CASES 3'
