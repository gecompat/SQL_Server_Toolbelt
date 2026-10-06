#requires -Version 7.0
Set-StrictMode -Version Latest
# Gemeinsame Offline-Invarianten: exakte Compileliste und unveränderte Closureframes.
# Keine SQL-, Trust-, Download- oder Registrymutation.
function Get-SchemaPatchHash([string]$Path,[string]$Algorithm='SHA256') {
 return (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash.ToLowerInvariant()
}
function Get-SchemaPatchSources([string]$ProjectPath) {
 $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
 $reader=[Xml.XmlReader]::Create($ProjectPath,$settings)
 try{$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
 $ns=[Xml.XmlNamespaceManager]::new($xml.NameTable);$ns.AddNamespace('p','http://schemas.microsoft.com/developer/msbuild/2003')
 $root=[IO.Path]::GetFullPath((Split-Path -Parent $ProjectPath))+[IO.Path]::DirectorySeparatorChar
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $sources=@($xml.SelectNodes('//p:Compile',$ns)|ForEach-Object{
  if($_.HasAttribute('Condition') -or $_.ParentNode.HasAttribute('Condition')){throw 'SCHEMA_PATCH_CONDITIONAL_COMPILE'}
  $relative=$_.GetAttribute('Include').Replace('\','/')
  $path=[IO.Path]::GetFullPath((Join-Path $root $relative))
  if(-not $path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or
   -not(Test-Path -LiteralPath $path -PathType Leaf) -or -not $seen.Add($path)){throw 'SCHEMA_PATCH_COMPILE_SET'}
  [ordered]@{relative=$relative;path=$path;sha256=(Get-SchemaPatchHash $path)}
 })
 if($sources.Count -eq 0){throw 'SCHEMA_PATCH_COMPILE_SET'}
 return $sources
}
function Get-SchemaPatchArtifactId($Fields,[object[]]$FieldOrder) {
 if($Fields.Count -ne $FieldOrder.Count){throw 'SCHEMA_PATCH_FRAME_FIELDS'}
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 $utf8=[Text.UTF8Encoding]::new($false,$true)
 $stream=[IO.MemoryStream]::new();$writer=[IO.BinaryWriter]::new($stream,$utf8,$true)
 try{
  $writer.Write([Text.Encoding]::ASCII.GetBytes('TBXJSONCLOSURE1'));$writer.Write([uint32]$FieldOrder.Count)
  foreach($key in $FieldOrder){
   if($key -isnot [string] -or -not $seen.Add($key) -or -not $Fields.Contains($key) -or $Fields[$key] -isnot [string]){throw 'SCHEMA_PATCH_FRAME_FIELDS'}
   foreach($value in @($key,$Fields[$key])){$bytes=$utf8.GetBytes($value);$writer.Write([uint32]$bytes.Length);$writer.Write($bytes)}
  }
  $writer.Flush();$hash=[Security.Cryptography.SHA256]::Create()
  try{return [BitConverter]::ToString($hash.ComputeHash($stream.ToArray())).Replace('-','').ToLowerInvariant()}finally{$hash.Dispose()}
 }finally{$writer.Dispose();$stream.Dispose()}
}
function Read-SchemaPatchClosure([string]$Path) {
 $closure=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json -AsHashtable
 if($closure.framing -cne 'toolbelt.json.shared-closure/v1' -or $closure.framePrefix -cne 'TBXJSONCLOSURE1' -or
  $closure.status -cne 'OFFLINE_QUALIFIED_KNOWN_ARTIFACTS' -or @($closure.artifacts).Count -ne 3){throw 'SCHEMA_PATCH_BASELINE'}
 $expected=@('toolbelt.json.core','toolbelt.json.constructors','toolbelt.json.schema')
 for($i=0;$i -lt 3;$i++){
  $row=$closure.artifacts[$i]
  if($row.Fields.moduleId -cne $expected[$i] -or $row.ArtifactId -cne (Get-SchemaPatchArtifactId $row.Fields @($row.fieldOrder))){throw 'SCHEMA_PATCH_BASELINE_FRAME'}
 }
 if($closure.artifacts[0].Fields.moduleVersion -cne '1.0.0' -or $closure.artifacts[0].Fields.managedVersion -cne '1.0.0.0' -or
  $closure.artifacts[1].Fields.moduleVersion -cne '1.3.0' -or $closure.artifacts[2].Fields.moduleVersion -cne '1.0.0' -or
  $closure.artifacts[2].Fields.managedVersion -cne '1.0.0.0' -or
  $closure.artifacts[1].Fields.coreArtifactId -cne $closure.artifacts[0].ArtifactId -or
  $closure.artifacts[2].Fields.coreArtifactId -cne $closure.artifacts[0].ArtifactId){throw 'SCHEMA_PATCH_BASELINE_VERSION'}
 return $closure
}
function Assert-SchemaPatchPrivateOutput([string]$RepoRoot,[string]$OutputPath) {
 $output=[IO.Path]::GetFullPath($OutputPath)
 $prefix=[IO.Path]::GetFullPath((Join-Path $RepoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
 if(-not $output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'SCHEMA_PATCH_PRIVATE_OUTPUT'}
 & git -C $RepoRoot check-ignore --quiet -- $output
 if($LASTEXITCODE -ne 0){throw 'SCHEMA_PATCH_OUTPUT_NOT_IGNORED'}
 return $output
}
function Assert-SchemaPatchPins([object[]]$Pins) {
 foreach($pin in $Pins){if((Get-SchemaPatchHash $pin.path) -cne $pin.sha256){throw 'SCHEMA_PATCH_INPUT_DRIFT'}}
}
function Write-SchemaPatchJson([string]$Path,$Value) {
 $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$bytes=[Text.UTF8Encoding]::new($false,$true).GetBytes((ConvertTo-Json -InputObject $Value -Depth 16));$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}
 finally{$stream.Dispose()}
}
