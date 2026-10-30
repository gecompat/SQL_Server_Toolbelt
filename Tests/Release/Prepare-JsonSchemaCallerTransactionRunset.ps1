[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$QualificationDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$apiErrors=$null;$apiAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$apiErrors)
if($apiErrors.Count){throw 'JSON_CALLER_TX_HELPER_PARSE'}
$import=@($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($import.Count-ne1){throw 'JSON_CALLER_TX_HELPER_DISCOVERY'}
. ([scriptblock]::Create($import[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-StablePackageLab.ps1') @('Assert-ReleasePrivatePath','Assert-ReleasePin')){. $block}
$basePreparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaUninstallAppLockRunset.ps1'
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'
$offline=Join-Path $PSScriptRoot 'Test-JsonSchemaCallerTransactionOffline.ps1'
$output=Assert-ReleasePrivatePath $OutputDirectory
$qualification=Assert-ReleasePrivatePath $QualificationDirectory
if(Test-Path -LiteralPath $output){throw 'JSON_CALLER_TX_OUTPUT_EXISTS'}
$offlineResult=& $offline
if(($offlineResult -join "`n") -notmatch 'PASS JSON_SCHEMA_CALLER_TRANSACTION offline'){throw 'JSON_CALLER_TX_OFFLINE_NOT_PASS'}
$parent=Split-Path -Parent $output
if(-not(Test-Path -LiteralPath $parent -PathType Container)){throw 'JSON_CALLER_TX_OUTPUT_PARENT_REQUIRED'}
[void][IO.Directory]::CreateDirectory($output)
$baseDirectory=Join-Path $output 'base'
& $basePreparer -QualificationDirectory $qualification -OutputDirectory $baseDirectory | Out-Null
$basePath=Join-Path $baseDirectory 'runset.json'
$base=Get-Content -LiteralPath $basePath -Raw -Encoding UTF8 | ConvertFrom-Json
if($base.schema_version -cne 'json-schema-uninstall-applock-probe/v1' -or
   $base.target.platform -cne 'windows' -or $base.target.version -cne '2025' -or
   $base.target.patch -cne 'CU8' -or $base.target.compatibility_level -ne 170 -or
   $base.target.test_purpose -cne 'Functional' -or $base.scope.deployment_mode -cne 'local' -or
   $base.artifacts.Count -ne 2 -or $base.baseline.modules.Count -ne 2 -or
   $base.baseline.modules[0] -cne 'toolbelt.core.result-table' -or
   $base.baseline.modules[1] -cne 'toolbelt.json.core' -or
   $base.schema_deploy.module -cne 'toolbelt.json.schema' -or
   $base.schema_uninstall.module -cne 'toolbelt.json.schema'){
    throw 'JSON_CALLER_TX_BASE_RUNSET_INVALID'
}
foreach($pin in $base.pins){Assert-ReleasePin $pin.path $pin.sha256}
Assert-ReleasePin $basePath (Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash
$pins=[Collections.Generic.List[object]]::new()
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($pin in $base.pins){$path=[IO.Path]::GetFullPath([string]$pin.path);if($seen.Add($path)){$pins.Add([ordered]@{path=$path;sha256=[string]$pin.sha256})}}
foreach($path in @($basePath,$PSCommandPath,$driver,$offline)){
    $full=[IO.Path]::GetFullPath($path)
    if($seen.Add($full)){$pins.Add([ordered]@{path=$full;sha256=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToUpperInvariant()})}
}
$cases=@(
    [ordered]@{ordinal=0;operation='deploy';initial_schema='absent';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'},
    [ordered]@{ordinal=1;operation='uninstall';initial_schema='installed';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'}
)
$runset=[ordered]@{
    schema_version='json-schema-caller-transaction-probe/v1'
    operation='json-schema-caller-transaction'
    base_runset=[ordered]@{path=$basePath;sha256=(Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash.ToUpperInvariant()}
    target=$base.target
    lab=$base.lab
    qualification=$base.qualification
    artifacts=$base.artifacts
    baseline=$base.baseline
    schema_deploy=$base.schema_deploy
    schema_uninstall=$base.schema_uninstall
    pins=$pins.ToArray()
    scope=[ordered]@{
        deployment_mode='local';expected_error=50000;expected_state=1
        cases=$cases
        session_profile=[ordered]@{quoted_identifier=$true;xact_abort=$false;nocount=$false}
        witness=[ordered]@{table='dbo.JsonSchemaCallerTransactionWitness';baseline=100;first=200;after_savepoint=300;savepoint='CallerSavepoint'}
        positive_controls='same pinned Deploy and Uninstall succeed after full caller rollback'
    }
}
$runsetPath=Join-Path $output 'runset.json'
$bytes=[Text.UTF8Encoding]::new($false,$true).GetBytes(($runset|ConvertTo-Json -Depth 16))
$stream=[IO.File]::Open($runsetPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
Write-Output 'PREPARED JSON_SCHEMA_CALLER_TRANSACTION_PRIVATE_RUNSET'
