[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent $PSScriptRoot
# Absichtlich kein impliziter Build und keine Installation: neue Binarybytes
# benötigen erst unabhängige Qualifikation und eine bekannte modullokale Zeile.
$registryPath=Join-Path $moduleRoot 'Documentation/KNOWN_CLR_ARTIFACTS.json'
$registry=Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8|ConvertFrom-Json
if($registry.status -cne 'OFFLINE_QUALIFIED_KNOWN_ARTIFACT' -or @($registry.artifacts).Count -ne 1 -or @($registry.fieldOrder).Count -ne 34){throw 'JSON_ARTIFACT_REGISTRY'}
$row=$registry.artifacts[0]
$utf8=New-Object Text.UTF8Encoding($false,$true)
$frame=New-Object IO.MemoryStream
$writer=New-Object IO.BinaryWriter($frame,$utf8,$true)
try {
 $writer.Write([Text.Encoding]::ASCII.GetBytes('TBXJSONART1'))
 $writer.Write([uint32]$registry.fieldOrder.Count)
 $seen=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
 if(@($row.Fields.psobject.Properties).Count -ne 34){throw 'JSON_ARTIFACT_FIELDS'}
 foreach($name in $registry.fieldOrder){
  if($name -isnot [string] -or -not $seen.Add($name)){throw 'JSON_ARTIFACT_ORDER'}
  $property=$row.Fields.psobject.Properties[$name]
  if($null -eq $property -or $property.Value -isnot [string]){throw 'JSON_ARTIFACT_VALUE'}
  foreach($text in @($name,$property.Value)){$bytes=$utf8.GetBytes($text);$writer.Write([uint32]$bytes.Length);$writer.Write($bytes)}
 }
 $writer.Flush()
 $sha=[Security.Cryptography.SHA256]::Create()
 try{$id=[BitConverter]::ToString($sha.ComputeHash($frame.ToArray())).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 if($row.ArtifactId -cne $id){throw 'JSON_ARTIFACT_FRAME'}
}finally{$writer.Dispose();$frame.Dispose()}
$sourcePaths=@('Clr/Toolbelt.JsonConstructors.csproj','Deployment/Deploy.sql','Deployment/Uninstall.sql',
 'Deployment/ClrPreflight.sql','Deployment/KnownArtifact.sql','Source/JsonEntryEvaluate.sql','Source/JsonAggregates.sql',
 'Source/USP_JsonConstructInternal.sql','Source/USP_JsonArray.sql','Source/USP_JsonObject.sql',
 'Source/USP_JsonArraysByGroup.sql','Source/USP_JsonObjectsByGroup.sql','Documentation/KNOWN_CLR_ARTIFACTS.json',
 'Scripts/New-ClrReleaseArtifacts.ps1')
foreach($property in $row.Fields.psobject.Properties){
 if($property.Name.StartsWith('source/',[StringComparison]::Ordinal)){
  $relative='Clr/'+$property.Name.Substring(7)
  if((Get-FileHash -LiteralPath (Join-Path $moduleRoot $relative) -Algorithm SHA256).Hash.ToLowerInvariant() -cne $property.Value){throw 'JSON_ARTIFACT_SOURCE'}
  $sourcePaths+= $relative
 }
}
function Get-SourcePins {
 foreach($relative in $sourcePaths){[pscustomobject]@{path=$relative;sha256=(Get-FileHash -LiteralPath (Join-Path $moduleRoot $relative) -Algorithm SHA256).Hash}}
}
$pins=@(Get-SourcePins);$before=ConvertTo-Json -InputObject $pins -Compress
$assemblyFull=[IO.Path]::GetFullPath($AssemblyPath)
$binary=[IO.File]::ReadAllBytes($assemblyFull)
$sha256=[Security.Cryptography.SHA256]::Create();$sha512=[Security.Cryptography.SHA512]::Create()
try{$hash256=[BitConverter]::ToString($sha256.ComputeHash($binary)).Replace('-','').ToLowerInvariant();$hash512=[BitConverter]::ToString($sha512.ComputeHash($binary)).Replace('-','').ToLowerInvariant()}
finally{$sha256.Dispose();$sha512.Dispose()}
if($hash256 -cne $row.Fields.binarySha256 -or $hash512 -cne $row.Fields.binarySha512){throw 'JSON_ARTIFACT_BINARY'}
$identity=[Reflection.AssemblyName]::GetAssemblyName($assemblyFull)
if($identity.Name -cne $row.Fields.managedAssembly -or $identity.Version.ToString() -cne $row.Fields.managedVersion){throw 'JSON_ARTIFACT_IDENTITY'}
if((Get-FileHash -LiteralPath $assemblyFull -Algorithm SHA256).Hash.ToLowerInvariant() -cne $hash256){throw 'JSON_ARTIFACT_BINARY_DRIFT'}
function Expand-Sql([string]$relative,[int]$depth=0){
 if($depth -gt 4 -or $relative -notin $sourcePaths){throw 'JSON_ARTIFACT_INCLUDE'}
 $path=Join-Path $moduleRoot $relative
 $text=[IO.File]::ReadAllText($path,$utf8)
 $parts=New-Object Text.StringBuilder
 foreach($line in [regex]::Split($text,'\r?\n')){
  if($line -match '^:r (.+)$'){
   $included=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $Matches[1]))
   $prefix=[IO.Path]::GetFullPath($moduleRoot)+[IO.Path]::DirectorySeparatorChar
   if(-not $included.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_ARTIFACT_INCLUDE'}
   $child=$included.Substring($prefix.Length).Replace('\','/')
   [void]$parts.Append((Expand-Sql $child ($depth+1)))
  }else{[void]$parts.Append($line);[void]$parts.Append("`r`n")}
 }
 return $parts.ToString()
}
$deploy=Expand-Sql 'Deployment/Deploy.sql'
if([regex]::Matches($deploy,[regex]::Escape('$(AssemblyBits)')).Count -ne 1){throw 'JSON_ARTIFACT_PLACEHOLDER'}
$deploy=$deploy.Replace('$(AssemblyBits)','0x'+[BitConverter]::ToString($binary).Replace('-',''))
$uninstall=Expand-Sql 'Deployment/Uninstall.sql'
if((ConvertTo-Json -InputObject @(Get-SourcePins) -Compress) -cne $before){throw 'JSON_ARTIFACT_SOURCE_DRIFT'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'JSON_ARTIFACT_OUTPUT_EXISTS'}
[void][IO.Directory]::CreateDirectory($output)
function Write-New([string]$name,[byte[]]$bytes){
 $stream=[IO.File]::Open((Join-Path $output $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
}
Write-New 'Toolbelt.JsonConstructors.dll' $binary
Write-New 'Deploy.WithAssembly.sql' ($utf8.GetBytes($deploy))
Write-New 'Uninstall.Expanded.sql' ($utf8.GetBytes($uninstall))
$manifest=[ordered]@{moduleId='toolbelt.json.constructors';moduleVersion='1.2.0';permissionSet='SAFE';
 artifactId=$id;sha256=$hash256;sha512=$hash512;managedAssembly=$identity.Name;managedVersion=$identity.Version.ToString();
 assemblyFileName='Toolbelt.JsonConstructors.dll';sourceFingerprints=$pins;scope='OFFLINE_KNOWN_ARTIFACT_PACKAGING_ONLY'}
Write-New 'Toolbelt.JsonConstructors.trust-manifest.json' ($utf8.GetBytes(($manifest|ConvertTo-Json -Depth 6)))
if((ConvertTo-Json -InputObject @(Get-SourcePins) -Compress) -cne $before -or
 (Get-FileHash -LiteralPath $assemblyFull -Algorithm SHA256).Hash.ToLowerInvariant() -cne $hash256){throw 'JSON_ARTIFACT_FINAL_DRIFT'}
'PASS JSON_KNOWN_ARTIFACT_PACKAGING_ONLY'
