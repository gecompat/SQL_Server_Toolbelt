[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('toolbelt.json.core','toolbelt.json.constructors','toolbelt.json.schema')][string]$ModuleId,
 [Parameter(Mandatory)][string]$AssemblyPath,[string]$CoreAssemblyPath,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Expand-JsonClosureSql.ps1')
$registryPath=Join-Path $script:JsonClosureRoot 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
$registry=Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8|ConvertFrom-Json
if($registry.status -cne 'OFFLINE_QUALIFIED_KNOWN_ARTIFACTS' -or $registry.framing -cne 'toolbelt.json.shared-closure/v1' -or
 $registry.framePrefix -cne 'TBXJSONCLOSURE1' -or @($registry.artifacts).Count -ne 3){throw 'JSON_CLOSURE_REGISTRY'}
$utf8=[Text.UTF8Encoding]::new($false,$true)
$pins=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
function Pin-File([string]$Path){
 $full=[IO.Path]::GetFullPath($Path)
 $hash=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
 if($pins.ContainsKey($full) -and $pins[$full] -cne $hash){throw 'JSON_CLOSURE_SOURCE_DRIFT'}
 $pins[$full]=$hash
}
Pin-File $registryPath
Pin-File $PSCommandPath
Pin-File (Join-Path $PSScriptRoot 'Expand-JsonClosureSql.ps1')
$rows=@{}
foreach($row in $registry.artifacts){
 $fields=$row.Fields;$module=$fields.moduleId
 if($module -cnotin @('toolbelt.json.core','toolbelt.json.constructors','toolbelt.json.schema') -or $rows.ContainsKey($module)){
  throw 'JSON_CLOSURE_MODULE'
 }
 $expectedVersion=if($module -ceq 'toolbelt.json.constructors'){'1.3.0'}else{'1.0.0'}
 if($fields.registrySchema -cne $registry.framing -or $fields.moduleVersion -cne $expectedVersion -or $fields.permissionSet -cne 'SAFE'){
  throw 'JSON_CLOSURE_FIELDS'
 }
 $frame=[IO.MemoryStream]::new();$writer=[IO.BinaryWriter]::new($frame,$utf8,$true)
 try{
  $writer.Write([Text.Encoding]::ASCII.GetBytes($registry.framePrefix));$writer.Write([uint32]$row.fieldOrder.Count)
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  if(@($fields.psobject.Properties).Count -ne @($row.fieldOrder).Count){throw 'JSON_CLOSURE_FRAME_FIELDS'}
  foreach($name in $row.fieldOrder){
   $property=$fields.psobject.Properties[$name]
   if($name -isnot [string] -or -not $seen.Add($name) -or $null -eq $property -or $property.Value -isnot [string]){
    throw 'JSON_CLOSURE_FRAME_VALUE'
   }
   foreach($value in @($name,$property.Value)){$bytes=$utf8.GetBytes($value);$writer.Write([uint32]$bytes.Length);$writer.Write($bytes)}
  }
  $writer.Flush();$sha=[Security.Cryptography.SHA256]::Create()
  try{$id=[BitConverter]::ToString($sha.ComputeHash($frame.ToArray())).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
  if($id -cne $row.ArtifactId){throw 'JSON_CLOSURE_FRAME_ID'}
 }finally{$writer.Dispose();$frame.Dispose()}
 $moduleRoot=Join-Path $script:JsonClosureRoot ('Modules/'+$module)
 $project=Join-Path $moduleRoot ('Clr/'+$fields.managedAssembly+'.csproj')
 Pin-File $project
 if($pins[[IO.Path]::GetFullPath($project)].ToLowerInvariant() -cne $fields.projectSha256){throw 'JSON_CLOSURE_PROJECT'}
 $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit
 $reader=[Xml.XmlReader]::Create($project,$settings);$xml=[Xml.XmlDocument]::new()
 try{$xml.Load($reader)}finally{$reader.Dispose()}
 $compiled=@($xml.SelectNodes('//*[local-name()="Compile"]')|ForEach-Object{$_.GetAttribute('Include').Replace('\','/')})
 $sourceNames=@($fields.psobject.Properties|Where-Object{$_.Name.StartsWith('source/',[StringComparison]::Ordinal)}|ForEach-Object{$_.Name.Substring(7)})
 if(@($compiled).Count -ne @($sourceNames).Count){throw 'JSON_CLOSURE_SOURCE_SET'}
 foreach($name in $sourceNames){
  if($name -cnotin $compiled -or $name.Contains('..') -or [IO.Path]::IsPathRooted($name)){throw 'JSON_CLOSURE_SOURCE_SET'}
  $source=Join-Path $moduleRoot ('Clr/'+$name);Pin-File $source
  if($pins[[IO.Path]::GetFullPath($source)].ToLowerInvariant() -cne $fields.psobject.Properties['source/'+$name].Value){throw 'JSON_CLOSURE_SOURCE'}
 }
 $rows[$module]=$row
}
foreach($row in @($rows['toolbelt.json.constructors'],$rows['toolbelt.json.schema'])){
 if($row.Fields.coreArtifactId -cne $rows['toolbelt.json.core'].ArtifactId){throw 'JSON_CLOSURE_DEPENDENCY'}
}
function Read-KnownBinary([string]$Path,$Row){
 $full=[IO.Path]::GetFullPath($Path);Pin-File $full
 $bytes=[IO.File]::ReadAllBytes($full);$sha=[Security.Cryptography.SHA512]::Create()
 try{$hash=[BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 $identity=[Reflection.AssemblyName]::GetAssemblyName($full)
 if($pins[$full].ToLowerInvariant() -cne $Row.Fields.binarySha256 -or $hash -cne $Row.Fields.binarySha512 -or
  $identity.Name -cne $Row.Fields.managedAssembly -or $identity.Version.ToString() -cne $Row.Fields.managedVersion){throw 'JSON_CLOSURE_BINARY'}
 return ,$bytes
}
$selected=$rows[$ModuleId];$binary=Read-KnownBinary $AssemblyPath $selected
if($ModuleId -cne 'toolbelt.json.core'){
 if([string]::IsNullOrEmpty($CoreAssemblyPath)){throw 'JSON_CLOSURE_CORE_REQUIRED'}
 [void](Read-KnownBinary $CoreAssemblyPath $rows['toolbelt.json.core'])
}
foreach($path in $script:JsonClosureSqlPaths){Pin-File (Join-Path $script:JsonClosureRoot ('Modules/'+$path))}
$deploy=Expand-JsonClosureSql -RelativePath ($ModuleId+'/Deployment/Deploy.sql')
$uninstall=Expand-JsonClosureSql -RelativePath ($ModuleId+'/Deployment/Uninstall.sql')
if([regex]::Matches($deploy,[regex]::Escape('$(AssemblyBits)')).Count -ne 1){throw 'JSON_CLOSURE_PLACEHOLDER'}
$deploy=$deploy.Replace('$(AssemblyBits)','0x'+[BitConverter]::ToString($binary).Replace('-',''))
function Assert-Pins {foreach($entry in $pins.GetEnumerator()){if((Get-FileHash -LiteralPath $entry.Key -Algorithm SHA256).Hash -cne $entry.Value){throw 'JSON_CLOSURE_FINAL_DRIFT'}}}
Assert-Pins
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'JSON_CLOSURE_OUTPUT_EXISTS'}
[void][IO.Directory]::CreateDirectory($output)
function Write-New([string]$Name,[byte[]]$Bytes){
 $stream=[IO.File]::Open((Join-Path $output $Name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($Bytes,0,$Bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
}
Write-New ($selected.Fields.managedAssembly+'.dll') $binary
Write-New 'Deploy.WithAssembly.sql' ($utf8.GetBytes($deploy))
Write-New 'Uninstall.Expanded.sql' ($utf8.GetBytes($uninstall))
$manifest=[ordered]@{moduleId=$ModuleId;moduleVersion=$selected.Fields.moduleVersion;artifactId=$selected.ArtifactId;
 sha256=$selected.Fields.binarySha256;sha512=$selected.Fields.binarySha512;permissionSet='SAFE';
 coreArtifactId=if($ModuleId -ceq 'toolbelt.json.core'){$null}else{$rows['toolbelt.json.core'].ArtifactId};
 scope='OFFLINE_KNOWN_CLOSURE_PACKAGING_ONLY';trustAuthorization='NOT_GRANTED';nativeQualification='NOT_EXECUTED'}
Write-New ($selected.Fields.managedAssembly+'.trust-manifest.json') ($utf8.GetBytes(($manifest|ConvertTo-Json -Depth 4)))
Assert-Pins
'PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY'
