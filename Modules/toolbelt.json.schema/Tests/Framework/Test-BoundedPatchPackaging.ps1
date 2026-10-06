#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$QualifiedDirectory,
 [Parameter(Mandatory)][string]$BaselineClosurePath,
 [Parameter(Mandatory)][string]$PowerShellPath,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$common=Join-Path $moduleRoot 'Scripts/SchemaPatch.Common.ps1'
$owned=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
$generator=Join-Path $moduleRoot 'Scripts/New-KnownSchemaPatch.ps1'
$driver=Join-Path $PSScriptRoot 'Invoke-BoundedPatchQualification.ps1'
. $common
. $owned
$record=$null;$output=$null
try{
 $qualified=[IO.Path]::GetFullPath($QualifiedDirectory)
 $baseline=Read-SchemaPatchClosure $BaselineClosurePath
 $inputReceipt=Get-Content -LiteralPath (Join-Path $qualified 'Receipt.private.json') -Raw|ConvertFrom-Json -AsHashtable
 $pins=@(Get-Content -LiteralPath (Join-Path $qualified 'FrozenInputs.private.json') -Raw|ConvertFrom-Json -AsHashtable)
 $guardFiles=@($BaselineClosurePath,$PowerShellPath,$common,$owned,$generator,$driver,$PSCommandPath,(Join-Path $qualified 'Receipt.private.json'),(Join-Path $qualified 'FrozenInputs.private.json'),(Join-Path $qualified 'Toolbelt.JsonSchema.IL.private.json'),(Join-Path $qualified 'canonical/Toolbelt.JsonSchema.dll'))
 $guardFiles+=@($inputReceipt.binaryPins|ForEach-Object{Join-Path $qualified $_.fileName})
 $guards=@($guardFiles|ForEach-Object{[ordered]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-SchemaPatchHash $_)}})
 Assert-SchemaPatchPins (@($pins)+@($guards))
 $output=Assert-SchemaPatchPrivateOutput $repoRoot $OutputDirectory
 [void][IO.Directory]::CreateDirectory($output)
 $record=[ordered]@{scope='BOUNDED_SCHEMA_PATCH_PACKAGING';status='FAILED';postPins=$false;cases=@()}
 function Invoke-PackagingCase([string]$Name,[string]$InputDirectory,[string]$ExpectedCode,[string]$CandidatePath,[string]$Baseline=$BaselineClosurePath) {
  $process=Invoke-OwnedProcess -FileName $PowerShellPath -Arguments @('-NoProfile','-NonInteractive','-File',$generator,'-QualifiedDirectory',$InputDirectory,'-BaselineClosurePath',$Baseline,'-OutputPath',$CandidatePath) -TimeoutMilliseconds 15000
  [IO.File]::WriteAllText((Join-Path $output ($Name+'.stdout.private')),$process.Stdout)
  [IO.File]::WriteAllText((Join-Path $output ($Name+'.stderr.private')),$process.Stderr)
  $expectedExit=if($ExpectedCode){1}else{0}
  if(-not $process.CaptureComplete -or $process.ExitCode -ne $expectedExit){throw 'SCHEMA_PATCH_PACKAGING_EXIT'}
  if($ExpectedCode){
   if($process.Stdout.Length -ne 0 -or $process.Stderr -cnotmatch ('(?<![A-Z_])'+[regex]::Escape($ExpectedCode)+'(?![A-Z_])') -or
    ($Name -cne 'existing-output' -and (Test-Path -LiteralPath $CandidatePath))){throw 'SCHEMA_PATCH_PACKAGING_REJECTION'}
  }elseif($process.Stderr.Length -ne 0 -or $process.Stdout -cnotmatch '\APASS KNOWN_SCHEMA_PATCH_ONLY\r?\n\z'){throw 'SCHEMA_PATCH_PACKAGING_PASS'}
  $record.cases+=@([ordered]@{name=$Name;exitCode=$process.ExitCode;captureComplete=$true;expectedCode=$ExpectedCode;status='PASSED'})
 }
 $candidatePath=Join-Path $output 'candidate.json'
 Invoke-PackagingCase 'qualified-schema-patch' $qualified '' $candidatePath
 $candidate=Get-Content -LiteralPath $candidatePath -Raw|ConvertFrom-Json -AsHashtable
 if($candidate.artifacts.Count -ne 3){throw 'SCHEMA_PATCH_PACKAGING_ROWS'}
 for($i=0;$i -lt 2;$i++){
  if((ConvertTo-Json -InputObject $candidate.artifacts[$i] -Depth 12 -Compress) -cne
   (ConvertTo-Json -InputObject $baseline.artifacts[$i] -Depth 12 -Compress)){throw 'SCHEMA_PATCH_PACKAGING_HISTORICAL_CHANGE'}
 }
 $before=$baseline.artifacts[2];$after=$candidate.artifacts[2]
 if(($after.fieldOrder -join '|') -cne ($before.fieldOrder -join '|') -or
  $after.ArtifactId -ceq $before.ArtifactId -or $after.ArtifactId -cne (Get-SchemaPatchArtifactId $after.Fields @($after.fieldOrder))){throw 'SCHEMA_PATCH_PACKAGING_SCHEMA_FRAME'}
 $allowed=@('moduleVersion','managedVersion','binarySha256','binarySha512','projectSha256','qualificationScope')
 foreach($key in $before.fieldOrder){
  if($key -cnotin $allowed -and $key -cnotlike 'source/*' -and $before.Fields[$key] -cne $after.Fields[$key]){throw 'SCHEMA_PATCH_PACKAGING_SCHEMA_FIELDS'}
 }
 $candidatePin=[ordered]@{path=$candidatePath;sha256=(Get-SchemaPatchHash $candidatePath)}
 Invoke-PackagingCase 'existing-output' $qualified 'SCHEMA_PATCH_PRIVATE_OUTPUT' $candidatePath
 Assert-SchemaPatchPins @($candidatePin)
 # Identische Binaries und ein gültiger Constructorframe erlauben keine
 # Umdeklaration seiner historischen Qualifikationsaussage.
 $relabeled=Get-Content -LiteralPath $BaselineClosurePath -Raw|ConvertFrom-Json -AsHashtable
 $relabeled.artifacts[1].Fields.qualificationScope='OFFLINE_RELABELLED_CONSTRUCTOR'
 $relabeled.artifacts[1].ArtifactId=Get-SchemaPatchArtifactId $relabeled.artifacts[1].Fields @($relabeled.artifacts[1].fieldOrder)
 $relabeledPath=Join-Path $output 'relabeled-constructor.json'
 Write-SchemaPatchJson $relabeledPath $relabeled
 # Auch das lokale Receipt behauptet den umetikettierten Baselinehash, damit
 # das Orakel gezielt den festen Snapshotpin statt einen Hashkonflikt prüft.
 $relabeledQualified=Join-Path $output 'relabeled-qualified'
 [void][IO.Directory]::CreateDirectory((Join-Path $relabeledQualified 'canonical'))
 foreach($entry in $inputReceipt.binaryPins){[IO.File]::Copy((Join-Path $qualified $entry.fileName),(Join-Path $relabeledQualified $entry.fileName),$false)}
 foreach($name in @('FrozenInputs.private.json','Toolbelt.JsonSchema.IL.private.json','canonical/Toolbelt.JsonSchema.dll')){
  [IO.File]::Copy((Join-Path $qualified $name),(Join-Path $relabeledQualified $name),$false)
 }
 $relabeledReceipt=Get-Content -LiteralPath (Join-Path $qualified 'Receipt.private.json') -Raw|ConvertFrom-Json -AsHashtable
 $relabeledReceipt.knownClosureSha256=Get-SchemaPatchHash $relabeledPath
 Write-SchemaPatchJson (Join-Path $relabeledQualified 'Receipt.private.json') $relabeledReceipt
 Invoke-PackagingCase 'relabeled-constructor' $relabeledQualified 'SCHEMA_PATCH_BASELINE_PIN' (Join-Path $output 'relabeled.candidate.json') $relabeledPath
 # Absichtlich nicht existente Toolpfade: Der Baselinepin muss vor Toolprüfung,
 # Compilerstart oder Ausgabeerstellung greifen, ohne Produktcode aufzurufen.
 $negativeOutput=Join-Path $output 'driver-rejected-output'
 $process=Invoke-OwnedProcess -FileName $PowerShellPath -Arguments @('-NoProfile','-NonInteractive','-File',$driver,
  '-CompilerPath','NOT_USED','-ReferenceDirectory','NOT_USED','-FrameworkPowerShell','NOT_USED','-MSBuildPath','NOT_USED',
  '-CoreAssemblyPath','NOT_USED','-ExpectedSchemaCases','169','-ExpectedSchemaAssertions','1275',
  '-KnownClosurePath',$relabeledPath,'-OutputDirectory',$negativeOutput) -TimeoutMilliseconds 15000
 [IO.File]::WriteAllText((Join-Path $output 'driver-baseline-pin.stdout.private'),$process.Stdout)
 [IO.File]::WriteAllText((Join-Path $output 'driver-baseline-pin.stderr.private'),$process.Stderr)
 if($process.ExitCode -ne 1 -or -not $process.CaptureComplete -or $process.Stdout.Length -ne 0 -or
  $process.Stderr -cnotmatch '(?<![A-Z_])SCHEMA_PATCH_BASELINE_PIN(?![A-Z_])' -or (Test-Path -LiteralPath $negativeOutput)){throw 'SCHEMA_PATCH_PACKAGING_DRIVER_PIN'}
 $record.cases+=@([ordered]@{name='driver-baseline-pin';exitCode=1;captureComplete=$true;expectedCode='SCHEMA_PATCH_BASELINE_PIN';status='PASSED';outputAbsent=$true})
 foreach($name in @('legacy-total-receipt','missing-phase','source-pin-drift','binary-drift')){
  $fixture=Join-Path $output $name;[void][IO.Directory]::CreateDirectory($fixture)
  $receipt=Get-Content -LiteralPath (Join-Path $qualified 'Receipt.private.json') -Raw|ConvertFrom-Json -AsHashtable
  $frozen=Get-Content -LiteralPath (Join-Path $qualified 'FrozenInputs.private.json') -Raw|ConvertFrom-Json -AsHashtable
  $code=switch($name){
   'legacy-total-receipt'{$receipt.scope='OFFLINE_SOURCE_FRAMEWORK_ONLY';$receipt.status='COMPLETE';'SCHEMA_PATCH_UNQUALIFIED_INPUT'}
   'missing-phase'{$receipt.phases=@($receipt.phases|Select-Object -SkipLast 1);'SCHEMA_PATCH_PHASE_SET'}
   'source-pin-drift'{$frozen[0].sha256='0'*64;'SCHEMA_PATCH_INPUT_DRIFT'}
   'binary-drift'{
    foreach($entry in $receipt.binaryPins){[IO.File]::Copy((Join-Path $qualified $entry.fileName),(Join-Path $fixture $entry.fileName),$false)}
    $path=Join-Path $fixture 'Toolbelt.JsonSchema.dll';$bytes=[IO.File]::ReadAllBytes($path);$bytes[-1]=$bytes[-1] -bxor 1;[IO.File]::WriteAllBytes($path,$bytes)
    'SCHEMA_PATCH_BINARY_DRIFT'
   }
  }
  Write-SchemaPatchJson (Join-Path $fixture 'Receipt.private.json') $receipt
  Write-SchemaPatchJson (Join-Path $fixture 'FrozenInputs.private.json') $frozen
  Invoke-PackagingCase $name $fixture $code (Join-Path $output ($name+'.candidate.json'))
 }
 $record['historicalFramesUnchanged']=$true;$record['schemaFieldAllowlist']=$true;$record.status='PASSED'
}catch{
 $category=$_.Exception.Message
 if($category -cnotmatch '^(SCHEMA_PATCH|OWNED_PROCESS)_[A-Z_]+$'){$category='SCHEMA_PATCH_PACKAGING_FAILED'}
 if($null -ne $record){$record.status='FAILED';$record['failure']=$category}
 throw $category
}finally{
 if($null -ne $record){
  try{Assert-SchemaPatchPins (@($pins)+@($guards));$record.postPins=$true}
  catch{$record.status='FAILED';$record['failure']='SCHEMA_PATCH_PACKAGING_POSTPIN'}
  Write-SchemaPatchJson (Join-Path $output 'Receipt.private.json') $record
 }
}
if($record.status -cne 'PASSED' -or -not $record.postPins){throw 'SCHEMA_PATCH_PACKAGING_FAILED'}
'PASS BOUNDED_SCHEMA_PATCH_PACKAGING CASES 8'
