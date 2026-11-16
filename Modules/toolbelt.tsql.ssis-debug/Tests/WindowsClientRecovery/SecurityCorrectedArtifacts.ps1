# Current build only; the original recovery fixture and its evidence stay immutable.
$definition=(Get-Command Assert-RecoveryArtifacts -CommandType Function).Definition
$begin=$definition.IndexOf(" `$recordPath=",[StringComparison]::Ordinal)
$end=$definition.IndexOf(" `$pins=",[StringComparison]::Ordinal)
if($begin -lt 0 -or $end -le $begin){throw 'SSIS_CURRENT_SSMS_ARTIFACT_ANCHOR'}
$current=@'
 $copyPath=Join-Path $repoRoot ($prefix+'Tests/Qualification/CopyColumn.Build.20261116.json')
 $deliveryPath=Join-Path $repoRoot ($prefix+'Tests/Qualification/CopyColumn.Package.20261116.json')
 $copy=Get-Content -LiteralPath $copyPath -Raw|ConvertFrom-Json -DateKind String
 $delivery=Get-Content -LiteralPath $deliveryPath -Raw|ConvertFrom-Json -DateKind String
 if($copy.result -cne 'PASS_FOR_BOUND_BUILD' -or $delivery.result -cne 'BOUND_INPUTS_ONLY' -or
    $delivery.package.qualified_source_record_sha256 -cne (Get-ClientHash $copyPath).ToLowerInvariant() -or
    $delivery.package.provider_sha512 -cne $copy.qualified_assembly_sha512.ToLowerInvariant()){throw 'SSIS_COPY_SSMS_APPROVAL_RECORD'}
 foreach($record in @($copy,$delivery)){
  foreach($entry in $record.source_sha256.psobject.Properties){
   $path=[IO.Path]::GetFullPath((Join-Path $repoRoot $entry.Name))
   if(-not $path.StartsWith($repoRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
      (Get-ClientHash $path).ToLowerInvariant() -cne [string]$entry.Value){throw 'SSIS_COPY_SSMS_PRODUCT_SOURCE_CHANGED'}
  }
 }
 $archivePath=Join-Path $repoRoot $delivery.package.path
 if((Get-ClientHash $archivePath).ToLowerInvariant() -cne $delivery.package.sha256){throw 'SSIS_COPY_SSMS_ARCHIVE_CHANGED'}
 $zip=[IO.Compression.ZipFile]::OpenRead($archivePath)
 try{
  foreach($file in @('Toolbelt.Tsql.SsisDebug.dll','Deploy.WithAssembly.sql','Uninstall.Expanded.sql','Toolbelt.Tsql.SsisDebug.trust-manifest.json')){
   $e=$zip.GetEntry('SSIS-Debug-SecurityCorrected-Install-Windows/'+$prefix+'Artifacts/'+$file)
   if(-not $e){throw 'SSIS_COPY_SSMS_ARCHIVE_ENTRY'}
   $stream=$e.Open();try{$memory=[IO.MemoryStream]::new();$stream.CopyTo($memory);$bytes=$memory.ToArray();$memory.Dispose()}finally{$stream.Dispose()}
   if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)) -cne (Get-ClientHash (Join-Path $Plan.ssis $file))){throw 'SSIS_COPY_SSMS_ARTIFACT_CHANGED'}
  }
 }finally{$zip.Dispose()}
 if((Get-ClientHash (Join-Path $Plan.ssis 'Toolbelt.Tsql.SsisDebug.dll')).ToLowerInvariant() -cne $copy.qualified_assembly_sha256){throw 'SSIS_COPY_SSMS_DLL_CHANGED'}
 # Preserve the original parser provenance and unchanged ResultTable helper pins.
 $recordPath=Join-Path $repoRoot ($prefix+'Tests/Qualification/Current.Functional.20261031.json')
 if((Get-ClientHash $recordPath)-cne 'BB3BB417B4E571CE2D201A10988FA4015080586EE19E8C85CB87FA259E61E8B5'){throw 'SSIS_CURRENT_SSMS_ORIGINAL_CORE_RECORD'}
 $record=Get-Content $recordPath -Raw|ConvertFrom-Json -DateKind String
'@
$definition=$definition.Substring(0,$begin)+$current+"`n"+$definition.Substring($end)
. ([scriptblock]::Create('function Assert-RecoveryArtifacts {'+$definition+'}'))
