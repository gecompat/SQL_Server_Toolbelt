[CmdletBinding()]
param([Parameter(Mandatory)][string]$QualifiedDirectory,
 [Parameter(Mandatory)][string]$ProjectBuildDirectory,
 [Parameter(Mandatory)][string]$RejectedFixtureDirectory,
 [Parameter(Mandatory)][string]$OutputPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$qualified=[IO.Path]::GetFullPath($QualifiedDirectory)
$framework=Get-Content -LiteralPath (Join-Path $qualified 'Receipt.private.json') -Raw|ConvertFrom-Json
$project=Get-Content -LiteralPath (Join-Path $ProjectBuildDirectory 'Receipt.private.json') -Raw|ConvertFrom-Json
$negative=Get-Content -LiteralPath (Join-Path $RejectedFixtureDirectory 'Receipt.private.json') -Raw|ConvertFrom-Json
if($framework.scope-cne'OFFLINE_SOURCE_FRAMEWORK_ONLY'-or$framework.status-cne'COMPLETE'-or-not$framework.postPins -or
 $project.scope-cne'CANONICAL_PROJECT_BYTE_EQUALITY_ONLY'-or$project.status-cne'COMPLETE'-or-not$project.postPins -or
 $negative.scope-cne'REJECTED_IL_FIXTURES_ONLY'-or$negative.status-cne'COMPLETE'-or-not$negative.postPins -or
 @($project.phases).Count-ne3-or@($negative.phases).Count-ne8){throw 'JSON_CLOSURE_QUALIFICATION'}
$pins=@(Get-Content -LiteralPath (Join-Path $qualified 'FrozenInputs.private.json') -Raw|ConvertFrom-Json)
foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash-cne$pin.sha256){throw 'JSON_CLOSURE_SOURCE_DRIFT'}}
$utf8=[Text.UTF8Encoding]::new($false,$true)
function Artifact([Collections.Specialized.OrderedDictionary]$fields){
 $buffer=[IO.MemoryStream]::new();$writer=[IO.BinaryWriter]::new($buffer,$utf8,$true)
 try{
  $writer.Write([Text.Encoding]::ASCII.GetBytes('TBXJSONCLOSURE1'))
  $writer.Write([uint32]$fields.Count)
  foreach($entry in $fields.GetEnumerator()){
   foreach($text in @($entry.Key,$entry.Value)){
    if($text-isnot[string]){throw 'JSON_CLOSURE_FIELD'}
    $bytes=$utf8.GetBytes($text);$writer.Write([uint32]$bytes.Length);$writer.Write($bytes)
   }
  }
  $writer.Flush();$hash=[Security.Cryptography.SHA256]::Create()
  try{$id=[BitConverter]::ToString($hash.ComputeHash($buffer.ToArray())).Replace('-','').ToLowerInvariant()}finally{$hash.Dispose()}
  return [ordered]@{ArtifactId=$id;fieldOrder=@($fields.Keys);Fields=$fields;trustAuthorization='NOT_GRANTED';nativeQualification='NOT_EXECUTED'}
 }finally{$writer.Dispose();$buffer.Dispose()}
}
$artifacts=@();$coreId=$null
$legacy=Get-Content -LiteralPath (Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Documentation/KNOWN_CLR_ARTIFACTS.json') -Raw|ConvertFrom-Json
foreach($product in @('Toolbelt.JsonCore','Toolbelt.JsonConstructors','Toolbelt.JsonSchema')){
 $module=switch($product){'Toolbelt.JsonCore'{'toolbelt.json.core'};'Toolbelt.JsonConstructors'{'toolbelt.json.constructors'};'Toolbelt.JsonSchema'{'toolbelt.json.schema'}}
 $version=if($product-ceq'Toolbelt.JsonConstructors'){'1.3.0'}else{'1.0.0'}
 $sqlName=switch($product){'Toolbelt.JsonCore'{'Toolbelt_JsonCore'};'Toolbelt.JsonConstructors'{'Toolbelt_JsonConstructors'};'Toolbelt.JsonSchema'{'Toolbelt_JsonSchema'}}
 $fileName=$product+'.dll';$binary=Join-Path $qualified $fileName
 $binaryPin=@($framework.binaryPins|Where-Object{$_.fileName-ceq$fileName})
 $buildPin=@($project.phases|Where-Object{$_.product-ceq$product})
 if($binaryPin.Count-ne1-or$buildPin.Count-ne1-or-not$buildPin[0].byteEqual-or$binaryPin[0].sha256-cne$buildPin[0].sha256 -or
  (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash-cne$binaryPin[0].sha256){throw 'JSON_CLOSURE_BINARY'}
 $il=Get-Content -LiteralPath (Join-Path $qualified ($product+'.IL.private.json')) -Raw|ConvertFrom-Json
 if($il.status-cne'PASS'-or@($il.unknown).Count-ne0-or$il.frameworkTransitiveSafe){throw 'JSON_CLOSURE_IL'}
 $identity=[Reflection.AssemblyName]::GetAssemblyName($binary)
 if($identity.Name-cne$product-or$identity.Version.ToString()-cne($version+'.0')){throw 'JSON_CLOSURE_IDENTITY'}
 $fields=[ordered]@{registrySchema='toolbelt.json.shared-closure/v1';moduleId=$module;moduleVersion=$version;
  managedAssembly=$product;managedVersion=$identity.Version.ToString();sqlAssembly=$sqlName;permissionSet='SAFE';
  binarySha256=$binaryPin[0].sha256.ToLowerInvariant();binarySha512=(Get-FileHash -LiteralPath $binary -Algorithm SHA512).Hash.ToLowerInvariant();
  buildProfile='net48;csharp7.3;Release;AnyCPU;checked;deterministic;warnaserror;no-debug;no-generated-framework-attribute';
  qualificationScope='OFFLINE_SOURCE_FRAMEWORK_AND_OWN_IL_AND_CANONICAL_PROJECT_BYTE_EQUALITY';
  nativeQualification='NOT_EXECUTED';frameworkTransitiveSafe='NOT_CERTIFIED'}
 if($product-cne'Toolbelt.JsonCore'){$fields['coreArtifactId']=$coreId}
 if($product-ceq'Toolbelt.JsonConstructors'){
  # Unveränderte fachliche1.2-Verträge; historische Artifactzeile bleibt intakt.
  foreach($name in @('wireVersion','profile1Entries','profile1Bytes','profile1StateBytes','profile2Entries','profile2Bytes','profile2StateBytes','agfEntryDepth','agfFinalDepth','bridgePolicy','bridgeBinding','bridgeInput','bridgeOutput','arrayBinding','objectBinding','udaContract','legacySlots')){
   $fields[$name]=[string]$legacy.artifacts[0].Fields.$name
  }
 }elseif($product-ceq'Toolbelt.JsonSchema'){
  $fields['profile']='toolbelt-2020-12-v1'
  $fields['bridgeBinding']='FT_ValidateJsonSchemaInternal|FT|Toolbelt.JsonSchema.JsonSchemaBridge|Validate|FillRow'
  $fields['bridgeInput']='Json:nvarchar(max),Schema:nvarchar(max),Profile:nvarchar(32),MaxDocumentBytes:bigint,MaxSchemaBytes:bigint,MaxDepth:int,MaxEvaluationSteps:bigint,MaxErrors:int'
  $fields['bridgeOutput']='RowKind:nvarchar(8),ErrorOrdinal:int,Status:nvarchar(24),Profile:nvarchar(32),IsValid:bit,DocumentPointer:nvarchar(max),SchemaPointer:nvarchar(max),Keyword:nvarchar(128),ErrorCode:nvarchar(32),ErrorsTruncated:bit;physical-nullable'
 }else{$fields['sqlBindings']='NONE';$fields['consumerPolicy']='same_database;known-exact-bytes;no-consumer-replacement-or-removal'}
 $projectPath=Join-Path $repoRoot ('Modules/'+$module+'/Clr/'+$product+'.csproj')
 $fields['projectSha256']=(Get-FileHash -LiteralPath $projectPath -Algorithm SHA256).Hash.ToLowerInvariant()
 [xml]$xml=[IO.File]::ReadAllText($projectPath)
 $ns=[Xml.XmlNamespaceManager]::new($xml.NameTable);$ns.AddNamespace('p','http://schemas.microsoft.com/developer/msbuild/2003')
 foreach($compile in $xml.SelectNodes('//p:Compile',$ns)){
  $relative=$compile.Include.Replace('\','/')
  $source=Join-Path (Split-Path -Parent $projectPath) $relative
  $fields['source/'+$relative]=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
 }
 $row=Artifact $fields;$artifacts+=@($row)
 if($product-ceq'Toolbelt.JsonCore'){$coreId=$row.ArtifactId}
}
$registry=[ordered]@{status='OFFLINE_QUALIFIED_KNOWN_ARTIFACTS';framing='toolbelt.json.shared-closure/v1';framePrefix='TBXJSONCLOSURE1';
 evidence='Modules/toolbelt.json.schema/Tests/Framework/README.md';artifacts=$artifacts;
 historicalConstructorRegistry='Modules/toolbelt.json.constructors/Documentation/KNOWN_CLR_ARTIFACTS.json'}
$output=[IO.Path]::GetFullPath($OutputPath)
if(Test-Path -LiteralPath $output){throw 'JSON_CLOSURE_OUTPUT_EXISTS'}
$parent=Split-Path -Parent $output
if(-not(Test-Path -LiteralPath $parent)){[void][IO.Directory]::CreateDirectory($parent)}
$stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$bytes=$utf8.GetBytes(($registry|ConvertTo-Json -Depth 8));$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash-cne$pin.sha256){throw 'JSON_CLOSURE_POSTPIN'}}
'PASS OFFLINE_KNOWN_JSON_CLOSURE_ONLY'
