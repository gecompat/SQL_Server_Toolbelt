Set-StrictMode -Version Latest
# Geschlossene Source-Liste; Includes dürfen nur diese produktiven Dateien lesen.
$script:JsonClosureRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$script:JsonClosureSqlPaths=@(
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
function Expand-JsonClosureSql {
 param([Parameter(Mandatory)][string]$RelativePath,[int]$Depth=0)
 if($Depth -gt 8 -or $RelativePath -cnotin $script:JsonClosureSqlPaths){throw 'JSON_CLOSURE_INCLUDE'}
 $modulesRoot=Join-Path $script:JsonClosureRoot 'Modules'
 $path=[IO.Path]::GetFullPath((Join-Path $modulesRoot $RelativePath))
 $prefix=[IO.Path]::GetFullPath($modulesRoot)+[IO.Path]::DirectorySeparatorChar
 if(-not $path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_CLOSURE_INCLUDE'}
 $text=[IO.File]::ReadAllText($path,[Text.UTF8Encoding]::new($false,$true))
 $output=[Text.StringBuilder]::new()
 foreach($line in [regex]::Split($text,'\r?\n')){
  if($line -match '^:r (.+)$'){
   $child=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $Matches[1]))
   if(-not $child.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_CLOSURE_INCLUDE'}
   $relative=$child.Substring($prefix.Length).Replace('\','/')
   [void]$output.Append((Expand-JsonClosureSql -RelativePath $relative -Depth ($Depth+1)))
  }elseif($line -match '^:r\b'){throw 'JSON_CLOSURE_INCLUDE'}
  else{[void]$output.AppendLine($line)}
 }
 return $output.ToString()
}
