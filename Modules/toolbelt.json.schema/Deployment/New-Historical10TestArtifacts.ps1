[CmdletBinding()]
param([Parameter(Mandatory)][string]$MSBuildPath,
 [Parameter(Mandatory)][string]$CoreAssemblyPath,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$watch=[Diagnostics.Stopwatch]::StartNew()
try{
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$helper=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $helper
$revision='0185603b0e30e4d0b2dd9c1cfa4e698fccd9feb9'
$registryRelative='Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
$snapshot=Join-Path $repoRoot 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE_SCHEMA_1_0.json'
$registry=Get-Content -LiteralPath $snapshot -Raw -Encoding UTF8|ConvertFrom-Json
if($registry.status-cne'OFFLINE_QUALIFIED_KNOWN_ARTIFACTS'-or$registry.framing-cne'toolbelt.json.shared-closure/v1'-or
 $registry.framePrefix-cne'TBXJSONCLOSURE1'-or@($registry.artifacts).Count-ne3){throw 'HISTORICAL10_REGISTRY'}
# Endliche Original-Compilelisten: keine vom Snapshot erfundenen Pfade oder Wildcards.
$sources=[ordered]@{
 'toolbelt.json.core'=@('JsonCanonicalCore.cs','JsonWorkBudget.cs','JsonTokenDocument.cs','JsonOrdinalComparer.cs','JsonSyntaxScanner.cs','Properties/AssemblyInfo.cs')
 'toolbelt.json.constructors'=@('AgfValidCodec.cs','AgfFaultCodec.cs','AgfDispatcher.cs','OwnedAggregateBuilder.cs','JsonAggregates.cs','JsonEntryEvaluateBridge.cs','Properties/AssemblyInfo.cs')
 'toolbelt.json.schema'=@('SignedDecimalDigits.cs','ExactJsonNumber.cs','SchemaTree.cs','LocalSchemaReference.cs','SchemaPreflight.cs','SchemaValidator.cs','JsonSchemaBridge.cs','Properties/AssemblyInfo.cs')
}
$managed=@{'toolbelt.json.core'='Toolbelt.JsonCore';'toolbelt.json.constructors'='Toolbelt.JsonConstructors';'toolbelt.json.schema'='Toolbelt.JsonSchema'}
$rows=@{}
foreach($row in $registry.artifacts){
 $module=$row.Fields.moduleId
 if(-not$sources.Contains($module)-or$rows.ContainsKey($module)){throw 'HISTORICAL10_MODULE'}
 $version=if($module-ceq'toolbelt.json.constructors'){'1.3.0'}else{'1.0.0'}
 if($row.Fields.moduleVersion-cne$version-or$row.Fields.managedVersion-cne($version+'.0')-or
  $row.Fields.managedAssembly-cne$managed[$module]-or$row.Fields.permissionSet-cne'SAFE'){throw 'HISTORICAL10_IDENTITY'}
 $names=@($row.Fields.psobject.Properties|Where-Object{$_.Name.StartsWith('source/',[StringComparison]::Ordinal)}|ForEach-Object{$_.Name.Substring(7)})
 if($names.Count-ne$sources[$module].Count-or@($names|Where-Object{$_-cnotin$sources[$module]}).Count-ne0){throw 'HISTORICAL10_SOURCE_SET'}
 $rows[$module]=$row
}
foreach($module in @('toolbelt.json.constructors','toolbelt.json.schema')){
 if($rows[$module].Fields.coreArtifactId-cne$rows['toolbelt.json.core'].ArtifactId){throw 'HISTORICAL10_DEPENDENCY'}
}
# Dieselbe endliche Includeclosure wie im Original; sie wird nach Capture verglichen.
$sqlFiles=@(
 'toolbelt.json.core/Deployment/Deploy.sql','toolbelt.json.core/Deployment/Uninstall.sql',
 'toolbelt.json.core/Deployment/KnownArtifact.sql','toolbelt.json.core/Deployment/Preflight.sql',
 'toolbelt.json.constructors/Deployment/Deploy.sql','toolbelt.json.constructors/Deployment/Uninstall.sql',
 'toolbelt.json.constructors/Deployment/KnownArtifact.sql','toolbelt.json.constructors/Deployment/KnownArtifact1_3.sql',
 'toolbelt.json.constructors/Deployment/ClrPreflight.sql',
 'toolbelt.json.constructors/Source/JsonEntryEvaluate.sql','toolbelt.json.constructors/Source/JsonAggregates.sql',
 'toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql','toolbelt.json.constructors/Source/USP_JsonArray.sql',
 'toolbelt.json.constructors/Source/USP_JsonObject.sql','toolbelt.json.constructors/Source/USP_JsonArraysByGroup.sql',
 'toolbelt.json.constructors/Source/USP_JsonObjectsByGroup.sql',
 'toolbelt.json.schema/Deployment/Deploy.sql','toolbelt.json.schema/Deployment/Uninstall.sql',
 'toolbelt.json.schema/Deployment/KnownArtifact.sql','toolbelt.json.schema/Deployment/State.sql',
 'toolbelt.json.schema/Deployment/Preflight.sql','toolbelt.json.schema/Source/JsonSchemaBridge.sql',
 'toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql')
$files=[Collections.Generic.List[string]]::new()
foreach($module in $sources.Keys){
 foreach($source in $sources[$module]){$files.Add('Modules/'+$module+'/Clr/'+$source)}
 $files.Add('Modules/'+$module+'/Clr/'+$managed[$module]+'.csproj')
}
foreach($relative in $sqlFiles){$files.Add('Modules/'+$relative)}
$files.Add($registryRelative)
$files.Add('Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1')
$files.Add('Modules/toolbelt.json.core/Scripts/Expand-JsonClosureSql.ps1')
if($files.Count-ne50){throw 'HISTORICAL10_FILE_SET'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $output)){throw 'HISTORICAL10_OUTPUT'}
$git=(Get-Command git -CommandType Application|Select-Object -First 1).Source
$processHost=(Get-Process -Id $PID).Path
$inputs=@($PSCommandPath,$helper,$snapshot,$git,$MSBuildPath,$CoreAssemblyPath,$processHost)|ForEach-Object{
 [pscustomobject]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant()}
}
function Check-Time {
 if($watch.ElapsedMilliseconds-ge60000){throw 'HISTORICAL10_TOTAL_TIMEOUT'}
}
function Run-Child([string]$Name,[string]$File,[string[]]$Arguments,[string]$BinaryPath){
 Check-Time
 $timeout=[int][Math]::Min(5000,60000-$watch.ElapsedMilliseconds)
 $parameters=@{FileName=$File;Arguments=$Arguments;TimeoutMilliseconds=$timeout}
 if($BinaryPath){$parameters.BinaryOutputPath=$BinaryPath}
 $run=Invoke-OwnedProcess @parameters
 Check-Time
 $record.phases+=@([ordered]@{name=$Name;actualExitCode=$run.ExitCode;captureComplete=$run.CaptureComplete;emptyStderr=($run.Stderr.Length-eq0)})
 if($run.ExitCode-ne0-or-not$run.CaptureComplete-or$run.Stderr.Length-ne0){throw ('HISTORICAL10_PROCESS_'+$Name)}
 return $run
}
function Check-Pins($Pins){
 foreach($pin in $Pins){
  Check-Time
  if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$pin.sha256){throw 'HISTORICAL10_POST_PIN'}
 }
}
$record=[ordered]@{scope='GENUINE_KNOWN_SCHEMA10_ONLY';status='FAILED';revision=$revision;
 artifactId=$rows['toolbelt.json.schema'].ArtifactId;binarySha256=$rows['toolbelt.json.schema'].Fields.binarySha256;
 binarySha512=$rows['toolbelt.json.schema'].Fields.binarySha512;
 snapshotSha256=(Get-FileHash -LiteralPath $snapshot -Algorithm SHA256).Hash.ToLowerInvariant();
 nativeQualification='NOT_EXECUTED';postPins=$false;phases=@();inputPins=$inputs;sourcePins=@();productPins=@()}
$blobPins=@()
$productPins=@()
$created=$false
try{
 $ignored=Run-Child 'Ignore' $git @('-C',$repoRoot,'check-ignore','--quiet','--',$output) ''
 $coreIdentity=[Reflection.AssemblyName]::GetAssemblyName([IO.Path]::GetFullPath($CoreAssemblyPath))
 $coreRow=$rows['toolbelt.json.core']
 if((Get-FileHash -LiteralPath $CoreAssemblyPath -Algorithm SHA256).Hash.ToLowerInvariant()-cne$coreRow.Fields.binarySha256-or
  (Get-FileHash -LiteralPath $CoreAssemblyPath -Algorithm SHA512).Hash.ToLowerInvariant()-cne$coreRow.Fields.binarySha512-or
  $coreIdentity.Name-cne$coreRow.Fields.managedAssembly-or$coreIdentity.Version.ToString()-cne$coreRow.Fields.managedVersion){throw 'HISTORICAL10_CORE_PIN'}
 [void][IO.Directory]::CreateDirectory($output);$created=$true
 $sourceRoot=Join-Path $output 'genuine-source'
 foreach($relative in $files){
  Check-Time
  $path=Join-Path $sourceRoot $relative
  [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
  # BaseStream-Capture erhält die Gitblobbytes einschließlich EOL und Encoding.
  [void](Run-Child 'GitBlob' $git @('-C',$repoRoot,'show',($revision+':'+$relative)) $path)
  $blobPins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()})
 }
 $capturedRegistry=Join-Path $sourceRoot $registryRelative
 if((Get-FileHash -LiteralPath $capturedRegistry -Algorithm SHA256).Hash-cne(Get-FileHash -LiteralPath $snapshot -Algorithm SHA256).Hash){throw 'HISTORICAL10_SNAPSHOT_DRIFT'}
 foreach($module in $sources.Keys){
  $row=$rows[$module]
  $moduleRoot=Join-Path $sourceRoot ('Modules/'+$module)
  $project=Join-Path $moduleRoot ('Clr/'+$managed[$module]+'.csproj')
  if((Get-FileHash -LiteralPath $project -Algorithm SHA256).Hash.ToLowerInvariant()-cne$row.Fields.projectSha256){throw 'HISTORICAL10_PROJECT'}
  $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
  $reader=[Xml.XmlReader]::Create($project,$settings);$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null
  try{$xml.Load($reader)}finally{$reader.Dispose()}
  $compiled=@($xml.SelectNodes('//*[local-name()="Compile"]')|ForEach-Object{$_.GetAttribute('Include').Replace('\','/')})
  if($compiled.Count-ne$sources[$module].Count-or@($compiled|Where-Object{$_-cnotin$sources[$module]}).Count-ne0-or
   @($compiled|Select-Object -Unique).Count-ne$compiled.Count){throw 'HISTORICAL10_COMPILE_SET'}
  foreach($source in $sources[$module]){
   if((Get-FileHash -LiteralPath (Join-Path $moduleRoot ('Clr/'+$source)) -Algorithm SHA256).Hash.ToLowerInvariant()-cne
    $row.Fields.psobject.Properties['source/'+$source].Value){throw 'HISTORICAL10_SOURCE'}
  }
 }
 $expand=Join-Path $sourceRoot 'Modules/toolbelt.json.core/Scripts/Expand-JsonClosureSql.ps1'
 . $expand
 if($script:JsonClosureRoot-cne$sourceRoot-or$script:JsonClosureSqlPaths.Count-ne$sqlFiles.Count-or
  ($script:JsonClosureSqlPaths-join'|')-cne($sqlFiles-join'|')){throw 'HISTORICAL10_INCLUDE_SET'}
 $buildRoot=Join-Path $output 'build'
 $project=Join-Path $sourceRoot 'Modules/toolbelt.json.schema/Clr/Toolbelt.JsonSchema.csproj'
 $build=Run-Child 'Build' $MSBuildPath @($project,'/t:Rebuild','/p:Configuration=Release','/p:Platform=AnyCPU','/m:1','/nr:false','/nologo','/v:minimal','/noAutoResponse',
  ('/p:CoreReferenceHintPath='+[IO.Path]::GetFullPath($CoreAssemblyPath)),('/p:OutputPath='+$buildRoot+[IO.Path]::DirectorySeparatorChar),
  ('/p:IntermediateOutputPath='+(Join-Path $buildRoot 'obj/') )) ''
 [IO.File]::WriteAllText((Join-Path $output 'Build.stdout.private'),$build.Stdout)
 [IO.File]::WriteAllText((Join-Path $output 'Build.stderr.private'),$build.Stderr)
 $dll=Join-Path $buildRoot 'Toolbelt.JsonSchema.dll';$row=$rows['toolbelt.json.schema']
 $identity=[Reflection.AssemblyName]::GetAssemblyName($dll)
 if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLowerInvariant()-cne$row.Fields.binarySha256-or
  (Get-FileHash -LiteralPath $dll -Algorithm SHA512).Hash.ToLowerInvariant()-cne$row.Fields.binarySha512-or
  $identity.Name-cne$row.Fields.managedAssembly-or$identity.Version.ToString()-cne$row.Fields.managedVersion){throw 'HISTORICAL10_UNKNOWN_BINARY'}
 $productPins+=@([pscustomobject]@{path=$dll;sha256=$row.Fields.binarySha256})
 Check-Pins (@($inputs)+@($blobPins)+@($productPins))
 $packager=Join-Path $sourceRoot 'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1'
 $package=Run-Child 'Package' $processHost @('-NoProfile','-NonInteractive','-File',$packager,
  '-ModuleId','toolbelt.json.schema','-AssemblyPath',$dll,'-CoreAssemblyPath',[IO.Path]::GetFullPath($CoreAssemblyPath),
  '-OutputDirectory',(Join-Path $output 'release')) ''
 if($package.Stdout-cne"PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY`r`n"-and$package.Stdout-cne"PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY`n"){throw 'HISTORICAL10_PACKAGE_WITNESS'}
 foreach($name in @('Toolbelt.JsonSchema.dll','Deploy.WithAssembly.sql','Uninstall.Expanded.sql','Toolbelt.JsonSchema.trust-manifest.json')){
  $path=Join-Path (Join-Path $output 'release') $name
  $productPins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()})
 }
 Check-Pins (@($inputs)+@($blobPins)+@($productPins))
 $record.postPins=$true;$record.status='COMPLETE'
}finally{
 if($created){
  $record.sourcePins=$blobPins
  $record.productPins=$productPins
  [IO.File]::WriteAllText((Join-Path $output 'Receipt.private.json'),($record|ConvertTo-Json -Depth 8))
 }
 $watch.Stop()
}
if($record.status-cne'COMPLETE'-or-not$record.postPins){throw 'HISTORICAL10_FAILED'}
'PASS GENUINE_KNOWN_SCHEMA10_ONLY'
}catch{
 # Keine unerwarteten Datei-/MSBuild-/Hostdetails in öffentliche CI-Diagnosen.
 $category=$_.Exception.Message
 if($category-cnotmatch '^(HISTORICAL10_[A-Z0-9_]+|OWNED_PROCESS_[A-Z0-9_]+)$'){$category='HISTORICAL10_FAILED'}
 throw $category
}finally{$watch.Stop()}
