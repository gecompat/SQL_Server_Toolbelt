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
if ($apiAstErrors.Count) { throw 'JSON_UNINSTALL_APPLOCK_HELPER_PARSE' }
$importNodes = @($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if ($importNodes.Count -ne 1) { throw 'JSON_UNINSTALL_APPLOCK_HELPER_DISCOVERY' }
. ([scriptblock]::Create($importNodes[0].Extent.Text))
foreach ($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @('Assert-ReleasePin','Assert-ReleasePrivatePath')) { . $block }

$output = Assert-ReleasePrivatePath $OutputDirectory
$qualification = Assert-ReleasePrivatePath $QualificationDirectory
if (Test-Path -LiteralPath $output) { throw 'JSON_UNINSTALL_APPLOCK_OUTPUT_EXISTS' }
$outputParent = Split-Path -Parent $output
if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) { throw 'JSON_UNINSTALL_APPLOCK_OUTPUT_PARENT_REQUIRED' }
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
    throw 'JSON_UNINSTALL_APPLOCK_BASE_RUNSET_INVALID'
}
$schemaUninstallText=[IO.File]::ReadAllText([string]$baseRunset.schema_uninstall.path,[Text.Encoding]::UTF8)
if($schemaUninstallText -notmatch 'toolbelt\.deploy\.json\.shared-core' -or
   $schemaUninstallText -notmatch 'toolbelt\.deploy\.toolbelt\.json\.schema' -or
   $schemaUninstallText -notmatch 'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar\.' -or
   $schemaUninstallText -notmatch 'JSON Schema lifecycle: Modul-AppLock nicht verfügbar\.'){
    throw 'JSON_UNINSTALL_APPLOCK_SCHEMA_LOCK_SOURCE_DRIFT'
}
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
        (Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'),
        (Join-Path $PSScriptRoot 'Test-JsonSchemaUninstallAppLockOffline.ps1'))) {
    $full = [IO.Path]::GetFullPath($path)
    if ($pinPaths.Add($full)) {
        $pins.Add([ordered]@{path=$full;sha256=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToUpperInvariant()})
    }
}

$resources = @('toolbelt.deploy.json.shared-core','toolbelt.deploy.toolbelt.json.schema')
$messages = @(
    'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.',
    'JSON Schema lifecycle: Modul-AppLock nicht verfügbar.'
)
$cases = @(
    [ordered]@{ordinal=0;resource=$resources[0];expected_message=$messages[0]},
    [ordered]@{ordinal=1;resource=$resources[1];expected_message=$messages[1]}
)
$runset = [ordered]@{
    schema_version='json-schema-uninstall-applock-probe/v1'
    operation='schema-uninstall-app-lock'
    base_runset=[ordered]@{path=$baseRunsetPath;sha256=(Get-FileHash -LiteralPath $baseRunsetPath -Algorithm SHA256).Hash.ToUpperInvariant()}
    target=$baseRunset.target
    lab=$baseRunset.lab
    qualification=$baseRunset.qualification
    artifacts=$baseRunset.artifacts
    baseline=$baseRunset.baseline
    schema_deploy=$baseRunset.schema_deploy
    schema_uninstall=$baseRunset.schema_uninstall
    pins=$pins.ToArray()
    scope=[ordered]@{
        deployment_mode='local'
        expected_error=55637
        expected_state=1
        cases=$cases
        positive_control='same schema Uninstall succeeds after holder release'
        reinstallation='same pinned schema Deploy restores the module between cases'
    }
}
$runsetPath = Join-Path $output 'runset.json'
$bytes = [Text.UTF8Encoding]::new($false,$true).GetBytes(($runset | ConvertTo-Json -Depth 12))
$stream = [IO.File]::Open($runsetPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $stream.Write($bytes,0,$bytes.Length);$stream.Flush() } finally { $stream.Dispose() }
Write-Output 'PREPARED JSON_SCHEMA_UNINSTALL_APPLOCK_PRIVATE_RUNSET'
