[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$QualificationDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

$apiAstErrors = $null
$apiAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$apiAstErrors)
if ($apiAstErrors.Count) { throw 'JSON_UNINSTALL_CONFIRMATION_HELPER_PARSE' }
$importNodes = @($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if ($importNodes.Count -ne 1) { throw 'JSON_UNINSTALL_CONFIRMATION_HELPER_DISCOVERY' }
. ([scriptblock]::Create($importNodes[0].Extent.Text))
foreach ($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @('Assert-ReleasePin','Assert-ReleasePrivatePath')) { . $block }

$output = Assert-ReleasePrivatePath $OutputDirectory
$qualification = Assert-ReleasePrivatePath $QualificationDirectory
if (Test-Path -LiteralPath $output) { throw 'JSON_UNINSTALL_CONFIRMATION_OUTPUT_EXISTS' }
$outputParent = Split-Path -Parent $output
if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) { throw 'JSON_UNINSTALL_CONFIRMATION_OUTPUT_PARENT_REQUIRED' }
[void][IO.Directory]::CreateDirectory($output)
$baseOutput = Join-Path $output 'base'
$basePreparer = Join-Path $PSScriptRoot 'Prepare-JsonSchemaAppLockRunset.ps1'
& $basePreparer -QualificationDirectory $qualification -OutputDirectory $baseOutput | Out-Null

$baseRunsetPath = Join-Path $baseOutput 'runset.json'
$baseRunset = Get-Content -LiteralPath $baseRunsetPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($baseRunset.schema_version -cne 'json-schema-applock-probe/v1' -or
    $baseRunset.target.platform -cne 'windows' -or $baseRunset.target.version -cne '2025' -or
    $baseRunset.target.patch -cne 'CU8' -or $baseRunset.target.compatibility_level -ne 170 -or
    $baseRunset.target.test_purpose -cne 'Functional' -or
    $baseRunset.baseline.modules.Count -ne 2 -or
    $baseRunset.baseline.modules[0] -cne 'toolbelt.core.result-table' -or
    $baseRunset.baseline.modules[1] -cne 'toolbelt.json.core' -or
    $baseRunset.schema_deploy.module -cne 'toolbelt.json.schema' -or
    $baseRunset.schema_uninstall.module -cne 'toolbelt.json.schema' -or
    ($baseRunset.scope.lock_resources -join '|') -cne 'toolbelt.deploy.json.shared-core|toolbelt.deploy.toolbelt.json.schema' -or
    $baseRunset.scope.expected_error -ne 55637 -or $baseRunset.scope.expected_state -ne 1) {
    throw 'JSON_UNINSTALL_CONFIRMATION_BASE_RUNSET_INVALID'
}
$schemaUninstallText=[IO.File]::ReadAllText([string]$baseRunset.schema_uninstall.path,[Text.Encoding]::UTF8)
if($schemaUninstallText -notmatch 'toolbelt\.deploy\.json\.shared-core' -or
   $schemaUninstallText -notmatch 'toolbelt\.deploy\.toolbelt\.json\.schema' -or
   $schemaUninstallText -notmatch 'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar\.' -or
   $schemaUninstallText -notmatch 'JSON Schema lifecycle: Modul-AppLock nicht verfügbar\.'){
    throw 'JSON_UNINSTALL_CONFIRMATION_SCHEMA_LOCK_SOURCE_DRIFT'
}

function Replace-Exact([string]$Text,[string]$Old,[string]$New,[string]$Code){
    if([regex]::Matches($Text,[regex]::Escape($Old)).Count-ne1){throw $Code}
    return $Text.Replace($Old,$New)
}
function Write-ExactUtf8([string]$Path,[string]$Text){
    $normalized=[regex]::Replace($Text,"`r`n|`r|`n","`n")
    $bytes=[Text.UTF8Encoding]::new($false,$true).GetBytes($normalized)
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
}
$baselineText=[IO.File]::ReadAllText([string]$baseRunset.baseline.path,[Text.Encoding]::UTF8)
$baselineText=Replace-Exact $baselineText "@DeploymentMode       nvarchar(16)  = LOWER(N'local')" "@DeploymentMode       nvarchar(16)  = LOWER(N'central')" 'JSON_UNINSTALL_CONFIRMATION_BASELINE_MODE_BINDING'
$baselineText=Replace-Exact $baselineText "DECLARE @Mode nvarchar(max)=N'local'," "DECLARE @Mode nvarchar(max)=N'central'," 'JSON_UNINSTALL_CONFIRMATION_CORE_MODE_BINDING'
$schemaDeployText=[IO.File]::ReadAllText([string]$baseRunset.schema_deploy.path,[Text.Encoding]::UTF8)
$schemaDeployText=Replace-Exact $schemaDeployText "DECLARE @Mode nvarchar(max)=N'local'," "DECLARE @Mode nvarchar(max)=N'central'," 'JSON_UNINSTALL_CONFIRMATION_SCHEMA_MODE_BINDING'
$confirmTemplate=Replace-Exact $schemaUninstallText "DECLARE @Confirmation nvarchar(max)=N'1'" "DECLARE @Confirmation nvarchar(max)=N'{CONFIRMATION}'" 'JSON_UNINSTALL_CONFIRMATION_INPUT_BINDING'
$confirm01=$confirmTemplate.Replace('{CONFIRMATION}','01')
$confirm0=$confirmTemplate.Replace('{CONFIRMATION}','0')
foreach($text in @($baselineText,$schemaDeployText,$schemaUninstallText,$confirm01,$confirm0)){if($text-match'(?m)^:|\$\('){throw 'JSON_UNINSTALL_CONFIRMATION_UNRESOLVED_SQL'}}
$baselinePath=Join-Path $output 'baseline.central.sql'
$schemaDeployPath=Join-Path $output 'schema.central.sql'
$uninstallConfirm1Path=Join-Path $output 'schema-uninstall.confirm-1.sql'
$uninstallConfirm01Path=Join-Path $output 'schema-uninstall.confirm-01.sql'
$uninstallConfirm0Path=Join-Path $output 'schema-uninstall.confirm-0.sql'
Write-ExactUtf8 $baselinePath $baselineText
Write-ExactUtf8 $schemaDeployPath $schemaDeployText
Write-ExactUtf8 $uninstallConfirm1Path $schemaUninstallText
Write-ExactUtf8 $uninstallConfirm01Path $confirm01
Write-ExactUtf8 $uninstallConfirm0Path $confirm0
foreach ($pin in $baseRunset.pins) { Assert-ReleasePin $pin.path $pin.sha256 }
Assert-ReleasePin $baseRunsetPath (Get-FileHash -LiteralPath $baseRunsetPath -Algorithm SHA256).Hash

$pins = [Collections.Generic.List[object]]::new()
$pinPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($pin in $baseRunset.pins) {
    if ($pinPaths.Add([IO.Path]::GetFullPath([string]$pin.path))) { $pins.Add($pin) }
}
foreach ($path in @(
        $baseRunsetPath,
        $PSCommandPath,
        (Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallConfirmationLab.ps1'),
        (Join-Path $PSScriptRoot 'Test-JsonSchemaUninstallConfirmationOffline.ps1'),
        $baselinePath,$schemaDeployPath,$uninstallConfirm1Path,$uninstallConfirm01Path,$uninstallConfirm0Path)) {
    $full = [IO.Path]::GetFullPath($path)
    if ($pinPaths.Add($full)) {
        $pins.Add([ordered]@{path=$full;sha256=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToUpperInvariant()})
    }
}

$cases = @(
    [ordered]@{ordinal=0;confirmation='01';path=$uninstallConfirm01Path;sha256=(Get-FileHash -LiteralPath $uninstallConfirm01Path -Algorithm SHA256).Hash.ToUpperInvariant();expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: ungültige Consumer-Bestätigung.'},
    [ordered]@{ordinal=1;confirmation='0';path=$uninstallConfirm0Path;sha256=(Get-FileHash -LiteralPath $uninstallConfirm0Path -Algorithm SHA256).Hash.ToUpperInvariant();expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'}
)
$runset = [ordered]@{
    schema_version='json-schema-uninstall-confirmation-probe/v1'
    operation='schema-uninstall-confirmation'
    base_runset=[ordered]@{path=$baseRunsetPath;sha256=(Get-FileHash -LiteralPath $baseRunsetPath -Algorithm SHA256).Hash.ToUpperInvariant()}
    target=$baseRunset.target
    lab=$baseRunset.lab
    qualification=$baseRunset.qualification
    artifacts=$baseRunset.artifacts
    baseline=[ordered]@{path=$baselinePath;sha256=(Get-FileHash -LiteralPath $baselinePath -Algorithm SHA256).Hash.ToUpperInvariant();modules=$baseRunset.baseline.modules}
    schema_deploy=[ordered]@{path=$schemaDeployPath;sha256=(Get-FileHash -LiteralPath $schemaDeployPath -Algorithm SHA256).Hash.ToUpperInvariant();module='toolbelt.json.schema'}
    schema_uninstall=[ordered]@{path=$uninstallConfirm1Path;sha256=(Get-FileHash -LiteralPath $uninstallConfirm1Path -Algorithm SHA256).Hash.ToUpperInvariant();module='toolbelt.json.schema'}
    pins=$pins.ToArray()
    scope=[ordered]@{
        deployment_mode='central'
        expected_error=55635
        expected_state=1
        cases=$cases
        positive_control='same pinned Uninstall succeeds with ConfirmNoExternalConsumers=1'
        initial_session_profile=[ordered]@{quoted_identifier='ON';nocount='ON';xact_abort='ON';implicit_transactions='OFF';transaction_count=0;options_unchanged_across_rejection=$true}
    }
}
$runsetPath = Join-Path $output 'runset.json'
$bytes = [Text.UTF8Encoding]::new($false,$true).GetBytes(($runset | ConvertTo-Json -Depth 12))
$stream = [IO.File]::Open($runsetPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $stream.Write($bytes,0,$bytes.Length);$stream.Flush() } finally { $stream.Dispose() }
Write-Output 'PREPARED JSON_SCHEMA_UNINSTALL_CONFIRMATION_PRIVATE_RUNSET'
