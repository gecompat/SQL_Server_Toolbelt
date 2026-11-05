# Current build only; the original recovery fixture and its evidence stay immutable.
$definition=(Get-Command Assert-RecoveryArtifacts -CommandType Function).Definition
$begin=$definition.IndexOf(" `$recordPath=",[StringComparison]::Ordinal)
$end=$definition.IndexOf(" `$pins=",[StringComparison]::Ordinal)
if($begin -lt 0 -or $end -le $begin){throw 'SSIS_CURRENT_SSMS_ARTIFACT_ANCHOR'}
$current=@'
 $recordPath=Join-Path $repoRoot ($prefix+'Tests/Qualification/Current.Build.20261104.json')
 $nativePath=Join-Path $repoRoot ($prefix+'Tests/Qualification/Current.Build.Native.20261104.json')
 if((Get-ClientHash $recordPath)-cne '8E17CA520F50E8385E744CF4B6464B97263B1AF17AF4C6B074DC36556F22D60C' -or
    (Get-ClientHash $nativePath)-cne 'B3DDA4B449BD53ACBC6421FBE7449B928DA32ADBFBCFDB772E018EF1A460792A'){throw 'SSIS_CURRENT_SSMS_APPROVAL_RECORD'}
 $record=Get-Content $recordPath -Raw|ConvertFrom-Json -DateKind String
 $native=Get-Content $nativePath -Raw|ConvertFrom-Json -DateKind String
 if($record.result -cne 'PASS' -or $native.result -cne 'PASS' -or $record.api_parameters -ne 40){throw 'SSIS_CURRENT_SSMS_BUILD_NOT_QUALIFIED'}
 foreach($pair in @(@('Toolbelt.Tsql.SsisDebug.dll',$record.qualified_assembly_sha256),
                    @('Deploy.WithAssembly.sql',$native.qualified_deploy_sql_sha256),
                    @('Uninstall.Expanded.sql',$native.qualified_uninstall_sql_sha256),
                    @('Toolbelt.Tsql.SsisDebug.trust-manifest.json',$native.qualified_trust_manifest_sha256))){
  if((Get-ClientHash (Join-Path $Plan.ssis $pair[0])).ToLowerInvariant() -cne ([string]$pair[1]).ToLowerInvariant()){throw 'SSIS_CURRENT_SSMS_ARTIFACT_CHANGED'}
 }
 foreach($entry in $record.source_sha256.psobject.Properties){
  $path=[IO.Path]::GetFullPath((Join-Path $repoRoot $entry.Name))
  if(-not $path.StartsWith($repoRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
     (Get-ClientHash $path).ToLowerInvariant() -cne ([string]$entry.Value).ToLowerInvariant()){throw 'SSIS_CURRENT_SSMS_PRODUCT_SOURCE_CHANGED'}
 }
 # Preserve the original parser provenance and unchanged ResultTable helper pins.
 $recordPath=Join-Path $repoRoot ($prefix+'Tests/Qualification/Current.Functional.20261031.json')
 if((Get-ClientHash $recordPath)-cne 'BB3BB417B4E571CE2D201A10988FA4015080586EE19E8C85CB87FA259E61E8B5'){throw 'SSIS_CURRENT_SSMS_ORIGINAL_CORE_RECORD'}
 $record=Get-Content $recordPath -Raw|ConvertFrom-Json -DateKind String
'@
$definition=$definition.Substring(0,$begin)+$current+"`n"+$definition.Substring($end)
. ([scriptblock]::Create('function Assert-RecoveryArtifacts {'+$definition+'}'))
