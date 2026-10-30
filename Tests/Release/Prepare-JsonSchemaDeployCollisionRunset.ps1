[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$QualificationDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$api=Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($api,[ref]$null,[ref]$errors)
if($errors.Count){throw 'JSON_DEPLOY_COLLISION_HELPER_PARSE'}
$imports=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($imports.Count-ne1){throw 'JSON_DEPLOY_COLLISION_HELPER_IMPORTER'}
. ([scriptblock]::Create($imports[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @('Assert-ReleasePrivatePath','Assert-ReleasePin')){. $block}
$output=Assert-ReleasePrivatePath $OutputDirectory
$qualification=Assert-ReleasePrivatePath $QualificationDirectory
if(Test-Path -LiteralPath $output){throw 'JSON_DEPLOY_COLLISION_OUTPUT_EXISTS'}
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaDeployCollisionLab.ps1'
$offline=Join-Path $PSScriptRoot 'Test-JsonSchemaDeployCollisionOffline.ps1'
$basePreparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaCallerTransactionRunset.ps1'
$offlineResult=& $offline
if(($offlineResult -join "`n") -notmatch 'PASS JSON_SCHEMA_DEPLOY_COLLISION offline'){throw 'JSON_DEPLOY_COLLISION_OFFLINE_NOT_PASS'}
$parent=Split-Path -Parent $output
if(-not(Test-Path -LiteralPath $parent -PathType Container)){throw 'JSON_DEPLOY_COLLISION_OUTPUT_PARENT_REQUIRED'}
[void][IO.Directory]::CreateDirectory($output)
$baseDirectory=Join-Path $output 'base'
& $basePreparer -QualificationDirectory $qualification -OutputDirectory $baseDirectory | Out-Null
$basePath=Join-Path $baseDirectory 'runset.json'
$base=Get-Content -LiteralPath $basePath -Raw -Encoding UTF8|ConvertFrom-Json
if($base.schema_version-cne'json-schema-caller-transaction-probe/v1' -or
   $base.target.platform-cne'windows' -or $base.target.version-cne'2025' -or $base.target.patch-cne'CU8' -or
   ($base.target.compatibility_level-isnot[int]-and$base.target.compatibility_level-isnot[long]) -or $base.target.compatibility_level-ne170 -or
   $base.target.test_purpose-cne'Functional' -or $base.scope.deployment_mode-cne'local' -or
   @($base.artifacts).Count-ne2 -or @($base.baseline.modules).Count-ne2 -or
   $base.baseline.modules[0]-cne'toolbelt.core.result-table' -or $base.baseline.modules[1]-cne'toolbelt.json.core' -or
   $base.schema_deploy.module-cne'toolbelt.json.schema' -or $base.schema_uninstall.module-cne'toolbelt.json.schema') {throw 'JSON_DEPLOY_COLLISION_BASE_RUNSET_INVALID'}
foreach($pin in $base.pins){Assert-ReleasePin $pin.path $pin.sha256}
Assert-ReleasePin $basePath (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash
$pins=[Collections.Generic.List[object]]::new()
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($pin in $base.pins){$full=[IO.Path]::GetFullPath([string]$pin.path);if($seen.Add($full)){$pins.Add([ordered]@{path=$full;sha256=[string]$pin.sha256})}}
foreach($path in @($basePath,$PSCommandPath,$driver,$offline)){
    $full=[IO.Path]::GetFullPath($path)
    if($seen.Add($full)){$pins.Add([ordered]@{path=$full;sha256=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToUpperInvariant()})}
}
$cases=@(
 [ordered]@{ordinal=0;kind='reserved_temp';object_name='#tbx_JsonSchema_DeployState';expected_error=55633;expected_state=1;expected_message='JSON Schema lifecycle: reservierter Callerzustand belegt.'},
 [ordered]@{ordinal=1;kind='public_slot';object_name='USP_ValidateJsonSchema';fixture_type='U';fixture_value=701;expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'},
 [ordered]@{ordinal=2;kind='internal_slot';object_name='FT_ValidateJsonSchemaInternal';fixture_type='U';fixture_value=702;expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'},
 [ordered]@{ordinal=3;kind='orphan_mode';property_name='Toolbelt.Module.toolbelt.json.schema.DeploymentMode';property_value='local';expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'}
)
$runset=[ordered]@{
 schema_version='json-schema-deploy-collision-probe/v1'
 operation='json-schema-deploy-collision'
 base_runset=[ordered]@{path=[IO.Path]::GetFullPath($basePath);sha256=(Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()}
 target=$base.target
 lab=$base.lab
 qualification=$base.qualification
 artifacts=$base.artifacts
 baseline=$base.baseline
 schema_deploy=$base.schema_deploy
 pins=$pins.ToArray()
 scope=[ordered]@{
   deployment_mode='local';namespace_owner='same_as_core';case_count=4;cases=$cases
   positive_control='one same-input Deploy after all owned fixtures are removed'
 }
}
$runsetPath=Join-Path $output 'runset.json'
$bytes=[Text.UTF8Encoding]::new($false,$true).GetBytes(($runset|ConvertTo-Json -Depth 16))
$stream=[IO.File]::Open($runsetPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
Write-Output 'PREPARED JSON_SCHEMA_DEPLOY_COLLISION_PRIVATE_RUNSET'
