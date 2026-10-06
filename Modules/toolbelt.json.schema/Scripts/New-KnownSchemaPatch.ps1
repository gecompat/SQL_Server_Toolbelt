#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$QualifiedDirectory,
 [Parameter(Mandatory)][string]$BaselineClosurePath,
 [Parameter(Mandatory)][string]$OutputPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent $PSScriptRoot
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$commonPath=Join-Path $PSScriptRoot 'SchemaPatch.Common.ps1'
. $commonPath
# Eine additive Schemazeile ersetzt nur die Schemaidentität im Kandidaten.
# Core-/Constructorframes behalten ihre historischen Felder und Nachweisgrenzen.
# Der Generator schreibt niemals die kanonische oder historische Registry.
try{
 $qualified=[IO.Path]::GetFullPath($QualifiedDirectory)
 $receiptPath=Join-Path $qualified 'Receipt.private.json'
 $frozenPath=Join-Path $qualified 'FrozenInputs.private.json'
 $receipt=Get-Content -LiteralPath $receiptPath -Raw|ConvertFrom-Json -AsHashtable
 if($receipt.scope -cne 'BOUNDED_SCHEMA_PATCH' -or $receipt.status -cne 'PASSED' -or -not $receipt.postPins -or
  $receipt.qualificationScope -cne 'OFFLINE_BOUNDED_SCHEMA_PATCH_FRAMEWORK_AND_OWN_IL_AND_CANONICAL_PROJECT_BYTE_EQUALITY' -or
  $receipt.moduleVersion -cne '1.0.1' -or $receipt.managedVersion -cne '1.0.1.0'){throw 'SCHEMA_PATCH_UNQUALIFIED_INPUT'}
 $pins=@(Get-Content -LiteralPath $frozenPath -Raw|ConvertFrom-Json -AsHashtable)
 Assert-SchemaPatchPins $pins
 $closure=Read-SchemaPatchClosure $BaselineClosurePath
 if((Get-SchemaPatchHash $BaselineClosurePath) -cne $receipt.knownClosureSha256 -or
  $closure.artifacts[0].ArtifactId -cne $receipt.coreArtifactId -or
  $closure.artifacts[0].Fields.binarySha256 -cne $receipt.coreSha256){throw 'SCHEMA_PATCH_BASELINE_DRIFT'}
 $phaseNames=@('CompileSchema','SchemaIL','CanonicalSchema','CompileSchemaHarness','CompileNumbersHarness','CompileBridgeHarness')
 foreach($culture in @('en-US','de-DE','tr-TR')){$phaseNames+=@(('Schema-'+$culture),('Numbers-'+$culture),('Bridge-'+$culture))}
 if(@($receipt.phases).Count -ne $phaseNames.Count){throw 'SCHEMA_PATCH_PHASE_SET'}
 for($i=0;$i -lt $phaseNames.Count;$i++){
  $phase=$receipt.phases[$i]
  if($phase.name -cne $phaseNames[$i] -or $phase.status -cne 'PASSED' -or $phase.exitCode -ne 0 -or
   -not $phase.captureComplete -or -not $phase.emptyStderr){throw 'SCHEMA_PATCH_PHASE_EVIDENCE'}
  if($phase.name -cmatch '^Schema-(en-US|de-DE|tr-TR)$'){
   if($phase.culture -cne $Matches[1] -or $phase.cases -ne $receipt.expectedSchemaCases -or $phase.assertions -ne $receipt.expectedSchemaAssertions -or
    $phase.cases -lt 169 -or $phase.assertions -lt 1275){throw 'SCHEMA_PATCH_SCHEMA_ORACLE'}
  }elseif($phase.name -cmatch '^Numbers-(en-US|de-DE|tr-TR)$'){
   if($phase.culture -cne $Matches[1] -or $phase.cases -ne 854 -or $phase.assertions -ne 6830){throw 'SCHEMA_PATCH_NUMBER_ORACLE'}
  }elseif($phase.name -cmatch '^Bridge-(en-US|de-DE|tr-TR)$'){
   if($phase.culture -cne $Matches[1] -or $phase.assertions -ne 120){throw 'SCHEMA_PATCH_BRIDGE_ORACLE'}
  }
 }
 if(-not $receipt.phases[2].byteEqual){throw 'SCHEMA_PATCH_CANONICAL_EVIDENCE'}
 $binaryNames=@('Toolbelt.JsonCore.dll','Toolbelt.JsonSchema.dll','SchemaHarness.exe','NumbersHarness.exe','BridgeHarness.exe')
 if(@($receipt.binaryPins).Count -ne $binaryNames.Count){throw 'SCHEMA_PATCH_BINARY_SET'}
 foreach($name in $binaryNames){
  $entries=@($receipt.binaryPins|Where-Object{$_.fileName -ceq $name})
  $path=Join-Path $qualified $name
  if($entries.Count -ne 1 -or (Get-SchemaPatchHash $path) -cne $entries[0].sha256 -or
   (Get-SchemaPatchHash $path 'SHA512') -cne $entries[0].sha512){throw 'SCHEMA_PATCH_BINARY_DRIFT'}
 }
 $core=Join-Path $qualified 'Toolbelt.JsonCore.dll';$schema=Join-Path $qualified 'Toolbelt.JsonSchema.dll'
 if((Get-SchemaPatchHash $core) -cne $closure.artifacts[0].Fields.binarySha256 -or
  (Get-SchemaPatchHash $core 'SHA512') -cne $closure.artifacts[0].Fields.binarySha512 -or
  (Get-SchemaPatchHash (Join-Path $qualified 'canonical/Toolbelt.JsonSchema.dll')) -cne (Get-SchemaPatchHash $schema)){throw 'SCHEMA_PATCH_PRODUCT_PIN'}
 $identity=[Reflection.AssemblyName]::GetAssemblyName($schema)
 if($identity.Name -cne 'Toolbelt.JsonSchema' -or $identity.Version.ToString() -cne '1.0.1.0'){throw 'SCHEMA_PATCH_IDENTITY'}
 $ilPath=Join-Path $qualified 'Toolbelt.JsonSchema.IL.private.json'
 $il=Get-Content -LiteralPath $ilPath -Raw|ConvertFrom-Json -AsHashtable
 if($il.status -cne 'PASS' -or @($il.unknown).Count -ne 0 -or $il.frameworkTransitiveSafe){throw 'SCHEMA_PATCH_IL_EVIDENCE'}
 $project=Join-Path $moduleRoot 'Clr/Toolbelt.JsonSchema.csproj'
 $sources=@(Get-SchemaPatchSources $project)
 if((Get-SchemaPatchHash $project) -cne $receipt.projectSha256 -or $sources.Count -ne @($receipt.sources).Count){throw 'SCHEMA_PATCH_SOURCE_SET'}
 for($i=0;$i -lt $sources.Count;$i++){
  if($sources[$i].relative -cne $receipt.sources[$i].relative -or $sources[$i].sha256 -cne $receipt.sources[$i].sha256){throw 'SCHEMA_PATCH_SOURCE_DRIFT'}
 }
 $guardPaths=@($receiptPath,$frozenPath,$BaselineClosurePath,$commonPath,$PSCommandPath,$ilPath,$project,$core,$schema,(Join-Path $qualified 'canonical/Toolbelt.JsonSchema.dll'))
 $guardPaths+=@($binaryNames|ForEach-Object{Join-Path $qualified $_})
 $guards=@($guardPaths|ForEach-Object{[ordered]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-SchemaPatchHash $_)}})
 $output=Assert-SchemaPatchPrivateOutput $repoRoot $OutputPath
 $schemaRow=$closure.artifacts[2];$fields=$schemaRow.Fields
 $fields.moduleVersion='1.0.1';$fields.managedVersion='1.0.1.0'
 $fields.binarySha256=Get-SchemaPatchHash $schema;$fields.binarySha512=Get-SchemaPatchHash $schema 'SHA512'
 $fields.projectSha256=$receipt.projectSha256;$fields.qualificationScope=$receipt.qualificationScope
 $sourceKeys=@($schemaRow.fieldOrder|Where-Object{$_ -clike 'source/*'})
 if($sourceKeys.Count -ne $sources.Count){throw 'SCHEMA_PATCH_BASELINE_SOURCE_SET'}
 for($i=0;$i -lt $sources.Count;$i++){
  $key='source/'+$sources[$i].relative
  if($key -cne $sourceKeys[$i]){throw 'SCHEMA_PATCH_BASELINE_SOURCE_SET'}
  $fields[$key]=$sources[$i].sha256
 }
 $schemaRow.ArtifactId=Get-SchemaPatchArtifactId $fields @($schemaRow.fieldOrder)
 # Erst nach vollständiger Revalidierung atomar neu anlegen; keine Teilregistry.
 Assert-SchemaPatchPins (@($pins)+@($guards))
 $parent=Split-Path -Parent $output
 if(-not(Test-Path -LiteralPath $parent)){[void][IO.Directory]::CreateDirectory($parent)}
 Write-SchemaPatchJson $output $closure
 Assert-SchemaPatchPins (@($pins)+@($guards))
 'PASS KNOWN_SCHEMA_PATCH_ONLY'
}catch{
 $category=$_.Exception.Message
 if($category -cnotmatch '^SCHEMA_PATCH_[A-Z_]+$'){$category='SCHEMA_PATCH_GENERATION_FAILED'}
 throw $category
}
